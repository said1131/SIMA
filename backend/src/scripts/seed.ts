/**
 * Datos iniciales: npm run seed  (en Docker se ejecuta solo al arrancar la API)
 *  1. Crea (o actualiza la contraseña de) el administrador del taller.
 *  2. Si el catálogo de servicios está vacío, lo llena con servicios de ejemplo.
 *  3. Si SEED_DEMO=true y NO hay clientes todavía, carga clientes, citas, órdenes y
 *     notificaciones de ejemplo para que web y app tengan algo que mostrar.
 * Se puede ejecutar muchas veces sin duplicar nada.
 */
import bcrypt from 'bcryptjs';
import { env } from '../config/env';
import { execute, getPool, query } from '../db/pool';
import { sqlDate } from '../utils/format';

const DEMO_PASSWORD = 'sima1234';

const SERVICIOS = [
  { nombre: 'Cambios de aceite de motor', categoria: 'Preventivo', descripcion: 'Cambio de aceite multigrado o sintético, filtro de aceite y revisión de niveles.', precio: 950, duracion: 1, garantia: 3 },
  { nombre: 'Lubricación', categoria: 'Preventivo', descripcion: 'Engrasado general de chasis, rótulas, terminales y puntos de articulación.', precio: 650, duracion: 1, garantia: 3 },
  { nombre: 'Servicio al sistema de enfriamiento', categoria: 'Preventivo', descripcion: 'Limpieza de radiador, revisión de mangueras, termostato y cambio de anticongelante.', precio: 1100, duracion: 2, garantia: 6 },
  { nombre: 'Alineación y balanceo', categoria: 'Preventivo', descripcion: 'Ajuste de ángulos de dirección y balanceo computarizado de las 4 ruedas.', precio: 850, duracion: 1, garantia: 3 },
  { nombre: 'Frenos', categoria: 'Correctivo', descripcion: 'Revisión y reemplazo de balatas, rectificado de discos/tambores y purga de líquido.', precio: 1450, duracion: 2, garantia: 6 },
  { nombre: 'Suspensiones', categoria: 'Correctivo', descripcion: 'Diagnóstico y cambio de amortiguadores, horquillas, bujes y bases.', precio: 1800, duracion: 3, garantia: 6 },
  { nombre: 'Reparaciones de motor (medios ajustes y ajustes completos)', categoria: 'Correctivo', descripcion: 'Servicio estrella: rectificación, cambio de anillos, metales, empaques y ajuste completo.', precio: 8500, duracion: 24, garantia: 12 },
  { nombre: 'Fallas electrónicas', categoria: 'Correctivo', descripcion: 'Diagnóstico con escáner automotriz, sensores, cableado y módulos electrónicos.', precio: 900, duracion: 2, garantia: 3 },
  { nombre: 'Sistemas ABS', categoria: 'Correctivo', descripcion: 'Diagnóstico y reparación de sensores de rueda, módulo hidráulico y testigos ABS.', precio: 1600, duracion: 3, garantia: 6 },
  { nombre: 'Transmisiones automáticas', categoria: 'Correctivo', descripcion: 'Diagnóstico, cambio de aceite ATF, filtro, solenoides y reparación de caja automática.', precio: 3200, duracion: 8, garantia: 6 },
  { nombre: 'Transmisiones estándar', categoria: 'Correctivo', descripcion: 'Ajuste y reparación de caja manual, clutch, collarín y sincronizadores.', precio: 2800, duracion: 6, garantia: 6 },
  { nombre: 'Hojalatería y pintura', categoria: 'Correctivo', descripcion: 'Enderezado de carrocería, igualación de color y acabado automotriz en cabina.', precio: 3500, duracion: 16, garantia: 12 },
  { nombre: 'Sistema de dirección hidráulica, electroasistida y electrónica', categoria: 'Correctivo', descripcion: 'Reparación de cremallera, bomba hidráulica, columna electroasistida y sensores.', precio: 2200, duracion: 4, garantia: 6 },
  { nombre: 'Elevadores, accesorios, puertas eléctricas y tableros', categoria: 'Correctivo', descripcion: 'Reparación de elevadores de cristales, seguros eléctricos, controles y tablero.', precio: 1100, duracion: 2, garantia: 3 },
];

const addDays = (n: number): string => {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d.toLocaleDateString('sv-SE');
};

async function insertId(text: string, params: Record<string, unknown>): Promise<number> {
  const r = await query<{ id: number }>(text, params);
  return r[0].id;
}

