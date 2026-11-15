import type { Transaction } from 'mssql';
import { execute, query, withTransaction } from '../../db/pool';
import type { AuthUser } from '../../middlewares/auth';
import { isStaff } from '../../middlewares/auth';
import { IVA, ORDEN_ESTADOS } from '../../types';
import type { OrdenEstado } from '../../types';
import { fmtMoney, round2 } from '../../utils/format';
import { badRequest, conflict, notFound } from '../../utils/httpError';
import { notificar } from '../notificaciones/notificaciones.service';

const BASE = `
  SELECT o.id_orden AS id, o.folio, o.estado, ISNULL(o.diagnostico, N'') AS diagnostico,
         o.autorizacion, CAST(o.cotizacion_enviada AS bit) AS cotizacionEnviada,
         o.kilometraje, o.notas_recepcion AS notas,
         CAST(ISNULL(o.total, 0) AS decimal(14,2)) AS total,
         CONVERT(varchar(19), o.fecha_ingreso, 126) AS fechaIngreso, o.id_cita AS citaId,
         u.id_usuario AS clienteId, CONCAT(u.nombre, N' ', u.apellidos) AS cliente, u.telefono,
         CAST(CASE WHEN u.tiene_cuenta = 0 THEN 1 ELSE 0 END AS bit) AS sinCuenta,
         v.id_vehiculo AS vehiculoId, CONCAT(v.marca, N' ', v.modelo, N' ', v.anio) AS vehiculo, v.placas,
         o.id_servicio AS servicioId, s.nombre AS servicio,
         CONCAT(e.nombre, N' ', e.apellidos) AS mecanico
  FROM OrdenesTrabajo o
  JOIN Usuarios u  ON u.id_usuario  = o.id_usuario
  JOIN Vehiculos v ON v.id_vehiculo = o.id_vehiculo
  LEFT JOIN Servicios s ON s.id_servicio  = o.id_servicio
  LEFT JOIN Empleados e ON e.id_empleado  = o.id_empleado`;

interface OrdenRow {
  id: number; folio: string; estado: OrdenEstado; diagnostico: string;
  autorizacion: 'Pendiente' | 'Autorizada' | 'Rechazada'; cotizacionEnviada: boolean;
  kilometraje: number | null; notas: string | null; total: number; fechaIngreso: string; citaId: number | null;
  clienteId: number; cliente: string; telefono: string; sinCuenta: boolean;
  vehiculoId: number; vehiculo: string; placas: string; servicioId: number | null; servicio: string | null;
  mecanico: string | null;
}

interface Concepto { id: number; concepto: string; tipo: string; cantidad: number; precio: number; subtotal: number }

const idx = (e: string) => ORDEN_ESTADOS.indexOf(e as OrdenEstado);

/* ---------- lectura ---------- */

export function listar(user: AuthUser, estado?: string) {
  const where: string[] = [];
  const params: Record<string, unknown> = {};
  if (!isStaff(user)) { where.push('o.id_usuario = @uid'); params.uid = user.id; }
  if (estado) { where.push('o.estado = @estado'); params.estado = estado; }
  return query<OrdenRow>(
    `${BASE} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY o.id_orden DESC`,
    params
  ).then((rows) => rows.map((r) => ({ ...r, mecanico: r.mecanico?.trim() || null })));
}

async function fila(id: number, tx?: Transaction): Promise<OrdenRow> {
  const r = await query<OrdenRow>(`${BASE} WHERE o.id_orden = @id`, { id }, tx);
  if (!r[0]) throw notFound('Orden no encontrada');
  return r[0];
}

function conceptosDe(id: number, tx?: Transaction) {
  return query<Concepto>(
    `SELECT id_detalle AS id, concepto, tipo, CAST(cantidad AS float) AS cantidad,
            CAST(precio_unitario AS float) AS precio, CAST(subtotal AS float) AS subtotal
     FROM Ordenes_Servicios WHERE id_orden = @id ORDER BY id_detalle`,
    { id }, tx
  );
}

/** Orden completa: datos + conceptos + totales (el total ya incluye IVA 16 %). */
export async function obtener(user: AuthUser, id: number) {
  const o = await fila(id);
  if (!isStaff(user) && o.clienteId !== user.id) throw notFound('Orden no encontrada');
  const conceptos = await conceptosDe(id);
  const total = round2(conceptos.reduce((s, c) => s + c.subtotal, 0));
  const subtotal = round2(total / (1 + IVA));
  return {
    ...o,
    mecanico: o.mecanico?.trim() || null,
    conceptos,
    total,
    subtotal,
    iva: round2(total - subtotal),
  };
}

/* ---------- creación ---------- */

export interface NuevaOrden {
  clienteId: number; vehiculoId: number; servicioId: number;
  kilometraje: number; notas?: string; citaId?: number;
}

