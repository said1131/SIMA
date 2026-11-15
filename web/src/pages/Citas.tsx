import { useState } from 'react';
import { Layout } from '../components/Layout';
import type { ShellProps } from '../components/Layout';
import { Icon } from '../components/Icons';
import { diasDesdeHoy, fmtFecha } from '../data';
import type { Cita, CitaEstado, Page } from '../types';

interface Props {
  shell: ShellProps;
  citas: Cita[];
  onConfirmar: (id: string) => void;
  onRechazar: (id: string, motivo: string) => void;
  go: (p: Page) => void;
}

const MOTIVOS = [
  'No hay disponibilidad en ese horario',
  'Servicio no disponible en el taller',
  'Falta de refacciones',
  'Otro',
];

function cuando(c: Cita): string {
  const d = diasDesdeHoy(c.fecha);
  const dia = d === 0 ? 'Hoy' : d === 1 ? 'Mañana' : fmtFecha(c.fecha);
  return `${dia} · ${c.hora}`;
}

export default function Citas({ shell, citas, onConfirmar, onRechazar, go }: Props) {
  const [filtro, setFiltro] = useState<'Todas' | CitaEstado>('Todas');
  const [rechazando, setRechazando] = useState<Cita | null>(null);
  const [motivo, setMotivo] = useState(MOTIVOS[0]);
  const [detalle, setDetalle] = useState('');

  const filtros: ('Todas' | CitaEstado)[] = ['Todas', 'Solicitada', 'Confirmada', 'Rechazada'];
  const count = (f: 'Todas' | CitaEstado) => (f === 'Todas' ? citas.length : citas.filter((c) => c.estado === f).length);
  const lista = citas
    .filter((c) => filtro === 'Todas' || c.estado === filtro)
    .slice()
    .sort((a, b) => (a.fecha + a.hora).localeCompare(b.fecha + b.hora));

  const abrir = (c: Cita) => {
    setRechazando(c);
    setMotivo(MOTIVOS[0]);
    setDetalle('');
  };
  const cerrar = () => setRechazando(null);
  const enviar = () => {
    if (!rechazando) return;
    onRechazar(rechazando.id, motivo === 'Otro' && detalle.trim() ? detalle.trim() : motivo);
    cerrar();
  };

  return (
    <Layout shell={shell} active="citas" title="Citas" subtitle="Solicitudes de los clientes y agenda del taller">
      <div className="chips">
        {filtros.map((f) => (
          <button key={f} className={'chip' + (filtro === f ? ' active' : '')} onClick={() => setFiltro(f)}>
            {f === 'Todas' ? 'Todas' : f + 's'} ({count(f)})
          </button>
        ))}
      </div>

      {lista.length === 0 && <div className="card empty">No hay citas en esta categoría</div>}

      {lista.map((c) => (
        <div className="cita-row" key={c.id}>
          <div className="who">
            <div className="vehicle-icon"><Icon name="car" /></div>
            <div>
              <div>
                {c.expres && <span className="tag amber" style={{ marginRight: 6 }}>CITA EXPRÉS</span>}
                <span className="service-tag">{c.servicio}</span>
              </div>
              <div className="name">
                {c.cliente}
                {c.expres && <span className="sub"> · sin cuenta{c.telefono ? ` · ${c.telefono}` : ''}</span>}
              </div>
              <div className="sub">{c.vehiculo} · {c.placas}</div>
            </div>
          </div>
          <div>
            <div style={{ fontWeight: 700 }}>{cuando(c)}</div>
            <div className="sub">{fmtFecha(c.fecha)}</div>
          </div>
          <div>
            <span className={'tag ' + (c.estado === 'Confirmada' ? 'green' : c.estado === 'Rechazada' ? 'red' : 'amber')}>
              {c.estado}
            </span>
          </div>
          <div className="cita-actions">
            {c.estado === 'Solicitada' && (
              <>
                <button className="btn sm red" onClick={() => onConfirmar(c.id)}>Confirmar</button>
                <button className="btn sm ghost" onClick={() => abrir(c)}>Rechazar</button>
              </>
            )}
            {c.estado === 'Confirmada' && (
              <button className="btn sm" onClick={() => go({ name: 'nueva-orden', citaId: c.id })}>Crear orden</button>
            )}
          </div>
        </div>
      ))}

      {rechazando && (
        <div className="overlay" onClick={cerrar}>
          <div className="modal" onClick={(e) => e.stopPropagation()} role="dialog" aria-modal="true">
            <h3>Rechazar cita</h3>
            <p className="sub">
              {rechazando.cliente} · {rechazando.servicio} · {cuando(rechazando)}. El cliente recibirá un aviso con el motivo.
            </p>
            <div className="field">
              <label>Motivo</label>
              <select value={motivo} onChange={(e) => setMotivo(e.target.value)}>
                {MOTIVOS.map((m) => <option key={m}>{m}</option>)}
              </select>
            </div>
            {motivo === 'Otro' && (
              <div className="field">
                <label>Detalle</label>
                <textarea value={detalle} onChange={(e) => setDetalle(e.target.value)} placeholder="Escribe el motivo…" />
              </div>
            )}
            <div className="modal-actions">
              <button className="btn ghost" onClick={cerrar}>Cancelar</button>
              <button className="btn red" onClick={enviar}>Rechazar cita</button>
            </div>
          </div>
        </div>
      )}
    </Layout>
  );
}
