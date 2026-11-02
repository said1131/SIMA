export class ServicioTaller {
  readonly nombre: string
  readonly descripcion: string
  readonly precio: number
  readonly activo: boolean

  constructor(
    nombre: string,
    descripcion: string,
    precio: number,
    activo: boolean,
  ) {
    this.nombre = nombre
    this.descripcion = descripcion
    this.precio = precio
    this.activo = activo
  }

  alternarActivo(): ServicioTaller {
    return new ServicioTaller(this.nombre, this.descripcion, this.precio, !this.activo)
  }
}