export async function crear(user: AuthUser, i: NuevaOrden) {
  const id = await withTransaction(async (tx) => {
    const veh = await query<{ descripcion: string }>(
      `SELECT CONCAT(marca, N' ', modelo, N' ', anio) AS descripcion
       FROM Vehiculos WHERE id_vehiculo = @v AND id_usuario = @u`,
      { v: i.vehiculoId, u: i.clienteId }, tx
    );
    if (!veh[0]) throw badRequest('El vehículo no pertenece a ese cliente');

    const svc = await query('SELECT 1 AS x FROM Servicios WHERE id_servicio = @s', { s: i.servicioId }, tx);
    if (!svc[0]) throw badRequest('El servicio no existe');

    if (i.citaId) {
      const c = await query<{ estado: string; id_usuario: number }>(
        'SELECT estado, id_usuario FROM Citas WHERE id_cita = @c', { c: i.citaId }, tx
      );
      if (!c[0]) throw notFound('La cita no existe');
      if (c[0].estado !== 'Confirmada') throw conflict('Solo se puede crear una orden desde una cita confirmada');
      if (c[0].id_usuario !== i.clienteId) throw conflict('La cita pertenece a otro cliente');
      const dup = await query('SELECT 1 AS x FROM OrdenesTrabajo WHERE id_cita = @c', { c: i.citaId }, tx);
      if (dup[0]) throw conflict('Esa cita ya tiene una orden de trabajo');
    }

    const seq = await query<{ n: number }>('SELECT NEXT VALUE FOR dbo.seq_folio_orden AS n', {}, tx);
    const folio = `OT-${seq[0].n}`;

    const ins = await query<{ id: number }>(
      `INSERT INTO OrdenesTrabajo
         (folio, id_cita, id_usuario, id_vehiculo, id_empleado, id_servicio, fecha_ingreso,
          diagnostico, estado, total, kilometraje, notas_recepcion)
       OUTPUT INSERTED.id_orden AS id
       VALUES (@folio, @cita, @u, @v, @emp, @s, SYSDATETIME(), N'', N'Recibida', 0, @km, @notas)`,
      {
        folio, cita: i.citaId ?? null, u: i.clienteId, v: i.vehiculoId, emp: user.id,
        s: i.servicioId, km: i.kilometraje, notas: i.notas ?? null,
      }, tx
    );

    await notificar({
      audiencia: 'cliente', usuarioId: i.clienteId, tipo: 'orden', tono: 'slate',
      titulo: 'Recibimos tu vehículo',
      detalle: `Orden ${folio} · ${veh[0].descripcion}. Te avisaremos cuando haya novedades`,
      refTipo: 'orden', refId: ins[0].id,
    }, tx);
    return ins[0].id;
  });
  return obtener(user, id);
}

/* ---------- diagnóstico y estado ---------- */

export async function guardarDiagnostico(user: AuthUser, id: number, texto: string) {
  const o = await fila(id);
  const nuevoEstado = o.estado === 'Recibida' ? 'En diagnóstico' : o.estado;
  await execute(
    'UPDATE OrdenesTrabajo SET diagnostico = @t, estado = @e WHERE id_orden = @id',
    { id, t: texto, e: nuevoEstado }
  );
  return obtener(user, id);
}

export async function cambiarEstado(user: AuthUser, id: number, nuevo: OrdenEstado) {
  const o = await fila(id);
  if (o.estado === 'Entregada') throw conflict('La orden ya fue entregada y no puede modificarse');
  if (nuevo === o.estado) return obtener(user, id);

  if (idx(nuevo) >= idx('Autorizada') && o.autorizacion !== 'Autorizada') {
    throw conflict(`No se puede pasar a «${nuevo}» sin la autorización del cliente`);
  }
  if (nuevo === 'Cotizada') {
    const c = await conceptosDe(id);
    if (!c.length) throw conflict('Agrega conceptos a la cotización antes de marcarla como cotizada');
  }
  if (nuevo === 'Entregada' && o.estado !== 'Lista') {
    throw conflict('Solo se puede entregar una orden que esté en estado «Lista»');
  }

  await execute('UPDATE OrdenesTrabajo SET estado = @e WHERE id_orden = @id', { id, e: nuevo });
  await notificar({
    audiencia: 'cliente', usuarioId: o.clienteId, tipo: 'orden',
    tono: nuevo === 'Lista' ? 'green' : 'slate',
    titulo: nuevo === 'Lista' ? 'Tu vehículo está listo' : 'Actualización de tu orden',
    detalle: `${o.folio} · ${o.vehiculo}: ahora está «${nuevo}»`,
    refTipo: 'orden', refId: id,
  });
  return obtener(user, id);
}

/* ---------- cotización ---------- */

async function recalcularTotal(id: number, tx: Transaction) {
  await execute(
    `UPDATE OrdenesTrabajo
     SET total = (SELECT ISNULL(SUM(subtotal), 0) FROM Ordenes_Servicios WHERE id_orden = @id)
     WHERE id_orden = @id`,
    { id }, tx
  );
}

