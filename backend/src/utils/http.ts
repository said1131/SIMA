import type { Request, RequestHandler, Response } from 'express';
import { z } from 'zod';

/** Envuelve handlers async para que los errores lleguen al errorHandler. */
export const ah =
  (fn: (req: Request, res: Response) => Promise<unknown>): RequestHandler =>
  (req, res, next) => {
    fn(req, res).catch(next);
  };

export const ok = (res: Response, data: unknown, status = 200) => res.status(status).json({ data });

export const idParam = (v: unknown): number => z.coerce.number().int().positive().parse(v);

export const FECHA = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Usa el formato AAAA-MM-DD');
export const HORA = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Usa el formato HH:mm');
