import { useState, type FormEvent } from 'react'
import Icono from '../components/Icono'
import EncabezadoPagina from '../components/EncabezadoPagina'
import { ServicioTaller } from '../models/ServicioTaller'
import { formatearMoneda } from '../util/presentacion'

type PropiedadesPaginaCatalogo = {
  servicios: ServicioTaller[]
  alAlternar: (nombre: string) => void
  alAgregar: (servicio: ServicioTaller) => void
}

export default function PaginaCatalogo({ servicios, alAlternar, alAgregar }: PropiedadesPaginaCatalogo) {
  const [mostrarFormulario, establecerMostrarFormulario] = useState(false)
  const [nombre, establecerNombre] = useState('')
  const [precio, establecerPrecio] = useState('')

  const gestionarEnvio = (evento: FormEvent<HTMLFormElement>) => {
    evento.preventDefault()
    if (!nombre.trim() || !precio) return
    alAgregar(new ServicioTaller(nombre.trim(), 'Servicio del taller', Number(precio), true))
    establecerNombre('')
    establecerPrecio('')
    establecerMostrarFormulario(false)
  }

  return (
    <>
      <EncabezadoPagina rotuloSuperior="SERVICIOS DEL TALLER" titulo="Catálogo de servicios" descripcion="Administra los servicios y precios estimados que ven tus clientes." accion={<button className="boton boton-principal" onClick={() => establecerMostrarFormulario((visible) => !visible)}><Icono nombre="mas" /> Agregar servicio</button>} />
      <div className="distribucion-catalogo">
        <section className="panel panel-tabla panel-tabla-catalogo">
          <div className="encabezado-panel encabezado-catalogo"><div><span className="rotulo">LISTA DE SERVICIOS</span><h2>{servicios.length} servicios</h2></div><span className="contador-activos-catalogo">{servicios.filter((servicio) => servicio.activo).length} activos</span></div>
          <div className="desplazamiento-tabla"><table><thead><tr><th>Servicio</th><th>Descripción</th><th>Precio estimado</th><th>Estado</th><th>Acciones</th></tr></thead><tbody>
            {servicios.map((servicio) => <tr key={servicio.nombre}><td><strong>{servicio.nombre}</strong></td><td>{servicio.descripcion}</td><td><strong>{formatearMoneda(servicio.precio)}</strong></td><td><span className={`insignia-estado ${servicio.activo ? 'servicio-activo' : 'servicio-inactivo'}`}>{servicio.activo ? 'Activo' : 'Inactivo'}</span></td><td><button className="boton boton-compacto boton-discreto" onClick={() => alAlternar(servicio.nombre)}>{servicio.activo ? 'Desactivar' : 'Activar'}</button></td></tr>)}
          </tbody></table></div>
        </section>
        {mostrarFormulario && <section className="panel panel-formulario-servicio"><div className="encabezado-panel"><div><span className="rotulo">NUEVO SERVICIO</span><h2>Agregar al catálogo</h2></div><button className="boton-icono" aria-label="Cerrar formulario" onClick={() => establecerMostrarFormulario(false)}><Icono nombre="cerrar" /></button></div>
          <form onSubmit={gestionarEnvio}>
            <label className="rotulo-campo" htmlFor="servicio-nombre">Nombre del servicio</label><input id="servicio-nombre" className="entrada-formulario" value={nombre} onChange={(evento) => establecerNombre(evento.target.value)} placeholder="Ej. Alineación y balanceo" required />
            <label className="rotulo-campo" htmlFor="servicio-precio">Precio estimado (MXN)</label><input id="servicio-precio" className="entrada-formulario" type="number" min="0" value={precio} onChange={(evento) => establecerPrecio(evento.target.value)} placeholder="0.00" required />
            <button type="submit" className="boton boton-principal">Guardar servicio</button>
          </form>
        </section>}
      </div>
    </>
  )
}