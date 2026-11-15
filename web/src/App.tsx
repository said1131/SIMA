import { useCallback, useEffect, useRef, useState } from 'react';
import type { ShellProps } from './components/Layout';
import {
  actualizarServicioApi,
  agregarConceptoApi,
  autorizarOrdenApi,
  cambiarEstadoOrdenApi,
  clearSession,
  confirmarCitaApi,
  crearOrdenApi,
  crearServicioApi,
  eliminarConceptoApi,
  enviarCotizacionApi,
  fetchCitas,
  fetchClientes,
  fetchMe,
  fetchNotificaciones,
  fetchOrdenDetalle,
  fetchOrdenes,
  fetchServicios,
  getSavedUser,
  getToken,
  guardarDiagnosticoApi,
  marcarNotifLeidaApi,
  marcarTodasNotifsLeidasApi,
  rechazarCitaApi,
  toggleServicioActivoApi,
} from './api';
import type { Cita, Cliente, Notificacion, Orden, Page, Servicio } from './types';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Citas from './pages/Citas';
import Ordenes from './pages/Ordenes';
import NuevaOrden from './pages/NuevaOrden';
import OrdenDetalle from './pages/OrdenDetalle';
import Catalogo from './pages/Catalogo';
import Notificaciones from './pages/Notificaciones';

