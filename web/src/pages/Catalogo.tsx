import { useState } from 'react';
import { Layout } from '../components/Layout';
import type { ShellProps } from '../components/Layout';
import { Icon } from '../components/Icons';
import { fmtMoney } from '../data';
import type { Categoria, Servicio } from '../types';

interface Props {
  shell: ShellProps;
  servicios: Servicio[];
  onSave: (s: Servicio) => void;
}

const CATEGORIAS: Categoria[] = ['Preventivo', 'Frenos', 'Eléctrico', 'Suspensión', 'Motor'];

const VACIO: Servicio = {
  id: '',
  nombre: '',
  categoria: 'Preventivo',
  descripcion: '',
  precio: 0,
  duracion: 1,
  garantia: 1,
  activo: true,
};

export default function Catalogo({ shell, servicios, onSave }: Props) {
  const [filtro, setFiltro] = useState<'Todos' | Categoria>('Todos');
  const [editando, setEditando] = useState<Servicio | null>(null);
  const [error, setError] = useState('');

  const lista = servicios.filter((s) => filtro === 'Todos' || s.categoria === filtro);

  const guardar = () => {
    if (!editando) return;
    if (!editando.nombre.trim()) return setError('El nombre es obligatorio');
    if (!(editando.precio > 0)) return setError('El precio debe ser mayor a 0');
    setError('');
    onSave({ ...editando, id: editando.id || 's' + Date.now(), nombre: editando.nombre.trim() });
    setEditando(null);
  };

  const patch = (p: Partial<Servicio>) => editando && setEditando({ ...editando, ...p });

  return (
    <Layout
      shell={shell}
      active="catalogo"
      title="Catálogo de servicios"
      subtitle="Lo que ven tus clientes en la app"
      actions={<button className="btn red" onClick={() => { setEditando({ ...VACIO }); setError(''); }}>+ Nuevo servicio</button>}
    >
      <div className="chips">
        {(['Todos', ...CATEGORIAS] as const).map((f) => (
          <button key={f} className={'chip' + (filtro === f ? ' active' : '')} onClick={() => setFiltro(f)}>{f}</button>
        ))}
      </div>

      <div className="catalog-layout">
        <div className="catalog-grid">
          {lista.map((s) => (
            <div key={s.id} className={'svc-card' + (editando?.id === s.id ? ' selected' : '')} style={{ opacity: s.activo ? 1 : 0.6 }}>
              <div className="svc-head">
                <span className="tag">{s.categoria.toUpperCase()}</span>
                <Icon name="wrench" size={22} />
              </div>
              <div className="svc-body">
                <div className="svc-title">
                  {s.nombre}
                  <button
                    className={'toggle' + (s.activo ? ' on' : '')}
                    onClick={() => onSave({ ...s, activo: !s.activo })}
                    aria-label={s.activo ? 'Desactivar' : 'Activar'}
                    title={s.activo ? 'Visible en la app' : 'Oculto en la app'}
                  />
                </div>
                <p>{s.descripcion}</p>
                <p>{s.duracion} h · Garantía {s.garantia} {s.garantia === 1 ? 'mes' : 'meses'}</p>
                <div className="svc-price"><small>DESDE </small>{fmtMoney(s.precio)}</div>
                <button className="btn sm ghost" onClick={() => { setEditando({ ...s }); setError(''); }}>Editar</button>
              </div>
            </div>
          ))}
          {lista.length === 0 && <div className="card empty" style={{ gridColumn: '1 / -1' }}>No hay servicios en esta categoría</div>}
        </div>

        {editando && (
          <div className="card edit-panel">
            <h3>{editando.id ? 'Editar servicio' : 'Nuevo servicio'}</h3>
            <div className="field">
              <label>Nombre</label>
              <input value={editando.nombre} onChange={(e) => patch({ nombre: e.target.value })} />
            </div>
            <div className="field">
              <label>Categoría</label>
              <select value={editando.categoria} onChange={(e) => patch({ categoria: e.target.value as Categoria })}>
                {CATEGORIAS.map((c) => <option key={c}>{c}</option>)}
              </select>
            </div>
            <div className="field">
              <label>Descripción</label>
              <textarea value={editando.descripcion} onChange={(e) => patch({ descripcion: e.target.value })} />
            </div>
            <div className="row2">
              <div className="field"><label>Precio desde (MXN)</label><input type="number" min={0} value={editando.precio} onChange={(e) => patch({ precio: Number(e.target.value) })} /></div>
              <div className="field"><label>Duración (h)</label><input type="number" min={0} step="0.5" value={editando.duracion} onChange={(e) => patch({ duracion: Number(e.target.value) })} /></div>
            </div>
            <div className="field"><label>Garantía (meses)</label><input type="number" min={0} value={editando.garantia} onChange={(e) => patch({ garantia: Number(e.target.value) })} /></div>
            {error && <div className="error-box">{error}</div>}
            <div className="btn-row">
              <button className="btn red" onClick={guardar}>Guardar</button>
              <button className="btn ghost" onClick={() => setEditando(null)}>Cancelar</button>
            </div>
          </div>
        )}
      </div>
    </Layout>
  );
}