/* ------------------------------------------------------------------ */

async function seedAdmin(): Promise<number> {
  const correo = env.SEED_ADMIN_EMAIL.toLowerCase();
  const hash = await bcrypt.hash(env.SEED_ADMIN_PASSWORD, 10);

  const ya = await query<{ id: number }>('SELECT id_empleado AS id FROM Empleados WHERE correo = @correo', { correo });
  if (ya.length) {
    await execute(`UPDATE Empleados SET password_hash = @hash, rol = N'admin' WHERE correo = @correo`, { hash, correo });
    console.log(`✔ Administrador actualizado: ${correo}`);
    return ya[0].id;
  }
  const id = await insertId(
    `INSERT INTO Empleados (nombre, apellidos, puesto, correo, password_hash, rol)
     OUTPUT INSERTED.id_empleado AS id
     VALUES (N'Carlos', N'Méndez', N'Encargado del taller', @correo, @hash, N'admin')`,
    { correo, hash }
  );
  console.log(`✔ Administrador creado: ${correo}`);
  return id;
}

async function seedCatalogo(): Promise<void> {
  const [{ n }] = await query<{ n: number }>('SELECT COUNT(*) AS n FROM Servicios');
  if (n > 0) {
    console.log(`• El catálogo ya tiene ${n} servicios, no se modificó`);
    return;
  }
  for (const s of SERVICIOS) {
    await execute(
      `INSERT INTO Servicios (nombre, descripcion, categoria, precio_estimado, duracion_horas, garantia_meses, activo)
       VALUES (@nombre, @descripcion, @categoria, @precio, @duracion, @garantia, 1)`,
      s
    );
  }
  console.log(`✔ Catálogo de ejemplo creado (${SERVICIOS.length} servicios)`);
}

/* ------------------------------------------------------------------ */

interface Cli { u: number; veh: number; nombre: string }
interface Vehiculo { marca: string; modelo: string; anio: number; placas: string }
type ConceptoDemo = [concepto: string, tipo: string, cantidad: number, precio: number];

