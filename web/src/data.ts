import type { Cita, Cliente, Notificacion, Orden, OrdenEstado, Servicio } from './types';

export const HOY = '2026-10-24';
export const ORDEN_ESTADOS: OrdenEstado[] = [
  'Recibida',
  'En diagnóstico',
  'Cotizada',
  'Autorizada',
  'En reparación',
  'Lista',
  'Entregada',
];

const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

export function fmtFecha(iso: string): string {
  const [, m, d] = iso.split('-');
  return `${Number(d)} ${MESES[Number(m) - 1]}`;
}

export function diasDesdeHoy(iso: string): number {
  const a = Date.parse(iso + 'T00:00:00Z');
  const b = Date.parse(HOY + 'T00:00:00Z');
  return Math.round((a - b) / 86_400_000);
}

export function fmtMoney(n: number): string {
  return (
    '$' + n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  );
}

export const AVANCE: Record<OrdenEstado, number> = {
  Recibida: 10,
  'En diagnóstico': 25,
  Cotizada: 40,
  Autorizada: 55,
  'En reparación': 70,
  Lista: 90,
  Entregada: 100,
};

export const CLIENTES: Cliente[] = [
  { id: 'c1', nombre: 'Carlos Mendoza', vehiculos: [{ descripcion: 'Toyota Hilux 2021', placas: 'ABC-892' }] },
  { id: 'c2', nombre: 'Andrea Morales', vehiculos: [{ descripcion: 'Mazda 3 2022', placas: 'KTR-415' }] },
  { id: 'c3', nombre: 'Roberto Vega', vehiculos: [{ descripcion: 'Ford Ranger 2019', placas: 'PZX-330' }] },
  { id: 'c4', nombre: 'Mariana Silva', vehiculos: [{ descripcion: 'Honda CR-V 2020', placas: 'JKL-901' }] },
  { id: 'c5', nombre: 'Luis Pérez', vehiculos: [{ descripcion: 'Nissan Versa 2018', placas: 'NMR-208' }] },
  { id: 'c6', nombre: 'Ana Ruiz', vehiculos: [{ descripcion: 'VW Jetta 2017', placas: 'HTR-554' }] },
  { id: 'c7', nombre: 'Sofía Herrera', vehiculos: [{ descripcion: 'Chevrolet Aveo 2019', placas: 'SFH-117' }] },
  {
    id: 'c8',
    nombre: 'Oswaldo Cruz',
    sinCuenta: true,
    telefono: '998 555 0142',
    vehiculos: [{ descripcion: 'Toyota Hilux 2021', placas: 'ABC-892' }],
  },
];

export const CITAS_INICIALES: Cita[] = [
  { id: 'a1', cliente: 'Oswaldo Cruz', vehiculo: 'Toyota Hilux 2021', placas: 'ABC-892', servicio: 'Frenos', fecha: '2026-10-26', hora: '10:00', estado: 'Solicitada', expres: true, telefono: '998 555 0142' },
  { id: 'a2', cliente: 'Carlos Mendoza', vehiculo: 'Toyota Hilux 2021', placas: 'ABC-892', servicio: 'Frenos', fecha: '2026-10-24', hora: '09:30', estado: 'Confirmada' },
  { id: 'a3', cliente: 'Andrea Morales', vehiculo: 'Mazda 3 2022', placas: 'KTR-415', servicio: 'Cambio de aceite', fecha: '2026-10-24', hora: '11:00', estado: 'Solicitada' },
  { id: 'a4', cliente: 'Roberto Vega', vehiculo: 'Ford Ranger 2019', placas: 'PZX-330', servicio: 'Diagnóstico', fecha: '2026-10-24', hora: '14:15', estado: 'Solicitada' },
  { id: 'a5', cliente: 'Mariana Silva', vehiculo: 'Honda CR-V 2020', placas: 'JKL-901', servicio: 'Afinación', fecha: '2026-10-24', hora: '16:00', estado: 'Confirmada' },
  { id: 'a6', cliente: 'Luis Pérez', vehiculo: 'Nissan Versa 2018', placas: 'NMR-208', servicio: 'Alineación', fecha: '2026-10-25', hora: '10:00', estado: 'Rechazada' },
  { id: 'a7', cliente: 'Ana Ruiz', vehiculo: 'VW Jetta 2017', placas: 'HTR-554', servicio: 'Cambio de embrague', fecha: '2026-10-27', hora: '12:00', estado: 'Confirmada' },
  { id: 'a8', cliente: 'Sofía Herrera', vehiculo: 'Chevrolet Aveo 2019', placas: 'SFH-117', servicio: 'Suspensión', fecha: '2026-10-28', hora: '09:00', estado: 'Confirmada' },
];

const cotizacionFrenos = [
  { id: 'k1', concepto: 'Pastillas cerámicas delanteras', tipo: 'Refacción' as const, cantidad: 1, precio: 1450 },
  { id: 'k2', concepto: 'Rectificado de discos', tipo: 'Tornería' as const, cantidad: 2, precio: 300 },
  { id: 'k3', concepto: 'Mano de obra especializada', tipo: 'Labor' as const, cantidad: 3.5, precio: 300 },
];

const base = { cotizacionEnviada: false, autorizacion: 'Pendiente' as const, diagnostico: '', conceptos: [] };

