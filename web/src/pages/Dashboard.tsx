import { Layout } from '../components/Layout';
import type { ShellProps } from '../components/Layout';
import { Icon } from '../components/Icons';
import type { IconName } from '../components/Icons';
import type { Cita, Orden, Page } from '../types';

interface Props {
  shell: ShellProps;
  citas: Cita[];
  ordenes: Orden[];
  go: (p: Page) => void;
}

const ESTADOS: { label: string; color: string; match: (o: Orden) => boolean }[] = [
  { label: 'Recibida', color: '#e0a526', match: (o) => o.estado === 'Recibida' },
  { label: 'En diagnóstico', color: '#6a4fd1', match: (o) => o.estado === 'En diagnóstico' },
  { label: 'Cotizada', color: '#16217a', match: (o) => o.estado === 'Cotizada' },
  { label: 'Autorizada', color: '#2b6cb0', match: (o) => o.estado === 'Autorizada' },
  { label: 'En reparación', color: '#d8392b', match: (o) => o.estado === 'En reparación' },
  { label: 'Lista', color: '#2f9e57', match: (o) => o.estado === 'Lista' },
  { label: 'Entregada', color: '#6b7088', match: (o) => o.estado === 'Entregada' },
];

function getFechaLocal() {
  const ahora = new Date();
  const year = ahora.getFullYear();
  const month = String(ahora.getMonth() + 1).padStart(2, '0');
  const day = String(ahora.getDate()).padStart(2, '0');

  const iso = `${year}-${month}-${day}`; 
  const legible = ahora.toLocaleDateString('es-MX', {
    day: 'numeric',
    month: 'long',
  }); 

  return { iso, legible };
}

export default function Dashboard({ shell, citas, ordenes, go }: Props) {
  const { iso: hoyIso, legible: hoyLegible } = getFechaLocal();

  const porConfirmar = citas.filter((c) => c.estado === 'Solicitada').length;
  const hoy = citas.filter((c) => c.fecha === hoyIso && c.estado !== 'Rechazada');
  const enRep = ordenes.filter((o) => o.estado === 'En reparación').length;
  const listas = ordenes.filter((o) => o.estado === 'Lista').length;
  const counts = ESTADOS.map((e) => ({ ...e, n: ordenes.filter(e.match).length }));
  const total = counts.reduce((a, c) => a + c.n, 0) || 1;

  const stats: { icon: IconName; color: string; n: number; label: string }[] = [
    { icon: 'calendar', color: '#16217a', n: hoy.length, label: 'Citas de hoy' },
    { icon: 'clock', color: '#e0a526', n: porConfirmar, label: 'Por confirmar' },
    { icon: 'wrench', color: '#d8392b', n: enRep, label: 'En reparación' },
    { icon: 'check', color: '#2f9e57', n: listas, label: 'Listas para entregar' },
  ];

  return (
    <Layout
      shell={shell}
      active="dashboard"
      title="Panel de inicio"
      subtitle={`Resumen del día · ${hoyLegible}`}
    >
      <div className="banner">
        <div>
          <h2>
            {porConfirmar > 0
              ? `Tienes ${porConfirmar} cita${porConfirmar === 1 ? '' : 's'} por confirmar`
              : 'Todo al día: no hay citas por confirmar'}
          </h2>
          <p>Responde a tus clientes para llenar la agenda de hoy.</p>
        </div>
        {porConfirmar > 0 && (
          <button className="btn red" onClick={() => go({ name: 'citas' })}>Revisar citas</button>
        )}
      </div>

      <div className="stats">
        {stats.map((s) => (
          <div className="card stat" key={s.label}>
            <div className="ico" style={{ background: s.color }}><Icon name={s.icon} size={18} /></div>
            <div>
              <div className="num">{s.n}</div>
              <div className="lbl">{s.label}</div>
            </div>
          </div>
        ))}
      </div>

      <div className="two-col">
        <div className="card">
          <h3>Servicios por estado</h3>
          <div className="status-bar">
            {counts.map((c) => (
              <div key={c.label} style={{ width: `${(c.n / total) * 100}%`, background: c.color }} />
            ))}
          </div>
          {counts.map((c) => (
            <div className="legend-row" key={c.label}>
              <span className="sq" style={{ background: c.color }} />
              {c.label}
              <b>{c.n}</b>
            </div>
          ))}
        </div>

        <div className="card">
          <div className="card-head">
            <h3>Citas de hoy</h3>
            <button className="btn ghost sm" onClick={() => go({ name: 'citas' })}>Ver todas</button>
          </div>
          {hoy.length === 0 && <div className="empty">No hay citas para hoy</div>}
          {hoy
            .slice()
            .sort((a, b) => a.hora.localeCompare(b.hora))
            .map((c) => (
              <div className="mini-row" key={c.id}>
                <div className="vehicle-icon"><Icon name="car" /></div>
                <div className="info">
                  <div className="name">{c.cliente}</div>
                  <div className="sub">{c.vehiculo} · {c.servicio}</div>
                </div>
                <span className="time">{c.hora}</span>
                <span className={'tag ' + (c.estado === 'Confirmada' ? 'green' : 'amber')}>{c.estado}</span>
              </div>
            ))}
        </div>
      </div>
    </Layout>
  );
}