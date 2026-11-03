import Icono from './Icono'

export default function EstadoVacio({ titulo, descripcion }: { titulo: string; descripcion: string }) {
  return <div className="estado-vacio"><span className="icono-vacio"><Icono nombre="calendario" tamano={21} /></span><strong>{titulo}</strong><p>{descripcion}</p></div>
}