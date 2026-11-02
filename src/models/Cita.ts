export type EstadoCita = 'Solicitada' | 'Confirmada' | 'Rechazada'

export class Cita {
  readonly id: number
  readonly cliente: string
  readonly vehiculo: string
  readonly servicio: string
  readonly fecha: string
  readonly hora: string
  readonly estado: EstadoCita
  readonly idOrden?: string

  constructor(
    id: number,
    cliente: string,
    vehiculo: string,
    servicio: string,
    fecha: string,
    hora: string,
    estado: EstadoCita,
    idOrden?: string,
  ) {
    this.id = id
    this.cliente = cliente
    this.vehiculo = vehiculo
    this.servicio = servicio
    this.fecha = fecha
    this.hora = hora
    this.estado = estado
    this.idOrden = idOrden
  }

  conEstado(estado: EstadoCita, idOrden = this.idOrden): Cita {
    return new Cita(this.id, this.cliente, this.vehiculo, this.servicio, this.fecha, this.hora, estado, idOrden)
  }
}