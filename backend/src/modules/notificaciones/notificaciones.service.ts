import { execute, query } from '../../db/pool';
import type { Transaction } from 'mssql';

export interface NuevaNotif {
  audiencia: 'personal' | 'cliente';
  /** destinatario cuando audiencia = 'cliente' */
  usuarioId?: number | null;
  tipo: 'cita' | 'orden' | 'cotizacion';
  tono: 'amber' | 'green' | 'red' | 'slate';
  titulo: string;
  detalle: string;
  refTipo?: 'cita' | 'orden';
  refId?: number;
}

/**
 * Crea una notificación. Para clientes sin cuenta (tiene_cuenta = 0) no hace nada,
 * porque no tienen app donde recibirla.
 */
export async function notificar(n: NuevaNotif, tx?: Transaction): Promise<void> {
  await execute(
    `INSERT INTO Notificaciones (audiencia, id_usuario, tipo, tono, titulo, detalle, ref_tipo, ref_id)
     SELECT @audiencia, @usuarioId, @tipo, @tono, @titulo, @detalle, @refTipo, @refId
     WHERE @audiencia = N'personal'
        OR EXISTS (SELECT 1 FROM Usuarios WHERE id_usuario = @usuarioId AND tiene_cuenta = 1)`,
    {
      audiencia: n.audiencia,
      usuarioId: n.audiencia === 'cliente' ? n.usuarioId ?? null : null,
      tipo: n.tipo,
      tono: n.tono,
      titulo: n.titulo,
      detalle: n.detalle,
      refTipo: n.refTipo ?? null,
      refId: n.refId ?? null,
    },
    tx
  );
}

const SELECT = `
  SELECT id_notificacion AS id, tipo, tono, titulo, detalle, CAST(leida AS bit) AS leida,
         CONVERT(varchar(19), fecha, 126) AS fecha, ref_tipo AS refTipo, ref_id AS refId
  FROM Notificaciones`;

function destino(role: string, userId: number) {
  return role === 'cliente'
    ? { where: `audiencia = N'cliente' AND id_usuario = @uid`, params: { uid: userId } }
    : { where: `audiencia = N'personal'`, params: {} as Record<string, unknown> };
}

export async function listar(role: string, userId: number, soloNoLeidas: boolean, tipo?: string) {
  const d = destino(role, userId);
  const extra = [soloNoLeidas ? 'AND leida = 0' : '', tipo ? 'AND tipo = @tipo' : ''].join(' ');
  return query(`${SELECT} WHERE ${d.where} ${extra} ORDER BY fecha DESC, id_notificacion DESC`, {
    ...d.params,
    tipo: tipo ?? null,
  });
}

export async function contarNoLeidas(role: string, userId: number): Promise<number> {
  const d = destino(role, userId);
  const r = await query<{ n: number }>(
    `SELECT COUNT(*) AS n FROM Notificaciones WHERE ${d.where} AND leida = 0`,
    d.params
  );
  return r[0]?.n ?? 0;
}

export async function marcarLeida(role: string, userId: number, id: number): Promise<boolean> {
  const d = destino(role, userId);
  const n = await execute(
    `UPDATE Notificaciones SET leida = 1 WHERE id_notificacion = @id AND ${d.where}`,
    { id, ...d.params }
  );
  return n > 0;
}

export async function marcarTodas(role: string, userId: number): Promise<number> {
  const d = destino(role, userId);
  return execute(`UPDATE Notificaciones SET leida = 1 WHERE ${d.where} AND leida = 0`, d.params);
}
