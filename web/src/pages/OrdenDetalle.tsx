import { useState } from 'react';
import { Layout } from '../components/Layout';
import type { ShellProps } from '../components/Layout';
import { Icon } from '../components/Icons';
import { fmtMoney, ORDEN_ESTADOS } from '../data';
import { estadoTono } from './Ordenes';
import type { Concepto, Orden, OrdenEstado, Page, TipoConcepto } from '../types';

interface Props {
  shell: ShellProps;
  orden: Orden;
  onUpdate: (id: string, patch: Partial<Orden>, toast?: string) => void;
  go: (p: Page) => void;
}

const IVA = 0.16;
const TIPOS: TipoConcepto[] = ['Refacción', 'Tornería', 'Labor'];
const TIPO_TAG: Record<TipoConcepto, string> = { Refacción: 'blue', Tornería: 'purple', Labor: 'amber' };

export default function OrdenDetalle({ shell, orden, onUpdate, go }: Props) {
  const [diag, setDiag] = useState(orden.diagnostico);
  const [nuevoEstado, setNuevoEstado] = useState<OrdenEstado>(orden.estado);
  const [agregando, setAgregando] = useState(false);
  const [c, setC] = useState({ concepto: '', tipo: 'Refacción' as TipoConcepto, cantidad: '1', precio: '' });

  const idx = ORDEN_ESTADOS.indexOf(orden.estado);
  const total = orden.conceptos.reduce((s, x) => s + x.cantidad * x.precio, 0);
  const subtotal = total / (1 + IVA);
  const iva = total - subtotal;

  const requiereAut = ORDEN_ESTADOS.indexOf(nuevoEstado) >= ORDEN_ESTADOS.indexOf('Autorizada');
  const bloqueado = requiereAut && orden.autorizacion !== 'Autorizada';
  const sinCambio = nuevoEstado === orden.estado;

  const setConceptos = (conceptos: Concepto[]) => onUpdate(orden.id, { conceptos });

  const agregar = () => {
    const cant = Number(c.cantidad);
    const precio = Number(c.precio);
    if (!c.concepto.trim() || !(cant > 0) || !(precio >= 0) || c.precio === '') return;
    setConceptos([...orden.conceptos, { id: 'k' + Date.now(), concepto: c.concepto.trim(), tipo: c.tipo, cantidad: cant, precio }]);
    setC({ concepto: '', tipo: 'Refacción', cantidad: '1', precio: '' });
    setAgregando(false);
  };

  const guardarDiag = () => onUpdate(orden.id, { diagnostico: diag, estado: orden.estado === 'Recibida' && diag.trim() ? 'En diagnóstico' : orden.estado }, 'Diagnóstico guardado');

  const autorizacionClase = orden.autorizacion === 'Autorizada' ? 'green' : orden.autorizacion === 'Rechazada' ? 'red' : '';

  return (
    <Layout shell={shell} active="ordenes" title="Detalle de orden" subtitle={`Seguimiento de ${orden.id}`}>
      <div className="order-banner">
        <div className="vehicle-icon"><Icon name="car" size={22} /></div>
        <div>
          <h2>Orden {orden.id} · {orden.vehiculo}</h2>
          <p>
            Placas {orden.placas} · {orden.sinCuenta ? `${orden.cliente}${orden.telefono ? ' · Tel. ' + orden.telefono : ''}` : `Cliente: ${orden.cliente}`} · {orden.servicio}
          </p>
          {orden.sinCuenta && <span className="sin-cuenta-tag">CLIENTE SIN CUENTA · CITA EXPRÉS</span>}
        </div>
        <div className="right">
          <span className={'tag ' + estadoTono(orden.estado)}>
            {orden.estado}{orden.estado === 'Cotizada' && orden.autorizacion === 'Pendiente' ? ' · esperando autorización' : ''}
          </span>
          <button className="btn sm ghost" onClick={() => go({ name: 'ordenes' })}>← Regresar a órdenes</button>
        </div>
      </div>

      <div className="card">
        <h3>Estado de la orden</h3>
        <div className="stepper">
          {ORDEN_ESTADOS.map((e, i) => (
            <div key={e} className={'step' + (i < idx ? ' done' : i === idx ? ' current' : '')}>
              <div className="dot" />
              {e}
            </div>
          ))}
        </div>
      </div>

      <div className="detail-grid">
        <div className="stack">
          <div className="card">
            <h3>Diagnóstico del mecánico</h3>
            <div className="field">
              <textarea value={diag} onChange={(e) => setDiag(e.target.value)} placeholder="Describe el diagnóstico…" style={{ minHeight: 90 }} />
            </div>
            <button className="btn sm ghost" onClick={guardarDiag}>Guardar diagnóstico</button>
          </div>

          <div className="card">
            <h3>Cambiar estado</h3>
            <div className="field">
              <label>Nuevo estado</label>
              <select value={nuevoEstado} onChange={(e) => setNuevoEstado(e.target.value as OrdenEstado)}>
                {ORDEN_ESTADOS.map((e) => <option key={e}>{e}</option>)}
              </select>
            </div>
            <button
              className="btn sm"
              disabled={bloqueado || sinCambio}
              onClick={() => onUpdate(orden.id, { estado: nuevoEstado }, `Estado actualizado: ${nuevoEstado}`)}
            >
              Actualizar estado
            </button>
            {bloqueado && (
              <p className="hint">No se puede pasar a «En reparación» sin la autorización del cliente.</p>
            )}
          </div>
        </div>

        <div className="card">
          <div className="card-head">
            <h3>Cotización</h3>
            <button className="btn sm ghost" onClick={() => setAgregando((v) => !v)}>+ Agregar concepto</button>
          </div>

          {agregando && (
            <div className="add-concept">
              <div><label className="sub">Concepto</label><input value={c.concepto} onChange={(e) => setC({ ...c, concepto: e.target.value })} /></div>
              <div>
                <label className="sub">Tipo</label>
                <select value={c.tipo} onChange={(e) => setC({ ...c, tipo: e.target.value as TipoConcepto })}>
                  {TIPOS.map((t) => <option key={t}>{t}</option>)}
                </select>
              </div>
              <div><label className="sub">Cant.</label><input type="number" min={0} step="0.5" value={c.cantidad} onChange={(e) => setC({ ...c, cantidad: e.target.value })} /></div>
              <div><label className="sub">Precio</label><input type="number" min={0} value={c.precio} onChange={(e) => setC({ ...c, precio: e.target.value })} /></div>
              <button className="btn sm red" onClick={agregar}>Agregar</button>
              <button className="btn sm ghost" onClick={() => setAgregando(false)}>✕</button>
            </div>
          )}

          <table className="table quote-table">
            <thead>
              <tr><th>Concepto</th><th>Tipo</th><th className="num">Cant.</th><th className="num">Precio</th><th className="num">Subtotal</th><th /></tr>
            </thead>
            <tbody>
              {orden.conceptos.length === 0 && <tr><td colSpan={6} className="empty">Aún no hay conceptos en la cotización</td></tr>}
              {orden.conceptos.map((x) => (
                <tr key={x.id}>
                  <td>{x.concepto}</td>
                  <td><span className={'tag ' + TIPO_TAG[x.tipo]}>{x.tipo.toUpperCase()}</span></td>
                  <td className="num">{x.cantidad}{x.tipo === 'Labor' ? ' h' : ''}</td>
                  <td className="num">{fmtMoney(x.precio)}</td>
                  <td className="num">{fmtMoney(x.cantidad * x.precio)}</td>
                  <td>
                    {!orden.cotizacionEnviada && (
                      <button className="link-btn" title="Quitar" onClick={() => setConceptos(orden.conceptos.filter((y) => y.id !== x.id))}>×</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="totals">
            <div><span>Subtotal</span><span>{fmtMoney(subtotal)}</span></div>
            <div><span>IVA 16%</span><span>{fmtMoney(iva)}</span></div>
          </div>
          <div className="quote-total">
            <small>TOTAL COTIZADO (IVA INCLUIDO)</small>
            <div className="amount">{fmtMoney(total)}</div>
            <small>MXN</small>
          </div>

          <div className={'auth-box ' + autorizacionClase}>
            <div>
              <b>Autorización del cliente</b>
              <small>
                {orden.sinCuenta
                  ? 'Cliente sin cuenta: confirmado por teléfono'
                  : 'El cliente la autoriza desde la app móvil'}
              </small>
            </div>
            <span className="state">{orden.autorizacion}</span>
          </div>

          {orden.sinCuenta ? (
            <>
              <div className="btn-row">
                <button
                  className="btn"
                  disabled={orden.autorizacion !== 'Pendiente' || total === 0}
                  onClick={() => onUpdate(orden.id, { autorizacion: 'Autorizada', cotizacionEnviada: true, estado: 'Autorizada' }, 'Autorización telefónica registrada')}
                >
                  Registrar autorización telefónica
                </button>
                <button
                  className="btn ghost"
                  disabled={orden.autorizacion !== 'Pendiente'}
                  onClick={() => onUpdate(orden.id, { autorizacion: 'Rechazada', cotizacionEnviada: true }, 'Rechazo registrado')}
                >
                  Registrar rechazo
                </button>
              </div>
              <p className="hint">Este cliente no tiene cuenta, así que no recibe avisos en la app. Contáctalo al {orden.telefono}.</p>
            </>
          ) : (
            <>
              <button
                className="btn red block"
                disabled={orden.cotizacionEnviada || total === 0}
                onClick={() => onUpdate(orden.id, { cotizacionEnviada: true, estado: 'Cotizada' }, 'Cotización enviada al cliente')}
              >
                {orden.cotizacionEnviada ? 'Cotización enviada ✓' : 'Enviar cotización al cliente'}
              </button>
              {orden.cotizacionEnviada && orden.autorizacion === 'Pendiente' && (
                <div className="btn-row" style={{ marginTop: 8 }}>
                  <button className="btn sm ghost" onClick={() => onUpdate(orden.id, { autorizacion: 'Autorizada', estado: 'Autorizada' }, 'El cliente autorizó (simulación)')}>
                    Simular autorización
                  </button>
                  <button className="btn sm ghost" onClick={() => onUpdate(orden.id, { autorizacion: 'Rechazada' }, 'El cliente rechazó (simulación)')}>
                    Simular rechazo
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </Layout>
  );
}
