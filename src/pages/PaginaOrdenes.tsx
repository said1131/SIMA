import type { OrdenTrabajo, EstadoOrdenTrabajo } from '../models/OrdenTrabajo'
import Icono from '../components/Icono'
import EncabezadoPagina from '../components/EncabezadoPagina'
import TablaOrdenes from '../components/TablaOrdenes'
import EstadoVacio from '../components/EstadoVacio'

export type FiltroOrdenes = 'Todas' | EstadoOrdenTrabajo

type PropiedadesPaginaOrdenes = {
  ordenes: OrdenTrabajo[]
  ordenesFiltradas: OrdenTrabajo[]
  filtro: FiltroOrdenes
  alCambiarFiltro: (filtro: FiltroOrdenes) => void
  alCrear: () => void
  alAbrir: (id: string) => void
}

const filtros: FiltroOrdenes[] = ['Todas', 'En diagnóstico', 'Cotizada', 'En reparación', 'Lista para entregar']

export default function PaginaOrdenes({ ordenes, ordenesFiltradas, filtro, alCambiarFiltro, alCrear, alAbrir }: PropiedadesPaginaOrdenes) {
  return (
    <>
      <EncabezadoPagina rotuloSuperior="SEGUIMIENTO DEL TALLER" titulo="Órdenes de trabajo" descripcion="Cada vehículo, cada servicio y su avance en un solo lugar." accion={<button className="boton boton-principal" onClick={alCrear}><Icono nombre="mas" /> Nueva orden</button>} />
      <section className="panel panel-tabla">
        <div className="barra-herramientas-lista barra-herramientas-orden">
          <div className="pestanas-filtro pestanas-orden">{filtros.map((elemento) => <button key={elemento} className={filtro === elemento ? 'filtro-tab activo' : 'filtro-tab'} onClick={() => alCambiarFiltro(elemento)}>{elemento}{elemento === 'Todas' && <span>{ordenes.length}</span>}</button>)}</div>
          <span className="rotulo-resultados">{ordenesFiltradas.length} órdenes</span>
        </div>
        <div className="desplazamiento-tabla"><TablaOrdenes ordenes={ordenesFiltradas} alAbrir={alAbrir} /></div>
        {ordenesFiltradas.length === 0 && <EstadoVacio titulo="No hay órdenes en este estado" descripcion="Las órdenes aparecerán aquí conforme avance el trabajo." />}
      </section>
    </>
  )
}