import { useState } from 'react';
import { Layout } from '../components/Layout';
import type { ShellProps } from '../components/Layout';
import { Icon } from '../components/Icons';
import type { IconName } from '../components/Icons';
import type { Notificacion, NotifTono, NotifTipo } from '../types';

interface Props {
  shell: ShellProps;
  notifs: Notificacion[];
  onOpen: (n: Notificacion) => void;
  onMarkAll: () => void;
}

type Filtro = 'Todas' | 'Sin leer' | 'Citas' | 'Órdenes' | 'Cotizaciones';
const FILTROS: Filtro[] = ['Todas', 'Sin leer', 'Citas', 'Órdenes', 'Cotizaciones'];
const TIPO_DE: Record<string, NotifTipo> = { Citas: 'cita', Órdenes: 'orden', Cotizaciones: 'cotizacion' };

const COLOR: Record<NotifTono, string> = { amber: '#e0a526', green: '#2f9e57', red: '#d8392b', slate: '#4a5170' };
const ICONO: Record<NotifTipo, IconName> = { cita: 'calendar', orden: 'clipboard', cotizacion: 'receipt' };

export default function Notificaciones({ shell, notifs, onOpen, onMarkAll }: Props) {
  const [filtro, setFiltro] = useState<Filtro>('Todas');

  const lista = notifs.filter((n) => {
    if (filtro === 'Todas') return true;
    if (filtro === 'Sin leer') return !n.leida;
    return n.tipo === TIPO_DE[filtro];
  });
  const count = (f: Filtro) =>
    f === 'Todas' ? notifs.length : f === 'Sin leer' ? notifs.filter((n) => !n.leida).length : null;

  return (
    <Layout
      shell={shell}
      active="notificaciones"
      title="Notificaciones"
      subtitle="Avisos de lo que hacen los clientes desde la app"
      actions={<button className="btn ghost" onClick={onMarkAll}>Marcar todas como leídas</button>}
    >
      <div className="chips">
        {FILTROS.map((f) => (
          <button key={f} className={'chip' + (filtro === f ? ' active' : '')} onClick={() => setFiltro(f)}>
            {f}{count(f) !== null ? ` (${count(f)})` : ''}
          </button>
        ))}
      </div>

      {lista.length === 0 && <div className="card empty">No hay notificaciones</div>}

      {lista.map((n) => (
        <div
          key={n.id}
          className="mini-row"
          style={{
            background: '#fff',
            border: '1px solid var(--line)',
            borderLeft: n.leida ? '1px solid var(--line)' : '4px solid var(--red)',
            padding: '12px 14px',
            marginBottom: 10,
          }}
        >
          <div className="vehicle-icon" style={{ background: COLOR[n.tono], borderRadius: '50%' }}>
            <Icon name={n.tono === 'green' ? 'check' : ICONO[n.tipo]} />
          </div>
          <div className="info">
            <div className="name">{n.titulo}</div>
            <div className="sub">{n.detalle}</div>
          </div>
          <span className="sub">{n.tiempo}</span>
          <button className={'btn sm ' + (n.accion.primaria ? 'red' : 'ghost')} onClick={() => onOpen(n)}>
            {n.accion.label}
          </button>
        </div>
      ))}
    </Layout>
  );
}
