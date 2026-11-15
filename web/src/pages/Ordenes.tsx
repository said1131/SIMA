import { useState } from 'react';
import { Layout } from '../components/Layout';
import type { ShellProps } from '../components/Layout';
import { Icon } from '../components/Icons';
import { AVANCE, ORDEN_ESTADOS } from '../data';
import type { Orden, OrdenEstado, Page } from '../types';

interface Props {
  shell: ShellProps;
  ordenes: Orden[];
  go: (p: Page) => void;
}

export function estadoTono(e: OrdenEstado): string {
  switch (e) {
    case 'Cotizada': return 'amber';
    case 'En diagnóstico': return 'blue';
    case 'Recibida': return 'blue';
    case 'Autorizada': return 'purple';
    case 'En reparación': return 'amber';
    case 'Lista': return 'green';
    default: return 'slate';
  }
}

export default function Ordenes({ shell, ordenes, go }: Props) {
  const [filtro, setFiltro] = useState<'Todas' | OrdenEstado>('Todas');
  const filtros: ('Todas' | OrdenEstado)[] = ['Todas', ...ORDEN_ESTADOS.filter((e) => e !== 'Entregada')];
  const count = (f: 'Todas' | OrdenEstado) => (f === 'Todas' ? ordenes.length : ordenes.filter((o) => o.estado === f).length);
  const lista = ordenes.filter((o) => filtro === 'Todas' || o.estado === filtro);

  return (
    <Layout
      shell={shell}
      active="ordenes"
      title="Órdenes de trabajo"
      subtitle="Seguimiento de cada vehículo hasta la entrega"
      actions={<button className="btn red" onClick={() => go({ name: 'nueva-orden' })}>+ Nueva orden</button>}
    >
      <div className="chips">
        {filtros.map((f) => (
          <button key={f} className={'chip' + (filtro === f ? ' active' : '')} onClick={() => setFiltro(f)}>
            {f} ({count(f)})
          </button>
        ))}
      </div>

      <div className="card">
        <table className="table">
          <thead>
            <tr>
              <th style={{ width: 50 }} />
              <th>Orden</th>
              <th>Cliente</th>
              <th>Vehículo y servicio</th>
              <th>Avance</th>
              <th>Estado</th>
              <th />
            </tr>
          </thead>
          <tbody>
            {lista.length === 0 && (
              <tr><td colSpan={7} className="empty">No hay órdenes en este estado</td></tr>
            )}
            {lista.map((o) => (
              <tr key={o.id}>
                <td><div className="vehicle-icon"><Icon name="car" /></div></td>
                <td className="order-id">{o.id}</td>
                <td>{o.cliente}</td>
                <td>
                  <div style={{ fontWeight: 600 }}>{o.vehiculo}</div>
                  <div className="sub">{o.servicio}</div>
                </td>
                <td><div className="progress"><span style={{ width: `${AVANCE[o.estado]}%` }} /></div></td>
                <td><span className={'tag ' + estadoTono(o.estado)}>{o.estado}</span></td>
                <td><button className="btn sm" onClick={() => go({ name: 'orden', id: o.id })}>Ver detalle</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Layout>
  );
}
