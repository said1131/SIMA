import type { OrdenTrabajo, EstadoOrdenTrabajo } from '../models/OrdenTrabajo'
import Icono from '../components/Icono'
import EncabezadoPagina from '../components/EncabezadoPagina'
import { formatearMoneda, claseEstado } from '../util/presentacion'

type PropiedadesPaginaDetalleOrden = {
  orden: OrdenTrabajo
  alRegresar: () => void
  alCambiarEstado: (estado: EstadoOrdenTrabajo) => void
  alNotificar: (mensaje: string) => void
}

const estadosOrden: EstadoOrdenTrabajo[] = ['En diagnóstico', 'Cotizada', 'En reparación', 'Lista para entregar']

export default function PaginaDetalleOrden({ orden, alRegresar, alCambiarEstado, alNotificar }: PropiedadesPaginaDetalleOrden) {
  const indiceActual = estadosOrden.indexOf(orden.estado)

  return (
    <>
      <div className="linea-superior-detalle"><button className="enlace-regreso" onClick={alRegresar}><Icono nombre="regresar" tamano={17} /> Órdenes de trabajo</button><span className="id-orden-detalle">ORDEN {orden.id}</span></div>
      <EncabezadoPagina rotuloSuperior="DETALLE DE ORDEN" titulo={orden.cliente} descripcion={`${orden.vehiculo} · ${orden.placas}`} accion={<span className={`insignia-estado grande ${claseEstado(orden.estado)}`}>{orden.estado}</span>} />
      <div className="rejilla-detalle">
        <section className="panel detalle-principal">
          <div className="encabezado-panel"><div><span className="rotulo">INFORMACIÓN DEL VEHÍCULO</span><h2>{orden.servicio}</h2></div><span className="marca-vehiculo"><Icono nombre="automovil" tamano={22} /></span></div>
          <div className="resumen-vehiculo"><div><span>Vehículo</span><strong>{orden.vehiculo}</strong></div><div><span>Placas</span><strong>{orden.placas}</strong></div><div><span>Ingreso</span><strong>{orden.fecha}</strong></div></div>
          <label className="rotulo-campo" htmlFor="diagnostico">Diagnóstico del mecánico</label><textarea id="diagnostico" className="area-texto" placeholder="Describe las condiciones encontradas y el trabajo recomendado…" rows={5} />
          <div className="encabezado-cotizacion"><div><span className="rotulo">COTIZACIÓN</span><h2>Conceptos del servicio</h2></div><button className="boton boton-compacto boton-contorno" onClick={() => alNotificar('Concepto agregado a la cotización.')}><Icono nombre="mas" tamano={15} /> Agregar concepto</button></div>
          <div className="linea-cotizacion"><span>Servicio</span><strong>{orden.servicio}</strong><b>{formatearMoneda(orden.total || 950)}</b></div>
          <div className="linea-cotizacion"><span>Mano de obra</span><strong>Revisión y servicio</strong><b>{formatearMoneda(orden.total ? 700 : 450)}</b></div>
          <div className="total-cotizacion"><span>Total estimado</span><strong>{formatearMoneda(orden.total || 1400)}</strong></div>
          <button className="boton boton-principal" onClick={() => alNotificar('Cotización enviada al cliente para autorización.')}>Enviar cotización <Icono nombre="flecha" tamano={16} /></button>
        </section>
        <aside className="panel lateral-detalle">
          <span className="rotulo">ESTADO DEL SERVICIO</span><h2>Avance de reparación</h2>
          <div className="lista-progreso">{estadosOrden.map((estado, indice) => <div className={`paso-progreso ${indice <= indiceActual ? 'completado' : ''}`} key={estado}><span className="nodo-progreso">{indice < indiceActual ? <Icono nombre="marca" tamano={13} /> : indice + 1}</span><span>{estado}</span></div>)}</div>
          <label className="rotulo-campo" htmlFor="orden-estado">Actualizar estado</label>
          <select id="orden-estado" className="selector-formulario" value={orden.estado} onChange={(evento) => alCambiarEstado(evento.target.value as EstadoOrdenTrabajo)}>
            {estadosOrden.map((estado) => <option key={estado}>{estado}</option>)}
          </select>
          <div className="separador-lateral" />
          <span className="rotulo">CLIENTE</span><div className="fila-cliente"><span className="insignia">{orden.cliente.split(' ').map((part) => part[0]).slice(0, 2).join('')}</span><div><strong>{orden.cliente}</strong><span>Cliente del taller</span></div></div>
        </aside>
      </div>
    </>
  )
}