export default function App() {
  const [user, setUser] = useState<string | null>(() => (getToken() ? getSavedUser() || 'Personal SIMA' : null));
  const [page, setPage] = useState<Page>({ name: 'dashboard' });
  const [citas, setCitas] = useState<Cita[]>([]);
  const [ordenes, setOrdenes] = useState<Orden[]>([]);
  const [servicios, setServicios] = useState<Servicio[]>([]);
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [notifs, setNotifs] = useState<Notificacion[]>([]);
  const [toast, setToast] = useState<string | null>(null);
  const timer = useRef<number | undefined>(undefined);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setToast(null), 3200);
  }, []);
  useEffect(() => () => window.clearTimeout(timer.current), []);

  const go = useCallback((p: Page) => {
    setPage(p);
    window.scrollTo({ top: 0 });
  }, []);

  const cargarTodo = useCallback(async () => {
    if (!getToken()) return;
    try {
      const [citasRes, ordenesRes, serviciosRes, clientesRes] = await Promise.all([
        fetchCitas(),
        fetchOrdenes(),
        fetchServicios(),
        fetchClientes(),
      ]);
      setCitas(citasRes);
      setOrdenes(ordenesRes);
      setServicios(serviciosRes);
      setClientes(clientesRes);
      const notifsRes = await fetchNotificaciones(ordenesRes);
      setNotifs(notifsRes);
    } catch (err) {
      if (!getToken()) {
        setUser(null);
      } else {
        showToast(err instanceof Error ? err.message : 'Error al sincronizar con el servidor');
      }
    }
  }, [showToast]);

  useEffect(() => {
    if (!user) return;
    fetchMe()
      .then((nombre) => setUser(nombre))
      .catch(() => {
        clearSession();
        setUser(null);
      });
    cargarTodo();
  }, [user, cargarTodo]);

  if (!user) {
    return (
      <Login
        onLogin={(name) => {
          setUser(name);
          go({ name: 'dashboard' });
        }}
      />
    );
  }

  const shell: ShellProps = {
    unread: notifs.filter((n) => !n.leida).length,
    toast,
    userName: user,
    onNavigate: go,
    onLogout: () => {
      clearSession();
      setUser(null);
      setToast(null);
    },
  };

  const confirmarCita = async (id: string) => {
    try {
      const actualizada = await confirmarCitaApi(id);
      setCitas((cs) => cs.map((c) => (c.id === id ? actualizada : c)));
      showToast('Cita confirmada. Se avisó al cliente');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'No se pudo confirmar la cita');
    }
  };

  const rechazarCita = async (id: string, motivo: string) => {
    try {
      const actualizada = await rechazarCitaApi(id, motivo);
      setCitas((cs) => cs.map((c) => (c.id === id ? actualizada : c)));
      showToast('Cita rechazada. Se avisó al cliente');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'No se pudo rechazar la cita');
    }
  };

  const crearOrden = async (o: Orden) => {
    try {
      const clienteMatch = clientes.find((c) => (o.clienteId != null && c.id === String(o.clienteId)) || c.nombre === o.cliente);
      const vehiculoMatch = clienteMatch?.vehiculos.find((v) => v.placas === o.placas) ?? clienteMatch?.vehiculos[0];
      const servicioMatch = servicios.find((s) => (o.servicioId != null && s.id === String(o.servicioId)) || s.nombre === o.servicio);

      const clienteId = o.clienteId ?? (clienteMatch ? Number(clienteMatch.id) : undefined);
      const vehiculoId = o.vehiculoId ?? vehiculoMatch?.id;
      const servicioId = o.servicioId ?? (servicioMatch ? Number(servicioMatch.id) : undefined);

      if (!clienteId || !vehiculoId || !servicioId) {
        showToast('Selecciona un cliente, vehículo y servicio registrados en la base de datos.');
        return;
      }

      const creada = await crearOrdenApi({
        clienteId,
        vehiculoId,
        servicioId,
        kilometraje: o.kilometraje ?? 0,
        notas: o.notas,
        citaId: o.citaId,
      });

      const detalle = creada.dbId != null ? await fetchOrdenDetalle(creada.dbId).catch(() => creada) : creada;
      setOrdenes((os) => [detalle, ...os]);
      showToast(`Orden ${detalle.id} creada`);
      go({ name: 'orden', id: detalle.id });
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'No se pudo crear la orden');
    }
  };

  const actualizarOrden = async (id: string, patch: Partial<Orden>, msg?: string) => {
    const actual = ordenes.find((o) => o.id === id);
    if (!actual || actual.dbId == null) return;
    const dbId = actual.dbId;

    try {
      let updated: Orden | null = null;

      if (patch.conceptos) {
        if (patch.conceptos.length > actual.conceptos.length) {
          const nuevo = patch.conceptos[patch.conceptos.length - 1];
          updated = await agregarConceptoApi(dbId, {
            concepto: nuevo.concepto,
            tipo: nuevo.tipo,
            cantidad: nuevo.cantidad,
            precio: nuevo.precio,
          });
        } else if (patch.conceptos.length < actual.conceptos.length) {
          const eliminado = actual.conceptos.find((old) => !patch.conceptos!.some((n) => n.id === old.id));
          if (eliminado) {
            updated = await eliminarConceptoApi(dbId, eliminado.id);
          }
        }
      } else if ('diagnostico' in patch) {
        updated = await guardarDiagnosticoApi(dbId, patch.diagnostico ?? '');
        if (patch.estado && updated.estado !== patch.estado) {
          updated = await cambiarEstadoOrdenApi(dbId, patch.estado);
        }
      } else if (patch.autorizacion === 'Autorizada' || patch.autorizacion === 'Rechazada') {
        if (!actual.cotizacionEnviada) {
          await enviarCotizacionApi(dbId);
        }
        updated = await autorizarOrdenApi(dbId, patch.autorizacion);
      } else if (patch.cotizacionEnviada === true) {
        updated = await enviarCotizacionApi(dbId);
      } else if (patch.estado) {
        updated = await cambiarEstadoOrdenApi(dbId, patch.estado);
      }

      const refrescada = await fetchOrdenDetalle(dbId).catch(() => updated ?? { ...actual, ...patch });
      setOrdenes((os) => os.map((o) => (o.id === id ? refrescada : o)));
      if (msg) showToast(msg);
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'No se pudo actualizar la orden');
    }
  };

  const guardarServicio = async (s: Servicio) => {
    try {
      const existente = servicios.find((x) => x.id === s.id);
      let guardado: Servicio;
      if (existente && existente.activo !== s.activo && existente.nombre === s.nombre && existente.precio === s.precio) {
        guardado = await toggleServicioActivoApi(s.id, s.activo);
      } else if (existente) {
        guardado = await actualizarServicioApi(s);
      } else {
        guardado = await crearServicioApi({
          nombre: s.nombre,
          categoria: s.categoria,
          descripcion: s.descripcion,
          precio: s.precio,
          duracion: s.duracion,
          garantia: s.garantia,
        });
      }
      setServicios((ss) => (ss.some((x) => x.id === guardado.id) ? ss.map((x) => (x.id === guardado.id ? guardado : x)) : [...ss, guardado]));
      showToast('Catálogo actualizado');
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'No se pudo guardar el servicio');
    }
  };

  const abrirNotif = async (n: Notificacion) => {
    setNotifs((ns) => ns.map((x) => (x.id === n.id ? { ...x, leida: true } : x)));
    marcarNotifLeidaApi(n.id).catch(() => {});
    go(n.accion.destino);
  };

  switch (page.name) {
    case 'dashboard':
      return <Dashboard shell={shell} citas={citas} ordenes={ordenes} go={go} />;
    case 'citas':
      return <Citas shell={shell} citas={citas} onConfirmar={confirmarCita} onRechazar={rechazarCita} go={go} />;
    case 'ordenes':
      return <Ordenes shell={shell} ordenes={ordenes} go={go} />;
    case 'nueva-orden':
      return (
        <NuevaOrden
          key={page.citaId ?? 'nueva'}
          shell={shell}
          citaId={page.citaId}
          citas={citas}
          ordenes={ordenes}
          servicios={servicios}
          clientes={clientes}
          onCrear={crearOrden}
          go={go}
        />
      );
    case 'orden': {
      const orden = ordenes.find((o) => o.id === page.id);
      if (!orden) return <Ordenes shell={shell} ordenes={ordenes} go={go} />;
      return <OrdenDetalle key={orden.id} shell={shell} orden={orden} onUpdate={actualizarOrden} go={go} />;
    }
    case 'catalogo':
      return <Catalogo shell={shell} servicios={servicios} onSave={guardarServicio} />;
    case 'notificaciones':
      return (
        <Notificaciones
          shell={shell}
          notifs={notifs}
          onOpen={abrirNotif}
          onMarkAll={() => {
            setNotifs((ns) => ns.map((n) => ({ ...n, leida: true })));
            marcarTodasNotifsLeidasApi().catch(() => {});
            showToast('Todas marcadas como leídas');
          }}
        />
      );
  }
}
