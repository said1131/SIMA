import type { Transaction } from 'mssql';
import { execute, query, withTransaction } from '../../db/pool';
import type { AuthUser } from '../../middlewares/auth';
import { isStaff } from '../../middlewares/auth';
import { badRequest, conflict, notFound } from '../../utils/httpError';
import { fmtFecha, hoyISO, sqlDate } from '../../utils/format';
import { notificar } from '../notificaciones/notificaciones.service';

const BASE = `
  SELECT c.id_cita AS id, c.id_usuario AS clienteId,
         CONCAT(u.nombre, N' ', u.apellidos) AS cliente, u.telefono,
         CAST(CASE WHEN u.tiene_cuenta = 0 THEN 1 ELSE 0 END AS bit) AS sinCuenta,
         c.id_vehiculo AS vehiculoId, CONCAT(v.marca, N' ', v.modelo, N' ', v.anio) AS vehiculo, v.placas,
         c.id_servicio AS servicioId, s.nombre AS servicio,
         CONVERT(varchar(10), c.fecha, 23) AS fecha, CONVERT(varchar(5), c.hora, 108) AS hora,
         c.estado, CAST(c.es_expres AS bit) AS expres, c.motivo_rechazo AS motivoRechazo
  FROM Citas c
  JOIN Usuarios u  ON u.id_usuario  = c.id_usuario
  JOIN Vehiculos v ON v.id_vehiculo = c.id_vehiculo
  LEFT JOIN Servicios s ON s.id_servicio = c.id_servicio`;

export interface CitaRow {
  id: number; clienteId: number; cliente: string; telefono: string; sinCuenta: boolean;
  vehiculoId: number; vehiculo: string; placas: string; servicioId: number | null; servicio: string | null;
  fecha: string; hora: string; estado: string; expres: boolean; motivoRechazo: string | null;
}

export async function horariosOcupados(fecha: string): Promise<string[]> {
  const rows = await query<{ hora: string }>(
    `SELECT CONVERT(varchar(5), hora, 108) AS hora
     FROM Citas
     WHERE fecha = @fecha AND estado IN (N'Solicitada', N'Confirmada')`,
    { fecha: sqlDate(fecha) }
  );
  return rows.map((r) => r.hora);
}

export async function diasLlenosMes(anio: number, mes: number): Promise<string[]> {
  const rows = await query<{ fecha: string }>(
    `SELECT CONVERT(varchar(10), fecha, 23) AS fecha
     FROM Citas
     WHERE YEAR(fecha) = @anio
       AND MONTH(fecha) = @mes
       AND estado IN (N'Solicitada', N'Confirmada')
     GROUP BY fecha
     HAVING COUNT(DISTINCT CONVERT(varchar(5), hora, 108)) >= 5`,
    { anio, mes }
  );
  return rows.map((r) => r.fecha);
}

async function verificarHorarioDisponible(fecha: string, hora: string, tx?: Transaction): Promise<void> {
  const rows = await query<{ total: number }>(
    `SELECT COUNT(*) AS total
     FROM Citas
     WHERE fecha = @fecha
       AND CONVERT(varchar(5), hora, 108) = @hora
       AND estado IN (N'Solicitada', N'Confirmada')`,
    { fecha: sqlDate(fecha), hora },
    tx
  );
  if ((rows[0]?.total ?? 0) > 0) {
    throw conflict(`El horario ${hora} del ${fmtFecha(fecha)} ya está ocupado. Elige otro horario o fecha.`);
  }
}

export function listar(user: AuthUser, estado?: string): Promise<CitaRow[]> {
  const where: string[] = [];
  const params: Record<string, unknown> = {};
  if (!isStaff(user)) { where.push('c.id_usuario = @uid'); params.uid = user.id; }
  if (estado) { where.push('c.estado = @estado'); params.estado = estado; }
  return query<CitaRow>(
    `${BASE} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY c.fecha, c.hora, c.id_cita`,
    params
  );
}

export async function obtener(id: number, user?: AuthUser, tx?: Transaction): Promise<CitaRow> {
  const r = await query<CitaRow>(`${BASE} WHERE c.id_cita = @id`, { id }, tx);
  const c = r[0];
  if (!c || (user && !isStaff(user) && c.clienteId !== user.id)) throw notFound('Cita no encontrada');
  return c;
}

function validarFechaHora(fecha: string) {
  if (fecha < hoyISO()) throw badRequest('La fecha de la cita no puede ser anterior a hoy');
}

async function servicioActivo(id: number, tx?: Transaction): Promise<string> {
  const r = await query<{ nombre: string }>(
    'SELECT nombre FROM Servicios WHERE id_servicio = @id AND activo <> 0', { id }, tx
  );
  if (!r[0]) throw badRequest('El servicio no existe o no está disponible');
  return r[0].nombre;
}

export interface NuevaCita { vehiculoId: number; servicioId: number; fecha: string; hora: string }

/** Cita normal: la crea un cliente con cuenta desde la app. */
export async function crear(user: AuthUser, i: NuevaCita): Promise<CitaRow> {
  validarFechaHora(i.fecha);
  await verificarHorarioDisponible(i.fecha, i.hora);
  const veh = await query('SELECT 1 AS x FROM Vehiculos WHERE id_vehiculo=@v AND id_usuario=@u', { v: i.vehiculoId, u: user.id });
  if (!veh[0]) throw badRequest('El vehículo no pertenece a tu cuenta');
  const servicio = await servicioActivo(i.servicioId);

  const r = await query<{ id: number }>(
    `INSERT INTO Citas (id_usuario, id_vehiculo, id_servicio, fecha, hora, estado, es_expres)
     OUTPUT INSERTED.id_cita AS id
     VALUES (@u, @v, @s, @fecha, @hora, N'Solicitada', 0)`,
    { u: user.id, v: i.vehiculoId, s: i.servicioId, fecha: sqlDate(i.fecha), hora: i.hora + ':00' }
  );
  await notificar({
    audiencia: 'personal', tipo: 'cita', tono: 'amber', titulo: 'Nueva cita solicitada',
    detalle: `${user.name} pidió cita para ${servicio} · ${fmtFecha(i.fecha)}, ${i.hora}`,
    refTipo: 'cita', refId: r[0].id,
  });
  return obtener(r[0].id);
}

