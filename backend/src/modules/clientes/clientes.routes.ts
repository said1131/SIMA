import { Router } from 'express';
import { query } from '../../db/pool';
import { soloPersonal } from '../../middlewares/auth';
import { ah, ok } from '../../utils/http';

/** Clientes con sus vehículos: lo usa la web para "Nueva orden". Solo personal. */
export const clientesRouter = Router();

clientesRouter.get('/', ...soloPersonal, ah(async (_req, res) => {
  const [clientes, vehiculos] = await Promise.all([
    query<{ id: number; nombre: string; telefono: string; sinCuenta: boolean }>(
      `SELECT id_usuario AS id, CONCAT(nombre, N' ', apellidos) AS nombre, telefono,
              CAST(CASE WHEN tiene_cuenta = 0 THEN 1 ELSE 0 END AS bit) AS sinCuenta
       FROM Usuarios ORDER BY nombre, apellidos`
    ),
    query<{ id: number; clienteId: number; descripcion: string; placas: string }>(
      `SELECT id_vehiculo AS id, id_usuario AS clienteId,
              CONCAT(marca, N' ', modelo, N' ', anio) AS descripcion, placas
       FROM Vehiculos ORDER BY id_vehiculo`
    ),
  ]);
  ok(res, clientes.map((c) => ({ ...c, vehiculos: vehiculos.filter((v) => v.clienteId === c.id) })));
}));
