export type Role = 'cliente' | 'mecanico' | 'admin';

export const ORDEN_ESTADOS = [
  'Recibida',
  'En diagnóstico',
  'Cotizada',
  'Autorizada',
  'En reparación',
  'Lista',
  'Entregada',
] as const;
export type OrdenEstado = (typeof ORDEN_ESTADOS)[number];

export const CITA_ESTADOS = ['Solicitada', 'Confirmada', 'Rechazada', 'Cancelada'] as const;
export type CitaEstado = (typeof CITA_ESTADOS)[number];

export const CATEGORIAS = ['Preventivo', 'Correctivo'] as const;
export const TIPOS_CONCEPTO = ['Refacción', 'Tornería', 'Labor'] as const;

export const IVA = 0.16;
