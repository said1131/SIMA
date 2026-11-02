import type { Cita, EstadoCita } from '../models/Cita'
import Icono from '../components/Icono'
import EncabezadoPagina from '../components/EncabezadoPagina'
import EstadoVacio from '../components/EstadoVacio'
import { etiquetaEstadoCita, claseEstado } from '../util/presentacion'

export type FiltroCitas = 'Todas' | EstadoCita

type PropiedadesPaginaCitas = {
  citas: Cita[]
  citasFiltradas: Cita[]
  filtro: FiltroCitas
  alCambiarFiltro: (filtro: FiltroCitas) => void
  alActualizar: (id: number, estado: EstadoCita) => void
  alCrearOrden: (cita: Cita) => void
  alAbrirOrden: (id: string) => void
}

const filtros: FiltroCitas[] = ['Todas', 'Solicitada', 'Confirmada', 'Rechazada']

export default function PaginaCitas({
  citas,
  citasFiltradas,
  filtro,
  alCambiarFiltro,
  alActualizar,
  alCrearOrden,
  alAbrirOrden,
}: PropiedadesPaginaCitas) {
  return (
    <>
      <EncabezadoPagina rotuloSuperior="AGENDA DEL TALLER" titulo="Citas solicitadas" descripcion="Revisa las solicitudes y organiza las próximas entradas al taller." />
      <section className="panel panel-tabla">
        <div className="barra-herramientas-lista">
          <div className="pestanas-filtro">
            {filtros.map((elemento) => <button key={elemento} className={filtro === elemento ? 'filtro-tab activo' : 'filtro-tab'} onClick={() => alCambiarFiltro(elemento)}>
              {elemento === 'Rechazada' ? 'Solicitud Rechazada' : elemento}<span>{elemento === 'Todas' ? citas.length : citas.filter((cita) => cita.estado === elemento).length}</span>
            </button>)}
          </div>
          <div className="fecha-herramientas"><Icono nombre="calendario" tamano={16} /><span>29 oct – 05 nov, 2026</span></div>
        </div>
        <div className="desplazamiento-tabla"><table><thead><tr><th>Fecha y hora</th><th>Cliente</th><th>Vehículo</th><th>Servicio solicitado</th><th>Estado</th><th>Acciones</th></tr></thead>
          <tbody>{citasFiltradas.map((cita) => <tr key={cita.id}>
            <td><strong>{cita.fecha}</strong><small>{cita.hora} h</small></td><td>{cita.cliente}</td><td>{cita.vehiculo}</td><td>{cita.servicio}</td>
            <td><span className={`insignia-estado ${claseEstado(cita.estado)}`}>{etiquetaEstadoCita(cita.estado)}</span></td>
            <td><div className="acciones-tabla">{cita.estado === 'Solicitada' ? <><button className="boton boton-compacto boton-principal" onClick={() => alActualizar(cita.id, 'Confirmada')}>Aceptar</button><button className="boton boton-compacto boton-discreto" onClick={() => alActualizar(cita.id, 'Rechazada')}>Rechazar</button></> : cita.estado === 'Confirmada' && cita.idOrden ? <button className="boton boton-compacto boton-contorno" onClick={() => alAbrirOrden(cita.idOrden!)}>Ver orden</button> : cita.estado === 'Confirmada' ? <button className="boton boton-compacto boton-contorno" onClick={() => alCrearOrden(cita)}>Crear orden</button> : <span className="atenuado">Sin acciones</span>}</div></td>
          </tr>)}</tbody>
        </table>{citasFiltradas.length === 0 && <EstadoVacio titulo="No hay citas con este filtro" descripcion="Prueba otra categoría o vuelve a ver todas las solicitudes." />}</div>
      </section>
    </>
  )
}