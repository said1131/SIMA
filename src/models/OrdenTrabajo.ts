export type EstadoOrdenTrabajo = 'En diagnóstico' | 'Cotizada' | 'En reparación' | 'Lista para entregar'

export class OrdenTrabajo {
  readonly id: string
  readonly cliente: string
  readonly vehiculo: string
  readonly placas: string
  readonly servicio: string
  readonly estado: EstadoOrdenTrabajo
  readonly fecha: string
  readonly total: number

  constructor(
    id: string,
    cliente: string,
    vehiculo: string,
    placas: string,
    servicio: string,
    estado: EstadoOrdenTrabajo,
    fecha: string,
    total: number,
  ) {
    this.id = id
    this.cliente = cliente
    this.vehiculo = vehiculo
    this.placas = placas
    this.servicio = servicio
    this.estado = estado
    this.fecha = fecha
    this.total = total
  }

  conEstado(estado: EstadoOrdenTrabajo): OrdenTrabajo {
    return new OrdenTrabajo(this.id, this.cliente, this.vehiculo, this.placas, this.servicio, estado, this.fecha, this.total)
  }
}