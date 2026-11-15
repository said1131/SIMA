import type { Cita, Cliente, Concepto, Notificacion, Orden, OrdenEstado, Servicio } from './types';

const API_URL = (import.meta.env.VITE_API_URL as string | undefined) || 'http://localhost:3000/api/v1';
const TOKEN_KEY = 'sima_staff_token';
const USER_KEY = 'sima_staff_user';

export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function getSavedUser(): string | null {
  return localStorage.getItem(USER_KEY);
}

export function saveSession(token: string, userName: string): void {
  localStorage.setItem(TOKEN_KEY, token);
  localStorage.setItem(USER_KEY, userName);
}

export function clearSession(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(init.headers as Record<string, string> | undefined),
  };
  if (token) {
    headers.Authorization = `Bearer ${token}`;
  }

  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, { ...init, headers });
  } catch {
    throw new Error('No se pudo conectar con el servidor SIMA (puerto 3000).');
  }

  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    if (res.status === 401) {
      clearSession();
    }
    const errObj = body?.error;
    const detail = Array.isArray(errObj?.details) && errObj.details[0]?.mensaje
      ? `: ${errObj.details[0].mensaje}`
      : '';
    throw new Error((errObj?.message || `Error HTTP ${res.status}`) + detail);
  }

  return (body?.data !== undefined ? body.data : body) as T;
}

function mapCita(raw: Record<string, unknown>): Cita {
  return {
    id: String(raw.id ?? ''),
    cliente: String(raw.cliente ?? ''),
    vehiculo: String(raw.vehiculo ?? ''),
    placas: String(raw.placas ?? ''),
    servicio: String(raw.servicio ?? ''),
    fecha: String(raw.fecha ?? '').slice(0, 10),
    hora: String(raw.hora ?? '').slice(0, 5),
    estado: (raw.estado as Cita['estado']) || 'Solicitada',
    expres: Boolean(raw.expres ?? raw.sinCuenta),
    telefono: raw.telefono ? String(raw.telefono) : undefined,
    clienteId: raw.clienteId != null ? Number(raw.clienteId) : undefined,
    vehiculoId: raw.vehiculoId != null ? Number(raw.vehiculoId) : undefined,
    servicioId: raw.servicioId != null ? Number(raw.servicioId) : undefined,
  };
}

function mapConcepto(raw: Record<string, unknown>): Concepto {
  return {
    id: String(raw.id ?? ''),
    concepto: String(raw.concepto ?? ''),
    tipo: (raw.tipo as Concepto['tipo']) || 'Refacción',
    cantidad: Number(raw.cantidad ?? 1),
    precio: Number(raw.precio ?? 0),
  };
}

function mapOrden(raw: Record<string, unknown>): Orden {
  const conceptosRaw = Array.isArray(raw.conceptos) ? raw.conceptos : [];
  const dbId = raw.id != null ? Number(raw.id) : undefined;
  const folio = raw.folio ? String(raw.folio) : dbId != null ? `OT-${dbId}` : '';
  return {
    id: folio,
    dbId,
    cliente: String(raw.cliente ?? ''),
    vehiculo: String(raw.vehiculo ?? ''),
    placas: String(raw.placas ?? ''),
    servicio: String(raw.servicio ?? ''),
    estado: (raw.estado as OrdenEstado) || 'Recibida',
    diagnostico: String(raw.diagnostico ?? ''),
    conceptos: conceptosRaw.map((c) => mapConcepto(c as Record<string, unknown>)),
    autorizacion: (raw.autorizacion as Orden['autorizacion']) || 'Pendiente',
    cotizacionEnviada: Boolean(raw.cotizacionEnviada),
    sinCuenta: Boolean(raw.sinCuenta),
    telefono: raw.telefono ? String(raw.telefono) : undefined,
    kilometraje: raw.kilometraje != null ? Number(raw.kilometraje) : undefined,
    notas: raw.notas ? String(raw.notas) : undefined,
    clienteId: raw.clienteId != null ? Number(raw.clienteId) : undefined,
    vehiculoId: raw.vehiculoId != null ? Number(raw.vehiculoId) : undefined,
    servicioId: raw.servicioId != null ? Number(raw.servicioId) : undefined,
    citaId: raw.citaId != null ? Number(raw.citaId) : undefined,
  };
}

