import type { OrdenTrabajo } from '../models/OrdenTrabajo'
import { formatearMoneda, claseEstado } from '../util/presentacion'

type PropiedadesTablaOrdenes = {
  ordenes: OrdenTrabajo[]
  alAbrir: (id: string) => void
}

export default function TablaOrdenes({ ordenes, alAbrir }: PropiedadesTablaOrdenes) {
  return <table><thead><tr><th>No. de orden</th><th>Cliente</th><th>Vehículo</th><th>Servicio</th><th>Estado</th><th>Total</th><th /></tr></thead><tbody>{ordenes.map((orden) => <tr key={orden.id}><td><button className="id-orden" onClick={() => alAbrir(orden.id)}>{orden.id}</button><small>{orden.fecha}</small></td><td>{orden.cliente}</td><td>{orden.vehiculo}<small>{orden.placas}</small></td><td>{orden.servicio}</td><td><span className={`insignia-estado ${claseEstado(orden.estado)}`}>{orden.estado}</span></td><td><strong>{orden.total ? formatearMoneda(orden.total) : 'Por cotizar'}</strong></td><td><button className="abrir-fila" onClick={() => alAbrir(orden.id)} aria-label={`Ver orden ${orden.id}`}><svg aria-hidden="true" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14M13 6l6 6-6 6" /></svg></button></td></tr>)}</tbody></table>
}