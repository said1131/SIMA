import { useState, type FormEvent } from 'react'
import logotipo from '../assets/Logotipo.jpg'

type PropiedadesPaginaAcceso = {
  alIniciarSesion: (correo: string, contrasena: string) => boolean
}

export default function PaginaAcceso({ alIniciarSesion }: PropiedadesPaginaAcceso) {
  const [correo, establecerCorreo] = useState('')
  const [contrasena, establecerContrasena] = useState('')
  const [hayError, establecerHayError] = useState(false)

  const gestionarEnvio = (evento: FormEvent<HTMLFormElement>) => {
    evento.preventDefault()
    establecerHayError(!alIniciarSesion(correo, contrasena))
  }

  return (
    <main className="pagina-acceso">
      <section className="panel-acceso" aria-labelledby="titulo-acceso">
        <img className="logotipo-acceso" src={logotipo} alt="SIMA, taller automotriz" />
        <div className="encabezado-acceso">
          <span className="rotulo">PANEL ADMINISTRATIVO DEL TALLER</span>
          <h1 id="titulo-acceso">Bienvenido de nuevo</h1>
          <p>Ingresa con tu cuenta de administrador.</p>
        </div>
        <form className="formulario-acceso" onSubmit={gestionarEnvio}>
          <label className="rotulo-campo" htmlFor="login-correo">Correo</label>
          <input
            autoComplete="username"
            className="entrada-formulario"
            id="login-correo"
            onChange={(evento) => establecerCorreo(evento.target.value)}
            placeholder="correo@taller.com"
            required
            type="email"
            value={correo}
          />
          <label className="rotulo-campo" htmlFor="login-contrasena">Contraseña</label>
          <input
            autoComplete="current-password"
            className="entrada-formulario"
            id="login-contrasena"
            onChange={(evento) => establecerContrasena(evento.target.value)}
            required
            type="password"
            value={contrasena}
          />
          <button className="boton boton-principal boton-acceso" type="submit">Ingresar</button>
          {hayError && <p className="error-acceso" role="alert">Error: correo o contraseña incorrectos</p>}
        </form>
        <div className="acceso-demostracion">Acceso de demostración: <strong>avil3scruz@gmail.com</strong> · <strong>sima2026</strong></div>
      </section>
      <div className="pie-acceso">SIMA <span>·</span> Sistema Integral de Mantenimiento Automotriz</div>
    </main>
  )
}