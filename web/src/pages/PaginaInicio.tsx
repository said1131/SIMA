import type { Cita } from '../models/Cita'
import type { OrdenTrabajo, EstadoOrdenTrabajo } from '../models/OrdenTrabajo'
import Icono from '../components/Icono'
import TablaOrdenes from '../components/TablaOrdenes'
import { etiquetaEstadoCita, claseEstado } from '../util/presentacion'

type PropiedadesPaginaInicio = {
  citas: Cita[]
  ordenes: OrdenTrabajo[]
  citasPendientes: number
  citasDeHoy: number
  ordenesEnReparacion: number
  ordenesListas: number
  alNavegar: (pagina: 'citas' | 'ordenes') => void
  alFiltrarCitas: (estado: 'Solicitada' | 'Todas') => void
  alFiltrarOrdenes: (estado: EstadoOrdenTrabajo) => void
  alAbrirOrden: (id: string) => void
}

const estadosOrden: EstadoOrdenTrabajo[] = ['En diagnóstico', 'Cotizada', 'En reparación', 'Lista para entregar']

export default function PaginaInicio({
  citas,
  ordenes,
  citasPendientes,
  citasDeHoy,
  ordenesEnReparacion,
  ordenesListas,
  alNavegar,
  alFiltrarCitas,
  alFiltrarOrdenes,
  alAbrirOrden,
}: PropiedadesPaginaInicio) {
  return (
    <>
      <section className="fila-bienvenida">
        <div>
          <h1>Buenos días.</h1>
          <p>Esto es lo que pasa hoy en el taller.</p>
        </div>
        <button className="boton boton-principal" onClick={() => alNavegar('ordenes')}><Icono nombre="mas" /> Nueva orden</button>
      </section>

      <section className="rejilla-metricas" aria-label="Resumen del taller">
        <button className="tarjeta-metrica" onClick={() => { alFiltrarCitas('Todas'); alNavegar('citas') }}>
          <span className="icono-metrica azul"><Icono nombre="calendario" /></span>
          <span className="rotulo-metrica">Citas de hoy</span><strong>{String(citasDeHoy).padStart(2, '0')}</strong>
          <span className="pie-metrica"><b className="cambio-metrica">+2</b> respecto a ayer</span>
        </button>
        <button className="tarjeta-metrica" onClick={() => { alFiltrarCitas('Solicitada'); alNavegar('citas') }}>
          <span className="icono-metrica rojo"><Icono nombre="reloj" /></span>
          <span className="rotulo-metrica">Por confirmar</span><strong>{String(citasPendientes).padStart(2, '0')}</strong>
          <span className="pie-metrica">Requieren tu atención</span>
        </button>
        <button className="tarjeta-metrica" onClick={() => { alFiltrarOrdenes('En reparación'); alNavegar('ordenes') }}>
          <span className="icono-metrica azul-marino"><Icono nombre="llave" /></span>
          <span className="rotulo-metrica">En reparación</span><strong>{String(ordenesEnReparacion).padStart(2, '0')}</strong>
          <span className="pie-metrica">Órdenes activas</span>
        </button>
        <button className="tarjeta-metrica" onClick={() => { alFiltrarOrdenes('Lista para entregar'); alNavegar('ordenes') }}>
          <span className="icono-metrica verde"><Icono nombre="marca" /></span>
          <span className="rotulo-metrica">Listas para entregar</span><strong>{String(ordenesListas).padStart(2, '0')}</strong>
          <span className="pie-metrica">Pendientes de entrega</span>
        </button>
      </section>

      <section className="rejilla-panel">
        <div className="panel panel-carga">
          <div className="encabezado-panel"><div><span className="rotulo">VISTA GENERAL</span><h2>Órdenes por estado</h2></div><button className="boton-icono" title="Ver órdenes" onClick={() => alNavegar('ordenes')}><Icono nombre="flecha" /></button></div>
          <div className="total-trabajo"><strong>{String(ordenes.length).padStart(2, '0')}</strong><span>órdenes abiertas</span></div>
          <div className="barras-estados">
            {estadosOrden.map((estado, indice) => {
              const cantidad = ordenes.filter((orden) => orden.estado === estado).length
              return <button className="fila-barra" key={estado} onClick={() => { alFiltrarOrdenes(estado); alNavegar('ordenes') }}>
                <span>{estado}</span><div className="riel-barra"><span className={`relleno-barra tono-${indice}`} style={{ width: `${Math.max(cantidad / Math.max(ordenes.length, 1) * 100, 8)}%` }} /></div><b>{String(cantidad).padStart(2, '0')}</b>
              </button>
            })}
          </div>
          <div className="nota-panel"><span className="punto-activo" /> Actualizado hace un momento</div>
        </div>

        <div className="panel citas-panel">
          <div className="encabezado-panel"><div><span className="rotulo">AGENDA</span><h2>Citas de hoy</h2></div><button className="enlace-texto" onClick={() => alNavegar('citas')}>Ver todas <Icono nombre="flecha" tamano={15} /></button></div>
          <div className="lista-citas">
            {citas.filter((cita) => cita.fecha.startsWith('Hoy')).slice(0, 3).map((cita) => (
              <div className="elemento-cita" key={cita.id}>
                <div className="hora-cita">{cita.hora}</div>
                <div className="datos-cita"><strong>{cita.cliente}</strong><span>{cita.vehiculo} · {cita.servicio}</span></div>
                <span className={`insignia-estado ${claseEstado(cita.estado)}`}>{etiquetaEstadoCita(cita.estado)}</span>
              </div>
            ))}
          </div>
          <button className="enlace-completo" onClick={() => alNavegar('citas')}>Ir a solicitudes de cita <Icono nombre="flecha" tamano={15} /></button>
        </div>
      </section>

      <section className="panel panel-reciente">
        <div className="encabezado-panel"><div><span className="rotulo">ACTIVIDAD RECIENTE</span><h2>Órdenes de trabajo</h2></div><button className="enlace-texto" onClick={() => alNavegar('ordenes')}>Ver órdenes <Icono nombre="flecha" tamano={15} /></button></div>
        <div className="desplazamiento-tabla"><TablaOrdenes ordenes={ordenes.slice(0, 3)} alAbrir={alAbrirOrden} /></div>
      </section>
    </>
  )
}