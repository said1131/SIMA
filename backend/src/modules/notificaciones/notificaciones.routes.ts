import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../../middlewares/auth';
import { ah, idParam, ok } from '../../utils/http';
import { notFound } from '../../utils/httpError';
import * as svc from './notificaciones.service';

export const notificacionesRouter = Router();
notificacionesRouter.use(requireAuth);

const listQuery = z.object({
  soloNoLeidas: z.enum(['true', 'false']).optional(),
  tipo: z.enum(['cita', 'orden', 'cotizacion']).optional(),
});

notificacionesRouter.get(
  '/',
  ah(async (req, res) => {
    const q = listQuery.parse(req.query);
    const u = req.user!;
    ok(res, await svc.listar(u.role, u.id, q.soloNoLeidas === 'true', q.tipo));
  })
);

notificacionesRouter.get(
  '/contador',
  ah(async (req, res) => {
    const u = req.user!;
    ok(res, { noLeidas: await svc.contarNoLeidas(u.role, u.id) });
  })
);

// Importante: esta ruta va antes de "/:id/leida"
notificacionesRouter.patch(
  '/leidas',
  ah(async (req, res) => {
    const u = req.user!;
    ok(res, { actualizadas: await svc.marcarTodas(u.role, u.id) });
  })
);

notificacionesRouter.patch(
  '/:id/leida',
  ah(async (req, res) => {
    const u = req.user!;
    if (!(await svc.marcarLeida(u.role, u.id, idParam(req.params.id)))) throw notFound('Notificación no encontrada');
    ok(res, { leida: true });
  })
);
