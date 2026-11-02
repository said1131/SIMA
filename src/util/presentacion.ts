import type { EstadoCita } from '../models/Cita'

export const claseEstado = (estado: string) => estado.toLowerCase().replaceAll(' ', '-')

export const etiquetaEstadoCita = (estado: EstadoCita) => estado === 'Rechazada' ? 'Solicitud Rechazada' : estado

export const formatearMoneda = (amount: number) => new Intl.NumberFormat('es-MX', {
  style: 'currency',
  currency: 'MXN',
  maximumFractionDigits: 0,
}).format(amount)