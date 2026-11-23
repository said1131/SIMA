import { Router } from 'express';
import { z } from 'zod';
import { requireAuth } from '../../middlewares/auth';
import { rateLimit } from '../../middlewares/rateLimit';
import { asyncHandler as ah } from '../../utils/asyncHandler';
import { ok } from '../../utils/http';
import { notFound } from '../../utils/httpError';
import * as svc from './auth.service';

export const authRouter = Router();

const registro = z.object({
  nombre: z.string().trim().min(1).max(60),
  apellidos: z.string().trim().min(1).max(80),
  telefono: z.string().trim().min(8).max(20),
  correo: z.string().trim().email().max(150),
  contrasena: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres').max(100),
});
const login = z.object({ correo: z.string().trim().email(), contrasena: z.string().min(1) });

const limiter = rateLimit(20, 10 * 60 * 1000);

// App móvil: clientes
authRouter.post('/register', limiter, ah(async (req, res) => ok(res, await svc.registrarCliente(registro.parse(req.body)), 201)));
authRouter.post('/login', limiter, ah(async (req, res) => {
  const b = login.parse(req.body);
  ok(res, await svc.loginCliente(b.correo, b.contrasena));
}));

// Web: personal del taller
authRouter.post('/staff/login', limiter, ah(async (req, res) => {
  const b = login.parse(req.body);
  ok(res, await svc.loginPersonal(b.correo, b.contrasena));
}));

authRouter.get('/me', requireAuth, ah(async (req, res) => {
  const p = await svc.perfil(req.user!.role, req.user!.id);
  if (!p) throw notFound('Usuario no encontrado');
  ok(res, p);
}));