function mapServicio(raw: Record<string, unknown>): Servicio {
  return {
    id: String(raw.id ?? ''),
    nombre: String(raw.nombre ?? ''),
    categoria: (raw.categoria as Servicio['categoria']) || 'Preventivo',
    descripcion: String(raw.descripcion ?? ''),
    precio: Number(raw.precio ?? 0),
    duracion: Number(raw.duracion ?? 1),
    garantia: Number(raw.garantia ?? 1),
    activo: raw.activo !== false,
  };
}

function mapCliente(raw: Record<string, unknown>): Cliente {
  const vehs = Array.isArray(raw.vehiculos) ? raw.vehiculos : [];
  return {
    id: String(raw.id ?? ''),
    nombre: String(raw.nombre ?? ''),
    sinCuenta: Boolean(raw.sinCuenta),
    telefono: raw.telefono ? String(raw.telefono) : undefined,
    vehiculos: vehs.map((v) => {
      const item = v as Record<string, unknown>;
      return {
        id: item.id != null ? Number(item.id) : undefined,
        descripcion: String(item.descripcion ?? `${item.marca ?? ''} ${item.modelo ?? ''} ${item.anio ?? ''}`.trim()),
        placas: String(item.placas ?? ''),
      };
    }),
  };
}

function formatTiempo(fechaIso: string): string {
  if (!fechaIso) return 'reciente';
  const ts = Date.parse(fechaIso);
  if (Number.isNaN(ts)) return fechaIso;
  const mins = Math.max(1, Math.floor((Date.now() - ts) / 60000));
  if (mins < 60) return `hace ${mins} min`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `hace ${hrs} h`;
  const dias = Math.floor(hrs / 24);
  return dias === 1 ? 'ayer' : `hace ${dias} d`;
}

function mapNotificacion(raw: Record<string, unknown>, ordenes: Orden[]): Notificacion {
  const refTipo = raw.refTipo ? String(raw.refTipo) : undefined;
  const refId = raw.refId != null ? Number(raw.refId) : undefined;
  const ordenMatch = refTipo === 'orden' && refId != null
    ? ordenes.find((o) => o.dbId === refId)
    : undefined;

  return {
    id: String(raw.id ?? ''),
    tipo: (raw.tipo as Notificacion['tipo']) || 'cita',
    tono: (raw.tono as Notificacion['tono']) || 'amber',
    titulo: String(raw.titulo ?? ''),
    detalle: String(raw.detalle ?? ''),
    tiempo: formatTiempo(String(raw.fecha ?? '')),
    leida: Boolean(raw.leida),
    refTipo,
    refId,
    accion: ordenMatch
      ? { label: 'Ver orden', destino: { name: 'orden', id: ordenMatch.id }, primaria: true }
      : { label: 'Ver cita', destino: { name: 'citas' }, primaria: true },
  };
}

export async function loginStaff(correo: string, contrasena: string): Promise<string> {
  const data = await request<{ token: string; usuario: { nombre?: string; apellidos?: string } }>(
    '/auth/staff/login',
    {
      method: 'POST',
      body: JSON.stringify({ correo: correo.trim(), contrasena }),
    }
  );
  const fullName = [data.usuario?.nombre, data.usuario?.apellidos].filter(Boolean).join(' ') || 'Personal SIMA';
  saveSession(data.token, fullName);
  return fullName;
}

export async function fetchMe(): Promise<string> {
  const data = await request<{ nombre?: string; apellidos?: string }>('/auth/me');
  const fullName = [data.nombre, data.apellidos].filter(Boolean).join(' ') || getSavedUser() || 'Personal SIMA';
  localStorage.setItem(USER_KEY, fullName);
  return fullName;
}

export async function fetchCitas(): Promise<Cita[]> {
  const data = await request<Record<string, unknown>[]>('/citas');
  return Array.isArray(data) ? data.map(mapCita) : [];
}

export async function confirmarCitaApi(id: string): Promise<Cita> {
  const data = await request<Record<string, unknown>>(`/citas/${id}/confirmar`, { method: 'PATCH' });
  return mapCita(data);
}

export async function rechazarCitaApi(id: string, motivo: string): Promise<Cita> {
  const data = await request<Record<string, unknown>>(`/citas/${id}/rechazar`, {
    method: 'PATCH',
    body: JSON.stringify({ motivo }),
  });
  return mapCita(data);
}

export async function fetchOrdenes(): Promise<Orden[]> {
  const data = await request<Record<string, unknown>[]>('/ordenes');
  const lista = Array.isArray(data) ? data.map(mapOrden) : [];
  return Promise.all(
    lista.map((o) => (o.dbId != null ? fetchOrdenDetalle(o.dbId).catch(() => o) : Promise.resolve(o)))
  );
}

