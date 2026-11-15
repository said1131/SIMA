import type { NextFunction, Request, RequestHandler, Response } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env';
import type { Role } from '../types';
import { HttpError } from '../utils/httpError';

export interface AuthUser {
  /** id_usuario si role = 'cliente', id_empleado si role = 'mecanico' | 'admin' */
  id: number;
  role: Role;
  name: string;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

export function signToken(u: AuthUser): string {
  return jwt.sign({ role: u.role, name: u.name }, env.JWT_SECRET, {
    subject: String(u.id),
    expiresIn: env.JWT_EXPIRES_IN as jwt.SignOptions['expiresIn'],
  });
}

function readToken(req: Request): AuthUser | null {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) return null;
  try {
    const p = jwt.verify(header.slice(7), env.JWT_SECRET) as jwt.JwtPayload;
    return { id: Number(p.sub), role: p.role as Role, name: String(p.name ?? '') };
  } catch {
    return null;
  }
}

export const requireAuth: RequestHandler = (req, _res, next) => {
  const u = readToken(req);
  if (!u) return next(new HttpError(401, 'UNAUTHORIZED', 'Sesión no válida o expirada'));
  req.user = u;
  next();
};

/** Si hay token válido lo usa; si no, deja pasar como visitante. */
export const optionalAuth: RequestHandler = (req, _res, next) => {
  const u = readToken(req);
  if (u) req.user = u;
  next();
};

export const requireRole =
  (...roles: Role[]): RequestHandler =>
  (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) return next(new HttpError(401, 'UNAUTHORIZED', 'Debes iniciar sesión'));
    if (!roles.includes(req.user.role)) {
      return next(new HttpError(403, 'FORBIDDEN', 'No tienes permiso para esta acción'));
    }
    next();
  };

export const isStaff = (u: AuthUser): boolean => u.role !== 'cliente';

/** Combinaciones listas para usar en las rutas */
export const soloPersonal: RequestHandler[] = [requireAuth, requireRole('mecanico', 'admin')];
export const soloAdmin: RequestHandler[] = [requireAuth, requireRole('admin')];
export const soloCliente: RequestHandler[] = [requireAuth, requireRole('cliente')];
