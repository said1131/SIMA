import { useCallback, useEffect, useRef, useState } from 'react';
import type { ShellProps } from './components/Layout';
import {
  CITAS_INICIALES,
  NOTIFICACIONES_INICIALES,
  ORDENES_INICIALES,
  SERVICIOS_INICIALES,
} from './data';
import type { Cita, Notificacion, Orden, Page, Servicio } from './types';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Citas from './pages/Citas';
import Ordenes from './pages/Ordenes';
import NuevaOrden from './pages/NuevaOrden';
import OrdenDetalle from './pages/OrdenDetalle';
import Catalogo from './pages/Catalogo';
import Notificaciones from './pages/Notificaciones';

export default function App() {
  const [user, setUser] = useState<string | null>(null);
  const [page, setPage] = useState<Page>({ name: 'dashboard' });
  const [citas, setCitas] = useState<Cita[]>(CITAS_INICIALES);
  const [ordenes, setOrdenes] = useState<Orden[]>(ORDENES_INICIALES);
  const [servicios, setServicios] = useState<Servicio[]>(SERVICIOS_INICIALES);
  const [notifs, setNotifs] = useState<Notificacion[]>(NOTIFICACIONES_INICIALES);
  const [toast, setToast] = useState<string | null>(null);
  const timer = useRef<number | undefined>(undefined);

  const showToast = useCallback((msg: string) => {
    setToast(msg);
    window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => setToast(null), 2800);
  }, []);
  useEffect(() => () => window.clearTimeout(timer.current), []);

  const go = useCallback((p: Page) => {
    setPage(p);
    window.scrollTo({ top: 0 });
  }, []);

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
      setUser(null);
      setToast(null);
    },
  };

  const confirmarCita = (id: string) => {
    setCitas((cs) => cs.map((c) => (c.id === id ? { ...c, estado: 'Confirmada' } : c)));
    showToast('Cita confirmada. Se avisó al cliente');
  };
  const rechazarCita = (id: string, _motivo: string) => {
    setCitas((cs) => cs.map((c) => (c.id === id ? { ...c, estado: 'Rechazada' } : c)));
    showToast('Cita rechazada. Se avisó al cliente');
  };

  const crearOrden = (o: Orden) => {
    setOrdenes((os) => [o, ...os]);
    showToast(`Orden ${o.id} creada`);
    go({ name: 'orden', id: o.id });
  };
  const actualizarOrden = (id: string, patch: Partial<Orden>, msg?: string) => {
    setOrdenes((os) => os.map((o) => (o.id === id ? { ...o, ...patch } : o)));
    if (msg) showToast(msg);
  };

  const guardarServicio = (s: Servicio) => {
    setServicios((ss) => (ss.some((x) => x.id === s.id) ? ss.map((x) => (x.id === s.id ? s : x)) : [...ss, s]));
    showToast('Catálogo actualizado');
  };

  const abrirNotif = (n: Notificacion) => {
    setNotifs((ns) => ns.map((x) => (x.id === n.id ? { ...x, leida: true } : x)));
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
            showToast('Todas marcadas como leídas');
          }}
        />
      );
  }
}