export const ORDENES_INICIALES: Orden[] = [
  { ...base, id: 'OT-1083', cliente: 'Oswaldo Cruz', vehiculo: 'Toyota Hilux 2021', placas: 'ABC-892', servicio: 'Frenos delanteros', estado: 'Cotizada', sinCuenta: true, telefono: '998 555 0142', diagnostico: 'Pastillas delanteras con desgaste severo. Discos requieren rectificado para evitar daño mayor.', conceptos: cotizacionFrenos },
  { ...base, id: 'OT-1082', cliente: 'Carlos Mendoza', vehiculo: 'Toyota Hilux 2021', placas: 'ABC-892', servicio: 'Frenos delanteros', estado: 'Cotizada', diagnostico: 'Pastillas delanteras con desgaste severo. Discos requieren rectificado para evitar daño mayor.', conceptos: cotizacionFrenos },
  { ...base, id: 'OT-1081', cliente: 'Andrea Morales', vehiculo: 'Mazda 3 2022', placas: 'KTR-415', servicio: 'Cambio de aceite', estado: 'En diagnóstico' },
  { ...base, id: 'OT-1080', cliente: 'Roberto Vega', vehiculo: 'Ford Ranger 2019', placas: 'PZX-330', servicio: 'Diagnóstico general', estado: 'Recibida' },
  { ...base, id: 'OT-1079', cliente: 'Mariana Silva', vehiculo: 'Honda CR-V 2020', placas: 'JKL-901', servicio: 'Afinación mayor', estado: 'En reparación', autorizacion: 'Autorizada', cotizacionEnviada: true, diagnostico: 'Bujías y filtros al límite de su vida útil.', conceptos: [{ id: 'm1', concepto: 'Afinación mayor', tipo: 'Labor', cantidad: 1, precio: 2850 }] },
  { ...base, id: 'OT-1078', cliente: 'Luis Pérez', vehiculo: 'Nissan Versa 2018', placas: 'NMR-208', servicio: 'Alineación', estado: 'Lista', autorizacion: 'Autorizada', cotizacionEnviada: true, diagnostico: 'Desalineación leve en eje delantero.', conceptos: [{ id: 'l1', concepto: 'Alineación y balanceo', tipo: 'Labor', cantidad: 1, precio: 780 }] },
  { ...base, id: 'OT-1077', cliente: 'Ana Ruiz', vehiculo: 'VW Jetta 2017', placas: 'HTR-554', servicio: 'Cambio de embrague', estado: 'En reparación', autorizacion: 'Autorizada', cotizacionEnviada: true, diagnostico: 'Embrague patina en segunda y tercera.', conceptos: [{ id: 'e1', concepto: 'Kit de embrague', tipo: 'Refacción', cantidad: 1, precio: 4200 }, { id: 'e2', concepto: 'Mano de obra', tipo: 'Labor', cantidad: 5, precio: 300 }] },
];

export const SERVICIOS_INICIALES: Servicio[] = [
  { id: 's1', nombre: 'Cambio de aceite y filtro', categoria: 'Preventivo', descripcion: 'Aceite sintético y filtro de aceite.', precio: 1200, duracion: 1, garantia: 3, activo: true },
  { id: 's2', nombre: 'Frenos delanteros', categoria: 'Frenos', descripcion: 'Pastillas cerámicas y rectificado.', precio: 1950, duracion: 2, garantia: 6, activo: true },
  { id: 's3', nombre: 'Afinación mayor', categoria: 'Preventivo', descripcion: 'Bujías, filtros y fluidos.', precio: 2850, duracion: 2.5, garantia: 6, activo: true },
  { id: 's4', nombre: 'Alineación y balanceo', categoria: 'Suspensión', descripcion: 'Alineación 3D, 4 ruedas.', precio: 780, duracion: 1, garantia: 3, activo: true },
  { id: 's5', nombre: 'Diagnóstico con escáner', categoria: 'Eléctrico', descripcion: 'Lectura de códigos de falla.', precio: 450, duracion: 0.5, garantia: 1, activo: true },
  { id: 's6', nombre: 'Limpieza de inyectores', categoria: 'Motor', descripcion: 'Limpieza ultrasónica.', precio: 1200, duracion: 2, garantia: 3, activo: false },
];

export const NOTIFICACIONES_INICIALES: Notificacion[] = [
  { id: 'n1', tipo: 'cita', tono: 'amber', titulo: 'Nueva cita exprés', detalle: 'Oswaldo Cruz (sin cuenta) · 998 555 0142 · Frenos delanteros · 26 oct, 10:00', tiempo: 'hace 5 min', leida: false, accion: { label: 'Ver cita', destino: { name: 'citas' }, primaria: true } },
  { id: 'n2', tipo: 'cotizacion', tono: 'green', titulo: 'Cotización autorizada', detalle: 'Carlos Mendoza autorizó la cotización de OT-1082 · $3,100.00', tiempo: 'hace 18 min', leida: false, accion: { label: 'Ver orden', destino: { name: 'orden', id: 'OT-1082' }, primaria: true } },
  { id: 'n3', tipo: 'cita', tono: 'amber', titulo: 'Nueva cita solicitada', detalle: 'Andrea Morales pidió cita para Cambio de aceite · 24 oct, 11:00', tiempo: 'hace 1 h', leida: false, accion: { label: 'Ver cita', destino: { name: 'citas' }, primaria: true } },
  { id: 'n4', tipo: 'cotizacion', tono: 'red', titulo: 'Cotización rechazada', detalle: 'Ana Ruiz rechazó la cotización de OT-1077', tiempo: 'ayer', leida: true, accion: { label: 'Ver orden', destino: { name: 'orden', id: 'OT-1077' }, primaria: false } },
  { id: 'n5', tipo: 'cita', tono: 'slate', titulo: 'Cita cancelada por el cliente', detalle: 'Luis Pérez canceló su cita del 25 oct, 10:00', tiempo: 'ayer', leida: true, accion: { label: 'Ver cita', destino: { name: 'citas' }, primaria: false } },
];