async function seedDemo(adminId: number): Promise<void> {
  const [{ n }] = await query<{ n: number }>('SELECT COUNT(*) AS n FROM Usuarios');
  if (n > 0) {
    console.log('• Ya hay clientes: no se cargan datos de demostración');
    return;
  }

  const hash = await bcrypt.hash(DEMO_PASSWORD, 10);
  const servicios = await query<{ id: number; nombre: string }>('SELECT id_servicio AS id, nombre FROM Servicios');
  const sid = (nombre: string) => (servicios.find((s) => s.nombre === nombre) ?? servicios[0]).id;

  const cliente = async (
    nombre: string, apellidos: string, telefono: string, correo: string | null, v: Vehiculo
  ): Promise<Cli> => {
    const u = await insertId(
      `INSERT INTO Usuarios (nombre, apellidos, telefono, correo, contrasena, tiene_cuenta)
       OUTPUT INSERTED.id_usuario AS id
       VALUES (@nombre, @apellidos, @telefono, @correo, @pass, @tiene)`,
      { nombre, apellidos, telefono, correo, pass: correo ? hash : null, tiene: correo ? 1 : 0 }
    );
    const veh = await insertId(
      `INSERT INTO Vehiculos (id_usuario, marca, modelo, anio, placas)
       OUTPUT INSERTED.id_vehiculo AS id VALUES (@u, @marca, @modelo, @anio, @placas)`,
      { u, ...v }
    );
    return { u, veh, nombre: `${nombre} ${apellidos}` };
  };

  const cita = (c: Cli, servicio: string, dias: number, hora: string, estado: string, expres = false) =>
    insertId(
      `INSERT INTO Citas (id_usuario, id_vehiculo, id_servicio, fecha, hora, estado, es_expres)
       OUTPUT INSERTED.id_cita AS id VALUES (@u, @v, @s, @fecha, @hora, @estado, @expres)`,
      { u: c.u, v: c.veh, s: sid(servicio), fecha: sqlDate(addDays(dias)), hora: hora + ':00', estado, expres: expres ? 1 : 0 }
    );

  const orden = async (o: {
    c: Cli; servicio: string; citaId?: number; estado: string; diagnostico?: string;
    autorizacion?: string; enviada?: boolean; km: number; notas?: string; conceptos?: ConceptoDemo[];
  }) => {
    const [{ n: num }] = await query<{ n: number }>('SELECT NEXT VALUE FOR dbo.seq_folio_orden AS n');
    const id = await insertId(
      `INSERT INTO OrdenesTrabajo
         (folio, id_cita, id_usuario, id_vehiculo, id_empleado, id_servicio, fecha_ingreso, diagnostico,
          estado, total, kilometraje, notas_recepcion, autorizacion, cotizacion_enviada)
       OUTPUT INSERTED.id_orden AS id
       VALUES (@folio, @cita, @u, @v, @emp, @s, SYSDATETIME(), @diag, @estado, 0, @km, @notas, @aut, @env)`,
      {
        folio: `OT-${num}`, cita: o.citaId ?? null, u: o.c.u, v: o.c.veh, emp: adminId, s: sid(o.servicio),
        diag: o.diagnostico ?? '', estado: o.estado, km: o.km, notas: o.notas ?? null,
        aut: o.autorizacion ?? 'Pendiente', env: o.enviada ? 1 : 0,
      }
    );
    for (const [concepto, tipo, cantidad, precio] of o.conceptos ?? []) {
      await execute(
        `INSERT INTO Ordenes_Servicios (id_orden, id_servicio, concepto, tipo, cantidad, precio_unitario)
         VALUES (@id, NULL, @concepto, @tipo, @cantidad, @precio)`,
        { id, concepto, tipo, cantidad, precio }
      );
    }
    await execute(
      `UPDATE OrdenesTrabajo
       SET total = (SELECT ISNULL(SUM(subtotal), 0) FROM Ordenes_Servicios WHERE id_orden = @id)
       WHERE id_orden = @id`,
      { id }
    );
    return { id, folio: `OT-${num}` };
  };

  const notif = (
    audiencia: 'personal' | 'cliente', usuarioId: number | null, tipo: string, tono: string,
    titulo: string, detalle: string, refTipo: string, refId: number, leida: boolean
  ) =>
    execute(
      `INSERT INTO Notificaciones (audiencia, id_usuario, tipo, tono, titulo, detalle, ref_tipo, ref_id, leida)
       VALUES (@audiencia, @usuarioId, @tipo, @tono, @titulo, @detalle, @refTipo, @refId, @leida)`,
      { audiencia, usuarioId, tipo, tono, titulo, detalle, refTipo, refId, leida: leida ? 1 : 0 }
    );

  // ---- Clientes con cuenta (todos usan la contraseña DEMO_PASSWORD) ----
  const carlos = await cliente('Carlos', 'Mendoza', '998 100 0001', 'cliente@sima.mx', { marca: 'Toyota', modelo: 'Hilux', anio: 2021, placas: 'ABC-892' });
  const andrea = await cliente('Andrea', 'Morales', '998 100 0002', 'andrea@demo.sima.mx', { marca: 'Mazda', modelo: '3', anio: 2022, placas: 'KTR-415' });
  const roberto = await cliente('Roberto', 'Vega', '998 100 0003', 'roberto@demo.sima.mx', { marca: 'Ford', modelo: 'Ranger', anio: 2019, placas: 'PZX-330' });
  const mariana = await cliente('Mariana', 'Silva', '998 100 0004', 'mariana@demo.sima.mx', { marca: 'Honda', modelo: 'CR-V', anio: 2020, placas: 'JKL-901' });
  const luis = await cliente('Luis', 'Pérez', '998 100 0005', 'luis@demo.sima.mx', { marca: 'Nissan', modelo: 'Versa', anio: 2018, placas: 'NMR-208' });
  const ana = await cliente('Ana', 'Ruiz', '998 100 0006', 'ana@demo.sima.mx', { marca: 'Volkswagen', modelo: 'Jetta', anio: 2017, placas: 'HTR-554' });
  // ---- Cliente SIN cuenta (cita exprés) ----
  const oswaldo = await cliente('Oswaldo', 'Cruz', '998 555 0142', null, { marca: 'Toyota', modelo: 'Hilux', anio: 2021, placas: 'ABC-892' });

  // ---- Citas ----
  const citaCarlos = await cita(carlos, 'Frenos delanteros', 0, '09:30', 'Confirmada');
  const citaAndrea = await cita(andrea, 'Cambio de aceite y filtro', 0, '11:00', 'Solicitada');
  const citaRoberto = await cita(roberto, 'Diagnóstico con escáner', 0, '14:15', 'Solicitada');
  await cita(mariana, 'Afinación mayor', 0, '16:00', 'Confirmada');
  const citaLuis = await cita(luis, 'Alineación y balanceo', 1, '10:00', 'Cancelada');
  const citaOswaldo = await cita(oswaldo, 'Frenos delanteros', 2, '10:00', 'Solicitada', true);

  // ---- Órdenes de trabajo ----
  const frenos: ConceptoDemo[] = [
    ['Pastillas cerámicas delanteras', 'Refacción', 1, 1450],
    ['Rectificado de discos', 'Tornería', 2, 300],
    ['Mano de obra especializada', 'Labor', 3.5, 300],
  ];
  const diagFrenos = 'Pastillas delanteras con desgaste severo. Discos requieren rectificado para evitar daño mayor.';

  const otAna = await orden({
    c: ana, servicio: 'Afinación mayor', estado: 'En reparación', autorizacion: 'Autorizada', enviada: true, km: 98000,
    diagnostico: 'Embrague patina en segunda y tercera.',
    conceptos: [['Kit de embrague', 'Refacción', 1, 4200], ['Mano de obra', 'Labor', 5, 300]],
  });
  await orden({
    c: luis, servicio: 'Alineación y balanceo', estado: 'Lista', autorizacion: 'Autorizada', enviada: true, km: 61200,
    diagnostico: 'Desalineación leve en eje delantero.', conceptos: [['Alineación y balanceo', 'Labor', 1, 780]],
  });
  await orden({
    c: mariana, servicio: 'Afinación mayor', estado: 'En reparación', autorizacion: 'Autorizada', enviada: true, km: 54300,
    diagnostico: 'Bujías y filtros al límite de su vida útil.', conceptos: [['Afinación mayor', 'Labor', 1, 2850]],
  });
  await orden({ c: roberto, servicio: 'Diagnóstico con escáner', estado: 'Recibida', km: 77500, notas: 'Se enciende la luz del motor.' });
  await orden({ c: andrea, servicio: 'Cambio de aceite y filtro', estado: 'En diagnóstico', km: 22100 });
  const otCarlos = await orden({
    c: carlos, servicio: 'Frenos delanteros', citaId: citaCarlos, estado: 'Cotizada', enviada: true, km: 45210,
    notas: 'El cliente reporta ruido metálico al frenar y vibración en el volante.', diagnostico: diagFrenos, conceptos: frenos,
  });
  await orden({
    c: oswaldo, servicio: 'Frenos delanteros', estado: 'Cotizada', km: 45210, diagnostico: diagFrenos, conceptos: frenos,
  });

  // ---- Notificaciones ----
  await notif('personal', null, 'cita', 'amber', 'Nueva cita exprés',
    'Oswaldo Cruz (sin cuenta) · 998 555 0142 · Frenos delanteros', 'cita', citaOswaldo, false);
  await notif('personal', null, 'cita', 'amber', 'Nueva cita solicitada',
    'Andrea Morales pidió cita para Cambio de aceite y filtro', 'cita', citaAndrea, false);
  await notif('personal', null, 'cita', 'amber', 'Nueva cita solicitada',
    'Roberto Vega pidió cita para Diagnóstico con escáner', 'cita', citaRoberto, false);
  await notif('personal', null, 'cotizacion', 'green', 'Cotización autorizada',
    `Ana Ruiz autorizó la cotización de ${otAna.folio} · $5,700.00`, 'orden', otAna.id, true);
  await notif('personal', null, 'cita', 'slate', 'Cita cancelada por el cliente',
    'Luis Pérez canceló su cita de mañana, 10:00', 'cita', citaLuis, true);
  await notif('cliente', carlos.u, 'cotizacion', 'amber', 'Tienes una cotización por autorizar',
    `${otCarlos.folio} · Toyota Hilux 2021 · Total $3,100.00 (IVA incluido)`, 'orden', otCarlos.id, false);

  console.log('✔ Datos de demostración cargados (7 clientes, 6 citas, 7 órdenes)');
  console.log(`  Login de cliente (app): cliente@sima.mx / ${DEMO_PASSWORD}`);
}

/* ------------------------------------------------------------------ */

async function main() {
  const adminId = await seedAdmin();
  await seedCatalogo();
  if (env.SEED_DEMO) await seedDemo(adminId);
  await (await getPool()).close();
}

main().catch((e) => {
  console.error('✖ Error en el seed:', e);
  process.exit(1);
});