export async function fetchOrdenDetalle(dbId: number): Promise<Orden> {
  const data = await request<Record<string, unknown>>(`/ordenes/${dbId}`);
  return mapOrden(data);
}

export async function crearOrdenApi(payload: {
  clienteId: number;
  vehiculoId: number;
  servicioId: number;
  kilometraje: number;
  notas?: string;
  citaId?: number;
}): Promise<Orden> {
  const data = await request<Record<string, unknown>>('/ordenes', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  return mapOrden(data);
}

export async function guardarDiagnosticoApi(dbId: number, diagnostico: string): Promise<Orden> {
  const data = await request<Record<string, unknown>>(`/ordenes/${dbId}/diagnostico`, {
    method: 'PUT',
    body: JSON.stringify({ diagnostico }),
  });
  return mapOrden(data);
}

export async function cambiarEstadoOrdenApi(dbId: number, estado: OrdenEstado): Promise<Orden> {
  const data = await request<Record<string, unknown>>(`/ordenes/${dbId}/estado`, {
    method: 'PATCH',
    body: JSON.stringify({ estado }),
  });
  return mapOrden(data);
}

export async function agregarConceptoApi(
  dbId: number,
  concepto: { concepto: string; tipo: Concepto['tipo']; cantidad: number; precio: number }
): Promise<Orden> {
  const data = await request<Record<string, unknown>>(`/ordenes/${dbId}/conceptos`, {
    method: 'POST',
    body: JSON.stringify(concepto),
  });
  return mapOrden(data);
}

export async function eliminarConceptoApi(dbId: number, conceptoId: string): Promise<Orden> {
  const data = await request<Record<string, unknown>>(`/ordenes/${dbId}/conceptos/${conceptoId}`, {
    method: 'DELETE',
  });
  return mapOrden(data);
}

export async function enviarCotizacionApi(dbId: number): Promise<Orden> {
  const data = await request<Record<string, unknown>>(`/ordenes/${dbId}/enviar-cotizacion`, {
    method: 'POST',
  });
  return mapOrden(data);
}

export async function autorizarOrdenApi(
  dbId: number,
  decision: 'Autorizada' | 'Rechazada'
): Promise<Orden> {
  const data = await request<Record<string, unknown>>(`/ordenes/${dbId}/autorizacion`, {
    method: 'PATCH',
    body: JSON.stringify({ decision }),
  });
  return mapOrden(data);
}

export async function fetchServicios(): Promise<Servicio[]> {
  const data = await request<Record<string, unknown>[]>('/servicios?incluirInactivos=true');
  return Array.isArray(data) ? data.map(mapServicio) : [];
}

export async function crearServicioApi(s: Omit<Servicio, 'id' | 'activo'>): Promise<Servicio> {
  const data = await request<Record<string, unknown>>('/servicios', {
    method: 'POST',
    body: JSON.stringify(s),
  });
  return mapServicio(data);
}

export async function actualizarServicioApi(s: Servicio): Promise<Servicio> {
  const data = await request<Record<string, unknown>>(`/servicios/${s.id}`, {
    method: 'PUT',
    body: JSON.stringify({
      nombre: s.nombre,
      categoria: s.categoria,
      descripcion: s.descripcion,
      precio: s.precio,
      duracion: s.duracion,
      garantia: s.garantia,
    }),
  });
  return mapServicio(data);
}

export async function toggleServicioActivoApi(id: string, activo: boolean): Promise<Servicio> {
  const data = await request<Record<string, unknown>>(`/servicios/${id}/activo`, {
    method: 'PATCH',
    body: JSON.stringify({ activo }),
  });
  return mapServicio(data);
}

export async function fetchClientes(): Promise<Cliente[]> {
  const data = await request<Record<string, unknown>[]>('/clientes');
  return Array.isArray(data) ? data.map(mapCliente) : [];
}

export async function fetchNotificaciones(ordenes: Orden[]): Promise<Notificacion[]> {
  const data = await request<Record<string, unknown>[]>('/notificaciones');
  return Array.isArray(data) ? data.map((n) => mapNotificacion(n, ordenes)) : [];
}

export async function marcarNotifLeidaApi(id: string): Promise<void> {
  await request<unknown>(`/notificaciones/${id}/leida`, { method: 'PATCH' });
}

export async function marcarTodasNotifsLeidasApi(): Promise<void> {
  await request<unknown>('/notificaciones/leidas', { method: 'PATCH' });
}
