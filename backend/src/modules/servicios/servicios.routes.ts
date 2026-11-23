import { Router } from 'express';
import { z } from 'zod';
import { isStaff, optionalAuth, soloPersonal } from '../../middlewares/auth';
import { CATEGORIAS } from '../../types';
import { asyncHandler as ah } from '../../utils/asyncHandler';
import { idParam, ok } from '../../utils/http';
import * as svc from './servicios.service';

export const serviciosRouter = Router();

const base = z.object({
  nombre: z.string().trim().min(1).max(100),
  descripcion: z.string().trim().max(300).default(''),
  categoria: z.enum(CATEGORIAS),
  precio: z.number().positive('El precio debe ser mayor a 0'),
  duracion: z.number().positive().max(99),
  garantia: z.number().int().min(0).max(120),
  activo: z.boolean().default(true),
});

// Catálogo público (la app lo usa sin iniciar sesión). El personal puede pedir también los inactivos.
serviciosRouter.get('/', optionalAuth, ah(async (req, res) => {
  const incluir = req.query.incluirInactivos === 'true' && !!req.user && isStaff(req.user);
  ok(res, await svc.listar(incluir));
}));

serviciosRouter.get('/:id', ah(async (req, res) => ok(res, await svc.obtener(idParam(req.params.id)))));

serviciosRouter.post('/', ...soloPersonal, ah(async (req, res) => ok(res, await svc.crear(base.parse(req.body)), 201)));

serviciosRouter.put('/:id', ...soloPersonal, ah(async (req, res) =>
  ok(res, await svc.actualizar(idParam(req.params.id), base.partial().parse(req.body)))));

serviciosRouter.patch('/:id/activo', ...soloPersonal, ah(async (req, res) => {
  const { activo } = z.object({ activo: z.boolean() }).parse(req.body);
  ok(res, await svc.actualizar(idParam(req.params.id), { activo }));
}));
