import { query } from '../../db/pool';
import type { AuthUser } from '../../middlewares/auth';
import { isStaff } from '../../middlewares/auth';
import { notFound } from '../../utils/httpError';

const SELECT = `
  SELECT id_vehiculo AS id, id_usuario AS clienteId, marca, modelo, anio, placas,
         CONCAT(marca, N' ', modelo, N' ', anio) AS descripcion
  FROM Vehiculos`;

export interface VehiculoInput {
  marca: string;
  modelo: string;
  anio: number;
  placas: string;
}

export function listar(user: AuthUser, clienteId?: number) {
  if (!isStaff(user)) return query(`${SELECT} WHERE id_usuario = @u ORDER BY id_vehiculo`, { u: user.id });
  if (clienteId) return query(`${SELECT} WHERE id_usuario = @u ORDER BY id_vehiculo`, { u: clienteId });
  return query(`${SELECT} ORDER BY id_usuario, id_vehiculo`);
}

async function obtenerPropio(user: AuthUser, id: number) {
  const r = await query(`${SELECT} WHERE id_vehiculo = @id AND id_usuario = @u`, { id, u: user.id });
  if (!r[0]) throw notFound('Vehículo no encontrado');
  return r[0];
}

export async function crear(user: AuthUser, i: VehiculoInput) {
  const r = await query<{ id: number }>(
    `INSERT INTO Vehiculos (id_usuario, marca, modelo, anio, placas)
     OUTPUT INSERTED.id_vehiculo AS id
     VALUES (@u, @marca, @modelo, @anio, @placas)`,
    { u: user.id, ...i, placas: i.placas.toUpperCase() }
  );
  return obtenerPropio(user, r[0].id);
}

export async function actualizar(user: AuthUser, id: number, i: VehiculoInput) {
  await obtenerPropio(user, id);
  await query(
    `UPDATE Vehiculos SET marca=@marca, modelo=@modelo, anio=@anio, placas=@placas
     WHERE id_vehiculo=@id AND id_usuario=@u`,
    { id, u: user.id, ...i, placas: i.placas.toUpperCase() }
  );
  return obtenerPropio(user, id);
}

export async function eliminar(user: AuthUser, id: number) {
  await obtenerPropio(user, id);
  // Si tiene citas u órdenes, SQL Server lanza error 547 y el errorHandler responde 409.
  await query('DELETE FROM Vehiculos WHERE id_vehiculo=@id AND id_usuario=@u', { id, u: user.id });
}
