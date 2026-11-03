import { useState } from 'react'
import PaginaAcceso from './pages/PaginaAcceso'
import { ServicioAutenticacionAdmin } from './services/ServicioAutenticacionAdmin'
import MarcoPanel from './components/MarcoPanel'
import { citasIniciales, ordenesIniciales, serviciosIniciales } from './data/datosTaller'
import { Cita } from './models/Cita'
import { ServicioTaller } from './models/ServicioTaller'
import { OrdenTrabajo } from './models/OrdenTrabajo'
import PaginaCatalogo from './pages/PaginaCatalogo'
import PaginaInicio from './pages/PaginaInicio'
import PaginaCitas, { type FiltroCitas } from './pages/PaginaCitas'
import PaginaOrdenes, { type FiltroOrdenes } from './pages/PaginaOrdenes'
import PaginaDetalleOrden from './pages/PaginaDetalleOrden'
import type { PaginaAdmin } from './models/PaginaAdmin'

const servicioAutenticacion = new ServicioAutenticacionAdmin()

function Aplicacion() {
  const [estaAutenticado, establecerAutenticado] = useState(false)
  const [pagina, establecerPagina] = useState<PaginaAdmin>('inicio')
  const [citas, establecerCitas] = useState(citasIniciales)
  const [ordenes, establecerOrdenes] = useState(ordenesIniciales)
  const [servicios, establecerServicios] = useState<ServicioTaller[]>(serviciosIniciales)
  const [idOrdenActivo, establecerIdOrdenActivo] = useState(ordenesIniciales[0].id)
  const [filtroCitas, establecerFiltroCitas] = useState<FiltroCitas>('Todas')
  const [filtroOrdenes, establecerFiltroOrdenes] = useState<FiltroOrdenes>('Todas')
  const [busqueda, establecerBusqueda] = useState('')
  const [aviso, establecerAviso] = useState('')

  const notificar = (mensaje: string) => {
    establecerAviso(mensaje)
    window.setTimeout(() => establecerAviso(''), 2800)
  }

  const actualizarCita = (id: number, estado: Cita['estado']) => {
    establecerCitas((actual) => actual.map((cita) => cita.id === id ? cita.conEstado(estado) : cita))
    notificar(estado === 'Confirmada' ? 'La cita quedó confirmada.' : 'Solicitud Rechazada')
  }

  const abrirOrden = (id: string) => {
    establecerIdOrdenActivo(id)
    establecerPagina('detalle')
  }

  const ordenesFiltradas = ordenes.filter((orden) => {
    const coincideEstado = filtroOrdenes === 'Todas' || orden.estado === filtroOrdenes
    const coincideBusqueda = `${orden.id} ${orden.cliente} ${orden.vehiculo} ${orden.placas}`.toLowerCase().includes(busqueda.toLowerCase())
    return coincideEstado && coincideBusqueda
  })

  const citasFiltradas = citas.filter((cita) => {
    const coincideEstado = filtroCitas === 'Todas' || cita.estado === filtroCitas
    const coincideBusqueda = `${cita.cliente} ${cita.vehiculo} ${cita.servicio}`.toLowerCase().includes(busqueda.toLowerCase())
    return coincideEstado && coincideBusqueda
  })

  const ordenSeleccionada = ordenes.find((orden) => orden.id === idOrdenActivo) ?? ordenes[0]
  const citasPendientes = citas.filter((cita) => cita.estado === 'Solicitada').length
  const citasDeHoy = citas.filter((cita) => cita.fecha.startsWith('Hoy')).length
  const ordenesEnReparacion = ordenes.filter((orden) => orden.estado === 'En reparación').length
  const ordenesListas = ordenes.filter((orden) => orden.estado === 'Lista para entregar').length

  if (!estaAutenticado) {
    return <PaginaAcceso alIniciarSesion={(correo, contrasena) => {
      const autenticado = servicioAutenticacion.autenticar(correo, contrasena)
      establecerAutenticado(autenticado)
      return autenticado
    }} />
  }

  const crearOrdenDesdeCita = (cita: Cita) => {
    const siguienteNumero = String(249 + ordenes.length - ordenesIniciales.length).padStart(4, '0')
    const orden = new OrdenTrabajo(`OT-${siguienteNumero}`, cita.cliente, cita.vehiculo, 'Por registrar', cita.servicio, 'En diagnóstico', `${cita.fecha}, ${cita.hora}`, 0)
    establecerOrdenes((actual) => [orden, ...actual])
    establecerCitas((actual) => actual.map((elemento) => elemento.id === cita.id ? elemento.conEstado('Confirmada', orden.id) : elemento))
    establecerIdOrdenActivo(orden.id)
    establecerPagina('detalle')
    notificar(`Se creó la orden ${orden.id}.`)
  }

  const crearOrdenNueva = () => {
    const id = `OT-${String(249 + ordenes.length - ordenesIniciales.length).padStart(4, '0')}`
    const orden = new OrdenTrabajo(id, 'Nuevo cliente', 'Vehículo por registrar', 'Por registrar', 'Diagnóstico general', 'En diagnóstico', 'Hoy, ahora', 0)
    establecerOrdenes((actual) => [orden, ...actual])
    abrirOrden(id)
  }

  const agregarServicio = (servicio: ServicioTaller) => {
    establecerServicios((actual) => [...actual, servicio])
    notificar('Servicio agregado al catálogo.')
  }

  return (
    <MarcoPanel
      pagina={pagina}
      citasPendientes={citasPendientes}
      busqueda={busqueda}
      aviso={aviso}
      alBuscar={establecerBusqueda}
      alNavegar={establecerPagina}
      alNotificar={() => notificar(`${citasPendientes} citas esperan confirmación.`)}
      alCerrarSesion={() => { establecerAutenticado(false); establecerPagina('inicio'); establecerBusqueda(''); establecerAviso('') }}
      alCerrarAviso={() => establecerAviso('')}
    >
      {pagina === 'inicio' && <PaginaInicio citas={citas} ordenes={ordenes} citasPendientes={citasPendientes} citasDeHoy={citasDeHoy} ordenesEnReparacion={ordenesEnReparacion} ordenesListas={ordenesListas} alNavegar={establecerPagina} alFiltrarCitas={establecerFiltroCitas} alFiltrarOrdenes={establecerFiltroOrdenes} alAbrirOrden={abrirOrden} />}
      {pagina === 'citas' && <PaginaCitas citas={citas} citasFiltradas={citasFiltradas} filtro={filtroCitas} alCambiarFiltro={establecerFiltroCitas} alActualizar={actualizarCita} alCrearOrden={crearOrdenDesdeCita} alAbrirOrden={abrirOrden} />}
      {pagina === 'ordenes' && <PaginaOrdenes ordenes={ordenes} ordenesFiltradas={ordenesFiltradas} filtro={filtroOrdenes} alCambiarFiltro={establecerFiltroOrdenes} alCrear={crearOrdenNueva} alAbrir={abrirOrden} />}
      {pagina === 'detalle' && <PaginaDetalleOrden orden={ordenSeleccionada} alRegresar={() => establecerPagina('ordenes')} alCambiarEstado={(estado) => establecerOrdenes((actual) => actual.map((orden) => orden.id === ordenSeleccionada.id ? orden.conEstado(estado) : orden))} alNotificar={notificar} />}
      {pagina === 'catalogo' && <PaginaCatalogo servicios={servicios} alAlternar={(nombre) => establecerServicios((actual) => actual.map((servicio) => servicio.nombre === nombre ? servicio.alternarActivo() : servicio))} alAgregar={agregarServicio} />}
    </MarcoPanel>
  )
}

export default Aplicacion