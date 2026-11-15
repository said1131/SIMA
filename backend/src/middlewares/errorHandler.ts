import type { ErrorRequestHandler, RequestHandler } from 'express';
import { ZodError } from 'zod';
import { HttpError } from '../utils/httpError';

export const notFoundHandler: RequestHandler = (req, res) => {
  res.status(404).json({
    error: { code: 'NOT_FOUND', message: `Ruta no encontrada: ${req.method} ${req.originalUrl}` },
  });
};

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Datos inválidos',
        details: err.issues.map((i) => ({ campo: i.path.join('.'), mensaje: i.message })),
      },
    });
  }

  if (err instanceof HttpError) {
    return res.status(err.status).json({ error: { code: err.code, message: err.message } });
  }

  if (err?.type === 'entity.parse.failed') {
    return res.status(400).json({ error: { code: 'BAD_JSON', message: 'El cuerpo no es un JSON válido' } });
  }

  // Errores de SQL Server
  const num: number | undefined = err?.number ?? err?.originalError?.info?.number;
  if (num === 547) {
    return res.status(409).json({
      error: { code: 'CONFLICT', message: 'La operación no es posible: el registro está relacionado con otros datos' },
    });
  }
  if (num === 2627 || num === 2601) {
    return res.status(409).json({ error: { code: 'DUPLICATE', message: 'Ya existe un registro con esos datos' } });
  }

  console.error(err);
  res.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Error interno del servidor' } });
};
