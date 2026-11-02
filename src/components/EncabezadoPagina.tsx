import type { ReactNode } from 'react'

type PropiedadesEncabezadoPagina = {
  rotuloSuperior: string
  titulo: string
  descripcion: string
  accion?: ReactNode
}

export default function EncabezadoPagina({ rotuloSuperior, titulo, descripcion, accion }: PropiedadesEncabezadoPagina) {
  return <section className="introduccion-pagina"><div><div className="rotulo">{rotuloSuperior}</div><h1>{titulo}</h1><p>{descripcion}</p></div>{accion}</section>
}