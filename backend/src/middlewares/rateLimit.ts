import type { RequestHandler } from 'express';
import { HttpError } from '../utils/httpError';

/** Limitador sencillo en memoria por IP (suficiente para endpoints públicos en un proyecto escolar). */
export function rateLimit(max: number, windowMs: number): RequestHandler {
  const hits = new Map<string, { count: number; reset: number }>();
  return (req, _res, next) => {
    const now = Date.now();
    const key = req.ip ?? 'desconocida';
    const h = hits.get(key);
    if (!h || h.reset < now) {
      hits.set(key, { count: 1, reset: now + windowMs });
      return next();
    }
    h.count += 1;
    if (h.count > max) {
      return next(new HttpError(429, 'TOO_MANY_REQUESTS', 'Demasiados intentos, espera unos minutos'));
    }
    next();
  };
}
