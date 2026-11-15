import { useEffect, useMemo, useState } from 'react';
import { Layout } from '../components/Layout';
import type { ShellProps } from '../components/Layout';
import { CLIENTES, fmtFecha, fmtMoney } from '../data';
import type { Cita, Cliente, Orden, Page, Servicio } from '../types';

interface Props {
  shell: ShellProps;
  citaId?: string;
  citas: Cita[];
  ordenes: Orden[];
  servicios: Servicio[];
  clientes?: Cliente[];
  onCrear: (o: Orden) => void;
  go: (p: Page) => void;
}

export default function NuevaOrden({ shell, citaId, citas, ordenes, servicios, clientes, onCrear, go }: Props) {
  const listaClientes = clientes && clientes.length > 0 ? clientes : CLIENTES;
  const cita = citas.find((c) => c.id === citaId);
  const activos = servicios.filter((s) => s.activo);

  const clienteInicial =
    listaClientes.find((c) => (cita?.clienteId != null && c.id === String(cita.clienteId)) || c.nombre === cita?.cliente) ??
    listaClientes[0];
  const [clienteId, setClienteId] = useState(clienteInicial.id);
  const cliente = listaClientes.find((c) => c.id === clienteId) ?? listaClientes[0];
  const [placas, setPlacas] = useState(cita?.placas ?? cliente.vehiculos[0]?.placas ?? '');
  const [servicioId, setServicioId] = useState(
    (cita?.servicioId != null ? activos.find((s) => s.id === String(cita.servicioId))?.id : undefined) ??
      activos.find((s) => cita && s.nombre.toLowerCase().includes(cita.servicio.toLowerCase()))?.id ??
      activos[0]?.id ??
      ''
  );
  const [km, setKm] = useState(cita ? '45210' : '');
  const [notas, setNotas] = useState(cita ? 'El cliente reporta ruido metálico al frenar y vibración en el volante.' : '');
  const [intento, setIntento] = useState(false);

  useEffect(() => {
    if (!listaClientes.some((c) => c.id === clienteId)) {
      const next =
        listaClientes.find((c) => (cita?.clienteId != null && c.id === String(cita.clienteId)) || c.nombre === cita?.cliente) ??
        listaClientes[0];
      setClienteId(next.id);
      setPlacas(cita?.placas ?? next.vehiculos[0]?.placas ?? '');
    }
  }, [listaClientes, clienteId, cita]);

  useEffect(() => {
    if (!servicioId && activos.length > 0) {
      setServicioId(
        (cita?.servicioId != null ? activos.find((s) => s.id === String(cita.servicioId))?.id : undefined) ??
          activos.find((s) => cita && s.nombre.toLowerCase().includes(cita.servicio.toLowerCase()))?.id ??
          activos[0].id
      );
    }
  }, [activos, servicioId, cita]);

  const vehiculo = cliente.vehiculos.find((v) => v.placas === placas) ?? cliente.vehiculos[0] ?? { descripcion: '', placas: '' };
  const servicio = activos.find((s) => s.id === servicioId);
  const folio = useMemo(() => {
    const max = ordenes.reduce((m, o) => {
      const n = Number(o.id.replace('OT-', ''));
      return Number.isFinite(n) ? Math.max(m, n) : m;
    }, 1000);
    return `OT-${max + 1}`;
  }, [ordenes]);

  const cambiarCliente = (id: string) => {
    setClienteId(id);
    const c = listaClientes.find((x) => x.id === id) ?? listaClientes[0];
    setPlacas(c.vehiculos[0]?.placas ?? '');
  };

  const kmValido = km.trim() !== '' && Number(km) >= 0;

  const crear = () => {
    setIntento(true);
    if (!servicio || !kmValido) return;
    onCrear({
      id: folio,
      cliente: cliente.nombre,
      vehiculo: vehiculo.descripcion,
      placas: vehiculo.placas,
      servicio: servicio.nombre,
      estado: 'Recibida',
      diagnostico: '',
      conceptos: [],
      autorizacion: 'Pendiente',
      cotizacionEnviada: false,
      sinCuenta: cliente.sinCuenta,
      telefono: cliente.telefono,
      kilometraje: Number(km),
      notas,
      clienteId: Number(cliente.id) || cita?.clienteId,
      vehiculoId: vehiculo.id ?? cita?.vehiculoId,
      servicioId: Number(servicio.id) || cita?.servicioId,
      citaId: cita ? Number(cita.id) : undefined,
    });
  };

  return (
    <Layout
      shell={shell}
      active="ordenes"
      title="Nueva orden"
      subtitle="Registra la recepción del vehículo en el taller"
      actions={<span className="tag blue">Estado inicial: Recibida</span>}
    >
      <div className="order-layout">
        <div className="stack">
          <div className="card">
            <h3>Cliente y vehículo</h3>
            {cita && (
              <div className="from-cita">
                <div>
                  <b>Viene de una cita</b>
                  {fmtFecha(cita.fecha)} · {cita.hora} · {cita.servicio}
                </div>
                <span className="tag green">{cita.estado}</span>
              </div>
            )}
            <div className="row2">
              <div className="field">
                <label>Cliente</label>
                <select value={clienteId} onChange={(e) => cambiarCliente(e.target.value)}>
                  {listaClientes.map((c) => <option key={c.id} value={c.id}>{c.nombre}{c.sinCuenta ? ' (sin cuenta)' : ''}</option>)}
                </select>
              </div>
              <div className="field">
                <label>Vehículo</label>
                <select value={placas} onChange={(e) => setPlacas(e.target.value)}>
                  {cliente.vehiculos.map((v) => (
                    <option key={v.placas} value={v.placas}>{v.descripcion} · {v.placas}</option>
                  ))}
                </select>
              </div>
            </div>
          </div>

          <div className="card">
            <h3>Servicio y recepción</h3>
            <div className="row2">
              <div className="field">
                <label>Servicio solicitado</label>
                <select value={servicioId} onChange={(e) => setServicioId(e.target.value)}>
                  {activos.map((s) => <option key={s.id} value={s.id}>{s.nombre}</option>)}
                </select>
              </div>
              <div className="field">
                <label>Kilometraje actual</label>
                <input
                  type="number"
                  min={0}
                  placeholder="45210"
                  value={km}
                  onChange={(e) => setKm(e.target.value)}
                  style={intento && !kmValido ? { borderColor: '#d8392b' } : undefined}
                />
              </div>
            </div>
            <div className="field">
              <label>Notas de recepción</label>
              <textarea value={notas} onChange={(e) => setNotas(e.target.value)} placeholder="¿Qué reporta el cliente?" />
            </div>
            <div className="btn-row" style={{ justifyContent: 'flex-start' }}>
              <button className="btn red" style={{ flex: 'none' }} onClick={crear}>Crear orden</button>
              <button className="btn ghost" style={{ flex: 'none' }} onClick={() => go({ name: citaId ? 'citas' : 'ordenes' })}>Cancelar</button>
            </div>
            {intento && !kmValido && <p className="hint" style={{ color: '#d8392b' }}>Captura el kilometraje del vehículo.</p>}
          </div>
        </div>

        <div>
          <div className="summary">
            <div className="title">RESUMEN DE LA ORDEN</div>
            <dl>
              <div className="item"><dt>Folio</dt><dd>{folio}</dd></div>
              <div className="item"><dt>Cliente</dt><dd>{cliente.nombre}</dd></div>
              <div className="item"><dt>Vehículo</dt><dd>{vehiculo.descripcion} · {vehiculo.placas}</dd></div>
              <div className="item"><dt>Servicio</dt><dd>{servicio?.nombre ?? '—'}</dd></div>
              <div className="item"><dt>Precio estimado desde</dt><dd>{servicio ? fmtMoney(servicio.precio) : '—'}</dd></div>
            </dl>
          </div>
          <div className="notice">
            <b>Notificación automática</b>
            Al crear la orden, el cliente recibe un aviso en su app y puede seguir el avance.
          </div>
        </div>
      </div>
    </Layout>
  );
}
