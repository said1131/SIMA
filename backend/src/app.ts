import cors from 'cors';
import express from 'express';
import { env } from './config/env';
import { query } from './db/pool';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler';
import { authRouter } from './modules/auth/auth.routes';
import { citasRouter } from './modules/citas/citas.routes';
import { clientesRouter } from './modules/clientes/clientes.routes';
import { empleadosRouter } from './modules/empleados/empleados.routes';
import { notificacionesRouter } from './modules/notificaciones/notificaciones.routes';
import { ordenesRouter } from './modules/ordenes/ordenes.routes';
import { serviciosRouter } from './modules/servicios/servicios.routes';
import { vehiculosRouter } from './modules/vehiculos/vehiculos.routes';

export function createApp() {
  const app = express();

  app.use(cors({ origin: env.corsOrigins, credentials: false }));
  app.use(express.json({ limit: '100kb' }));

  app.get('/health', async (_req, res) => {
    try {
      await query('SELECT 1 AS ok');
      res.json({ status: 'ok', db: true });
    } catch {
      res.status(503).json({ status: 'error', db: false });
    }
  });

  const api = express.Router();
  api.use('/auth', authRouter);
  api.use('/servicios', serviciosRouter);
  api.use('/vehiculos', vehiculosRouter);
  api.use('/clientes', clientesRouter);
  api.use('/citas', citasRouter);
  api.use('/ordenes', ordenesRouter);
  api.use('/notificaciones', notificacionesRouter);
  api.use('/empleados', empleadosRouter);
  app.use('/api/v1', api);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
