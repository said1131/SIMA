import { Router } from 'express';
import { z } from 'zod';
import { isStaff, requireAuth, soloCliente } from '../../middlewares/auth';
import { asyncHandler as ah } from '../../utils/asyncHandler';
import { idParam, ok } from '../../utils/http';
import * as svc from './vehiculos.service';

export const vehiculosRouter = Router();

const body = z.object({
  marca: z.string().trim().min(1).max(40),
  modelo: z.string().trim().min(1).max(40),
  anio: z.number().int().min(1950).max(new Date().getFullYear() + 1),
  placas: z.string().trim().min(3).max(12),
});

// Cliente: sus vehículos. Personal: todos, o los de ?clienteId=
vehiculosRouter.get('/', requireAuth, ah(async (req, res) => {
  const clienteId = req.query.clienteId ? idParam(req.query.clienteId) : undefined;
  ok(res, await svc.listar(req.user!, isStaff(req.user!) ? clienteId : undefined));
}));

vehiculosRouter.post('/', ...soloCliente, ah(async (req, res) => ok(res, await svc.crear(req.user!, body.parse(req.body)), 201)));
vehiculosRouter.put('/:id', ...soloCliente, ah(async (req, res) =>
  ok(res, await svc.actualizar(req.user!, idParam(req.params.id), body.parse(req.body)))));
vehiculosRouter.delete('/:id', ...soloCliente, ah(async (req, res) => {
  await svc.eliminar(req.user!, idParam(req.params.id));
  ok(res, { eliminado: true });
}));
