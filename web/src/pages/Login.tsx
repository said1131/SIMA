import { useState } from 'react';
import type { FormEvent } from 'react';
import { Logo } from '../components/Icons';

interface Props {
  onLogin: (name: string) => void;
}

const DEMO_EMAIL = 'taller@sima.mx';
const DEMO_PASS = 'sima1234';

export default function Login({ onLogin }: Props) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState(false);

  const submit = (e: FormEvent) => {
    e.preventDefault();
    if (email.trim().toLowerCase() === DEMO_EMAIL && password === DEMO_PASS) {
      setError(false);
      onLogin('Ing. Carlos Méndez');
    } else {
      setError(true);
    }
  };

  return (
    <div className="login">
      <section className="login-hero">
        <Logo />
        <h2>Controla tu taller desde un solo lugar</h2>
        <p>Administra citas, órdenes de trabajo y el catálogo de servicios que ven tus clientes en la app.</p>
        <div className="chips">
          <span className="chip">Citas</span>
          <span className="chip">Órdenes</span>
          <span className="chip">Catálogo</span>
        </div>
      </section>
      <section className="login-panel">
        <form className="login-card" onSubmit={submit}>
          <h2>Iniciar sesión</h2>
          <p className="sub">Acceso para el personal del taller</p>
          <div className="field">
            <label htmlFor="email">Correo electrónico</label>
            <input id="email" type="email" placeholder="tu@correo.com" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div className="field">
            <label htmlFor="pass">Contraseña</label>
            <input id="pass" type="password" placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} />
          </div>
          {error && <div className="error-box">Correo o contraseña incorrectos</div>}
          <button className="btn red block" type="submit">Iniciar sesión en SIMA →</button>
          <p className="hint">Demo: {DEMO_EMAIL} / {DEMO_PASS}</p>
        </form>
      </section>
    </div>
  );
}
