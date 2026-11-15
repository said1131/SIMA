export type CitaEstado = 'Solicitada' | 'Confirmada' | 'Rechazada';

export interface Cita {
  id: string;
  cliente: string;
  vehiculo: string;
  placas: string;
  servicio: string;
  fecha: string; // ISO yyyy-mm-dd
  hora: string; // HH:mm
  estado: CitaEstado;
  expres?: boolean;
  telefono?: string;
  clienteId?: number;
  vehiculoId?: number;
  servicioId?: number;
}

export type OrdenEstado =
  | 'Recibida'
  | 'En diagnóstico'
  | 'Cotizada'
  | 'Autorizada'
  | 'En reparación'
  | 'Lista'
  | 'Entregada';

export type TipoConcepto = 'Refacción' | 'Tornería' | 'Labor';

export interface Concepto {
  id: string;
  concepto: string;
  tipo: TipoConcepto;
  cantidad: number;
  precio: number;
}

export type Autorizacion = 'Pendiente' | 'Autorizada' | 'Rechazada';

export interface Orden {
  id: string; // OT-1082
  dbId?: number;
  cliente: string;
  vehiculo: string;
  placas: string;
  servicio: string;
  estado: OrdenEstado;
  diagnostico: string;
  conceptos: Concepto[];
  autorizacion: Autorizacion;
  cotizacionEnviada: boolean;
  sinCuenta?: boolean;
  telefono?: string;
  kilometraje?: number;
  notas?: string;
  clienteId?: number;
  vehiculoId?: number;
  servicioId?: number;
  citaId?: number;
}

export interface Cliente {
  id: string;
  nombre: string;
  sinCuenta?: boolean;
  telefono?: string;
  vehiculos: { id?: number; descripcion: string; placas: string }[];
}

export type Categoria = 'Preventivo' | 'Frenos' | 'Eléctrico' | 'Suspensión' | 'Motor';

export interface Servicio {
  id: string;
  nombre: string;
  categoria: Categoria;
  descripcion: string;
  precio: number;
  duracion: number;
  garantia: number;
  activo: boolean;
}

export type NotifTipo = 'cita' | 'orden' | 'cotizacion';
export type NotifTono = 'amber' | 'green' | 'red' | 'slate';

export type Page =
  | { name: 'dashboard' }
  | { name: 'citas' }
  | { name: 'ordenes' }
  | { name: 'nueva-orden'; citaId?: string }
  | { name: 'orden'; id: string }
  | { name: 'catalogo' }
  | { name: 'notificaciones' };

export interface Notificacion {
  id: string;
  tipo: NotifTipo;
  tono: NotifTono;
  titulo: string;
  detalle: string;
  tiempo: string;
  leida: boolean;
  refTipo?: string;
  refId?: number;
  accion: { label: string; destino: Page; primaria: boolean };
}
