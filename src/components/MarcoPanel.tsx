import { useState, type ReactNode } from 'react'
import logotipo from '../assets/Logotipo.jpg'
import type { PaginaAdmin, PaginaNavegacion } from '../models/PaginaAdmin'
import Icono from './Icono'

type PropiedadesMarcoPanel = {
  pagina: PaginaAdmin
  citasPendientes: number
  busqueda: string
  aviso: string
  children: ReactNode
  alBuscar: (value: string) => void
  alNavegar: (pagina: PaginaNavegacion) => void
  alNotificar: () => void
  alCerrarSesion: () => void
  alCerrarAviso: () => void
}

const elementosNavegacion: { id: PaginaNavegacion; etiqueta: string; icono: string }[] = [
  { id: 'inicio', etiqueta: 'Panel de inicio', icono: 'cuadricula' },
  { id: 'citas', etiqueta: 'Citas', icono: 'calendario' },
  { id: 'ordenes', etiqueta: 'Órdenes de trabajo', icono: 'llave' },
  { id: 'catalogo', etiqueta: 'Catálogo', icono: 'capas' },
]

export default function MarcoPanel({
  pagina,
  citasPendientes,
  busqueda,
  aviso,
  children,
  alBuscar,
  alNavegar,
  alNotificar,
  alCerrarSesion,
  alCerrarAviso,
}: PropiedadesMarcoPanel) {
  const [menuCuentaAbierto, establecerMenuCuentaAbierto] = useState(false)
  const etiquetaActual = pagina === 'detalle' ? 'Órdenes de trabajo / Detalle' : elementosNavegacion.find((elemento) => elemento.id === pagina)?.etiqueta

  return (
    <div className="marco-aplicacion">
      <aside className="barra-lateral">
        <button className="marca" onClick={() => alNavegar('inicio')} aria-label="SIMA, ir al inicio"><img className="logotipo-marca" src={logotipo} alt="SIMA" /><span className="texto-marca"><strong>SIMA</strong><small>TALLER AUTOMOTRIZ</small></span></button>
        <div className="rotulo-lateral">MENÚ PRINCIPAL</div>
        <nav className="navegacion-lateral" aria-label="Navegación principal">{elementosNavegacion.map((elemento) => <button key={elemento.id} className={`elemento-navegacion ${pagina === elemento.id || (pagina === 'detalle' && elemento.id === 'ordenes') ? 'seleccionado' : ''}`} title={elemento.etiqueta} aria-label={elemento.etiqueta} onClick={() => alNavegar(elemento.id)}><Icono nombre={elemento.icono} /><span>{elemento.etiqueta}</span>{elemento.id === 'citas' && citasPendientes > 0 && <b className="contador-navegacion">{citasPendientes}</b>}</button>)}</nav>
        <div className="pie-lateral">
          <div className="tarjeta-taller"><div className="indicador-taller" /><div><strong>Taller SIMA</strong><span>Operación activa</span></div><span className="menu-taller">···</span></div>
          <div className="contenedor-cuenta">
            <button className="fila-perfil" aria-expanded={menuCuentaAbierto} aria-haspopup="menu" onClick={() => establecerMenuCuentaAbierto((open) => !open)}><span className="insignia insignia-perfil">OS</span><span className="texto-perfil"><strong>Oswaldo Cruz</strong><small>Administrador</small></span><span className="flecha-perfil">{menuCuentaAbierto ? '⌃' : '⌄'}</span></button>
            {menuCuentaAbierto && <div className="menu-cuenta" role="menu"><div className="encabezado-menu-cuenta"><strong>Oswaldo Cruz</strong><span>Administrador</span></div><button role="menuitem" onClick={alCerrarSesion}><Icono nombre="cerrarSesion" tamano={16} /> Cerrar sesión</button></div>}
          </div>
        </div>
      </aside>

      <main className="area-principal">
        <header className="barra-superior"><div className="migas-pan"><span>SIMA</span><span className="separador-migas">/</span><strong>{etiquetaActual}</strong></div>
          <div className="acciones-superiores"><label className="caja-busqueda"><Icono nombre="busqueda" tamano={17} /><input value={busqueda} onChange={(evento) => alBuscar(evento.target.value)} placeholder="Buscar cliente, vehículo u orden" aria-label="Buscar" /></label><button className="boton-notificaciones" aria-label="Notificaciones" onClick={alNotificar}><Icono nombre="campana" /><i /></button><span className="separador-superior" /><span className="rotulo-fecha">MIÉ, 29 OCT</span></div>
        </header>
        <div className="area-contenido">{children}</div>
      </main>
      {aviso && <div className="aviso-emergente" role="status"><span className="confirmacion-aviso"><Icono nombre="marca" tamano={15} /></span>{aviso}<button onClick={alCerrarAviso} aria-label="Cerrar notificación"><Icono nombre="cerrar" tamano={15} /></button></div>}
    </div>
  )
}