export interface NuevaCitaExpres {
  nombre: string; apellidos?: string; telefono: string;
  marca: string; modelo: string; anio: number; placas: string;
  servicioId: number; fecha: string; hora: string;
}

/** Cita exprés: persona SIN cuenta. Se crea un Usuario con tiene_cuenta = 0 y su vehículo. */
export async function crearExpres(i: NuevaCitaExpres): Promise<CitaRow> {
  validarFechaHora(i.fecha);
  const id = await withTransaction(async (tx) => {
    await verificarHorarioDisponible(i.fecha, i.hora, tx);
    const servicio = await servicioActivo(i.servicioId, tx);

    const u = await query<{ id: number }>(
      'SELECT TOP 1 id_usuario AS id FROM Usuarios WHERE telefono = @t AND tiene_cuenta = 0',
      { t: i.telefono }, tx
    );
    const usuarioId = u[0]
      ? u[0].id
      : (await query<{ id: number }>(
          `INSERT INTO Usuarios (nombre, apellidos, telefono, correo, contrasena, tiene_cuenta)
           OUTPUT INSERTED.id_usuario AS id VALUES (@n, @a, @t, NULL, NULL, 0)`,
          { n: i.nombre, a: i.apellidos ?? '', t: i.telefono }, tx
        ))[0].id;

    const placas = i.placas.toUpperCase();
    const v = await query<{ id: number }>(
      'SELECT TOP 1 id_vehiculo AS id FROM Vehiculos WHERE id_usuario = @u AND placas = @p',
      { u: usuarioId, p: placas }, tx
    );
    const vehiculoId = v[0]
      ? v[0].id
      : (await query<{ id: number }>(
          `INSERT INTO Vehiculos (id_usuario, marca, modelo, anio, placas)
           OUTPUT INSERTED.id_vehiculo AS id VALUES (@u, @m, @mo, @an, @p)`,
          { u: usuarioId, m: i.marca, mo: i.modelo, an: i.anio, p: placas }, tx
        ))[0].id;

    const c = await query<{ id: number }>(
      `INSERT INTO Citas (id_usuario, id_vehiculo, id_servicio, fecha, hora, estado, es_expres)
       OUTPUT INSERTED.id_cita AS id
       VALUES (@u, @v, @s, @fecha, @hora, N'Solicitada', 1)`,
      { u: usuarioId, v: vehiculoId, s: i.servicioId, fecha: sqlDate(i.fecha), hora: i.hora + ':00' }, tx
    );

    const nombre = `${i.nombre} ${i.apellidos ?? ''}`.trim();
    await notificar({
      audiencia: 'personal', tipo: 'cita', tono: 'amber', titulo: 'Nueva cita exprés',
      detalle: `${nombre} (sin cuenta) · ${i.telefono} · ${servicio} · ${fmtFecha(i.fecha)}, ${i.hora}`,
      refTipo: 'cita', refId: c[0].id,
    }, tx);
    return c[0].id;
  });
  return obtener(id);
}

export async function confirmar(id: number): Promise<CitaRow> {
  const c = await obtener(id);
  const n = await execute(`UPDATE Citas SET estado = N'Confirmada' WHERE id_cita = @id AND estado = N'Solicitada'`, { id });
  if (!n) throw conflict(`La cita ya está ${c.estado.toLowerCase()}`);
  await notificar({
    audiencia: 'cliente', usuarioId: c.clienteId, tipo: 'cita', tono: 'green', titulo: 'Cita confirmada',
    detalle: `Tu cita de ${c.servicio} del ${fmtFecha(c.fecha)} a las ${c.hora} fue confirmada`,
    refTipo: 'cita', refId: id,
  });
  return obtener(id);
}

export async function rechazar(id: number, motivo: string): Promise<CitaRow> {
  const c = await obtener(id);
  const n = await execute(
    `UPDATE Citas SET estado = N'Rechazada', motivo_rechazo = @motivo WHERE id_cita = @id AND estado = N'Solicitada'`,
    { id, motivo }
  );
  if (!n) throw conflict(`La cita ya está ${c.estado.toLowerCase()}`);
  await notificar({
    audiencia: 'cliente', usuarioId: c.clienteId, tipo: 'cita', tono: 'red', titulo: 'Cita rechazada',
    detalle: `Tu cita de ${c.servicio} del ${fmtFecha(c.fecha)} no pudo agendarse: ${motivo}`,
    refTipo: 'cita', refId: id,
  });
  return obtener(id);
}

export async function cancelar(user: AuthUser, id: number): Promise<CitaRow> {
  const c = await obtener(id, user);
  const n = await execute(
    `UPDATE Citas SET estado = N'Cancelada'
     WHERE id_cita = @id AND id_usuario = @u AND estado IN (N'Solicitada', N'Confirmada')`,
    { id, u: user.id }
  );
  if (!n) throw conflict(`No se puede cancelar una cita ${c.estado.toLowerCase()}`);
  await notificar({
    audiencia: 'personal', tipo: 'cita', tono: 'slate', titulo: 'Cita cancelada por el cliente',
    detalle: `${c.cliente} canceló su cita del ${fmtFecha(c.fecha)}, ${c.hora}`,
    refTipo: 'cita', refId: id,
  });
  return obtener(id);
}