export interface NuevoConcepto { concepto: string; tipo: string; cantidad: number; precio: number }

export async function agregarConcepto(user: AuthUser, id: number, c: NuevoConcepto) {
  const o = await fila(id);
  if (o.cotizacionEnviada) throw conflict('La cotización ya fue enviada y no puede modificarse');
  await withTransaction(async (tx) => {
    await execute(
      `INSERT INTO Ordenes_Servicios (id_orden, id_servicio, concepto, tipo, cantidad, precio_unitario)
       VALUES (@id, NULL, @concepto, @tipo, @cantidad, @precio)`,
      { id, ...c }, tx
    );
    await recalcularTotal(id, tx);
  });
  return obtener(user, id);
}

export async function quitarConcepto(user: AuthUser, id: number, conceptoId: number) {
  const o = await fila(id);
  if (o.cotizacionEnviada) throw conflict('La cotización ya fue enviada y no puede modificarse');
  await withTransaction(async (tx) => {
    const n = await execute(
      'DELETE FROM Ordenes_Servicios WHERE id_detalle = @c AND id_orden = @id',
      { c: conceptoId, id }, tx
    );
    if (!n) throw notFound('Concepto no encontrado');
    await recalcularTotal(id, tx);
  });
  return obtener(user, id);
}

/** Clientes con cuenta: la cotización les llega a la app para que la autoricen. */
export async function enviarCotizacion(user: AuthUser, id: number) {
  const o = await fila(id);
  if (o.sinCuenta) {
    throw conflict('Este cliente no tiene cuenta: registra su autorización por teléfono');
  }
  if (o.cotizacionEnviada) throw conflict('La cotización ya fue enviada');
  const conceptos = await conceptosDe(id);
  if (!conceptos.length) throw conflict('La cotización está vacía');
  const total = round2(conceptos.reduce((s, c) => s + c.subtotal, 0));

  await execute(
    `UPDATE OrdenesTrabajo
     SET cotizacion_enviada = 1, autorizacion = N'Pendiente',
         estado = CASE WHEN estado IN (N'Recibida', N'En diagnóstico') THEN N'Cotizada' ELSE estado END
     WHERE id_orden = @id`,
    { id }
  );
  await notificar({
    audiencia: 'cliente', usuarioId: o.clienteId, tipo: 'cotizacion', tono: 'amber',
    titulo: 'Tienes una cotización por autorizar',
    detalle: `${o.folio} · ${o.vehiculo} · Total ${fmtMoney(total)} (IVA incluido)`,
    refTipo: 'orden', refId: id,
  });
  return obtener(user, id);
}

/**
 * Autorizar o rechazar la cotización.
 *  - Cliente con cuenta: lo hace él desde la app (solo si ya se la enviaron).
 *  - Cliente sin cuenta: lo registra el personal tras confirmarlo por teléfono.
 */
export async function decidirAutorizacion(user: AuthUser, id: number, decision: 'Autorizada' | 'Rechazada') {
  const o = await fila(id);
  const esCliente = !isStaff(user);

  if (esCliente) {
    if (o.clienteId !== user.id) throw notFound('Orden no encontrada');
    if (!o.cotizacionEnviada) throw conflict('La cotización todavía no ha sido enviada');
  } else if (!o.sinCuenta) {
    throw conflict('Este cliente tiene cuenta: la autorización la registra él desde la app');
  }
  if (o.autorizacion !== 'Pendiente') throw conflict(`La cotización ya fue ${o.autorizacion.toLowerCase()}`);

  const conceptos = await conceptosDe(id);
  if (!conceptos.length) throw conflict('La cotización está vacía');
  const total = round2(conceptos.reduce((s, c) => s + c.subtotal, 0));

  const n = await execute(
    `UPDATE OrdenesTrabajo
     SET autorizacion = @d, cotizacion_enviada = 1,
         estado = CASE WHEN @d = N'Autorizada' AND estado IN (N'Recibida', N'En diagnóstico', N'Cotizada')
                       THEN N'Autorizada' ELSE estado END
     WHERE id_orden = @id AND autorizacion = N'Pendiente'`,
    { id, d: decision }
  );
  if (!n) throw conflict('La cotización ya fue respondida');

  if (esCliente) {
    const ok = decision === 'Autorizada';
    await notificar({
      audiencia: 'personal', tipo: 'cotizacion', tono: ok ? 'green' : 'red',
      titulo: ok ? 'Cotización autorizada' : 'Cotización rechazada',
      detalle: `${o.cliente} ${ok ? 'autorizó' : 'rechazó'} la cotización de ${o.folio}${ok ? ' · ' + fmtMoney(total) : ''}`,
      refTipo: 'orden', refId: id,
    });
  }
  return obtener(user, id);
}
