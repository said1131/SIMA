import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, soloCliente, soloPersonal } from '../../middlewares/auth';
import { rateLimit } from '../../middlewares/rateLimit';
import { CITA_ESTADOS } from '../../types';
import { ah, FECHA, HORA, idParam, ok } from '../../utils/http';
import * as svc from './citas.service';

export const citasRouter = Router();

const nueva = z.object({
  vehiculoId: z.number().int().positive(),
  servicioId: z.number().int().positive(),
  fecha: FECHA,
  hora: HORA,
});

const expres = z.object({
  nombre: z.string().trim().min(1).max(60),
  apellidos: z.string().trim().max(80).optional(),
  telefono: z.string().trim().min(8).max(20),
  marca: z.string().trim().min(1).max(40),
  modelo: z.string().trim().min(1).max(40),
  anio: z.number().int().min(1950).max(new Date().getFullYear() + 1),
  placas: z.string().trim().min(3).max(12),
  servicioId: z.number().int().positive(),
  fecha: FECHA,
  hora: HORA,
});

citasRouter.get('/', requireAuth, ah(async (req, res) => {
  const estado = z.enum(CITA_ESTADOS).optional().parse(req.query.estado);
  ok(res, await svc.listar(req.user!, estado));
}));

citasRouter.get('/:id', requireAuth, ah(async (req, res) =>
  ok(res, await svc.obtener(idParam(req.params.id), req.user!))));

// App: cliente con cuenta
citasRouter.post('/', ...soloCliente, ah(async (req, res) =>
  ok(res, await svc.crear(req.user!, nueva.parse(req.body)), 201)));

// App: persona sin cuenta (público, con límite de intentos)
citasRouter.post('/express', rateLimit(10, 10 * 60 * 1000), ah(async (req, res) =>
  ok(res, await svc.crearExpres(expres.parse(req.body)), 201)));

// Web: personal
citasRouter.patch('/:id/confirmar', ...soloPersonal, ah(async (req, res) =>
  ok(res, await svc.confirmar(idParam(req.params.id)))));

citasRouter.patch('/:id/rechazar', ...soloPersonal, ah(async (req, res) => {
  const { motivo } = z.object({ motivo: z.string().trim().min(3).max(200) }).parse(req.body);
  ok(res, await svc.rechazar(idParam(req.params.id), motivo));
}));

// App: el cliente cancela su cita
citasRouter.patch('/:id/cancelar', ...soloCliente, ah(async (req, res) =>
  ok(res, await svc.cancelar(req.user!, idParam(req.params.id)))));
