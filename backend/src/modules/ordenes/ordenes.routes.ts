import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, soloPersonal } from '../../middlewares/auth';
import { ORDEN_ESTADOS, TIPOS_CONCEPTO } from '../../types';
import { asyncHandler as ah } from '../../utils/asyncHandler';
import { idParam, ok } from '../../utils/http';
import * as svc from './ordenes.service';

export const ordenesRouter = Router();

const nueva = z.object({
  clienteId: z.number().int().positive(),
  vehiculoId: z.number().int().positive(),
  servicioId: z.number().int().positive(),
  kilometraje: z.number().int().min(0).max(2_000_000),
  notas: z.string().trim().max(500).optional(),
  citaId: z.number().int().positive().optional(),
});

const concepto = z.object({
  concepto: z.string().trim().min(1).max(150),
  tipo: z.enum(TIPOS_CONCEPTO),
  cantidad: z.number().positive().max(9999),
  precio: z.number().min(0).max(9_999_999),
});

ordenesRouter.get('/', requireAuth, ah(async (req, res) => {
  const estado = z.enum(ORDEN_ESTADOS).optional().parse(req.query.estado);
  ok(res, await svc.listar(req.user!, estado));
}));

ordenesRouter.get('/:id', requireAuth, ah(async (req, res) =>
  ok(res, await svc.obtener(req.user!, idParam(req.params.id)))));

ordenesRouter.post('/', ...soloPersonal, ah(async (req, res) =>
  ok(res, await svc.crear(req.user!, nueva.parse(req.body)), 201)));

ordenesRouter.put('/:id/diagnostico', ...soloPersonal, ah(async (req, res) => {
  const { diagnostico } = z.object({ diagnostico: z.string().trim().max(2000) }).parse(req.body);
  ok(res, await svc.guardarDiagnostico(req.user!, idParam(req.params.id), diagnostico));
}));

ordenesRouter.patch('/:id/estado', ...soloPersonal, ah(async (req, res) => {
  const { estado } = z.object({ estado: z.enum(ORDEN_ESTADOS) }).parse(req.body);
  ok(res, await svc.cambiarEstado(req.user!, idParam(req.params.id), estado));
}));

ordenesRouter.post('/:id/conceptos', ...soloPersonal, ah(async (req, res) =>
  ok(res, await svc.agregarConcepto(req.user!, idParam(req.params.id), concepto.parse(req.body)), 201)));

ordenesRouter.delete('/:id/conceptos/:conceptoId', ...soloPersonal, ah(async (req, res) =>
  ok(res, await svc.quitarConcepto(req.user!, idParam(req.params.id), idParam(req.params.conceptoId)))));

ordenesRouter.post('/:id/enviar-cotizacion', ...soloPersonal, ah(async (req, res) =>
  ok(res, await svc.enviarCotizacion(req.user!, idParam(req.params.id)))));

// Cliente (app) o personal (solo si el cliente no tiene cuenta)
ordenesRouter.patch('/:id/autorizacion', requireAuth, ah(async (req, res) => {
  const { decision } = z.object({ decision: z.enum(['Autorizada', 'Rechazada']) }).parse(req.body);
  ok(res, await svc.decidirAutorizacion(req.user!, idParam(req.params.id), decision));
}));
