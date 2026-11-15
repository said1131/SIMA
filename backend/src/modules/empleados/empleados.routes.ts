import bcrypt from 'bcryptjs';
import { Router } from 'express';
import { z } from 'zod';
import { query } from '../../db/pool';
import { soloAdmin } from '../../middlewares/auth';
import { ah, ok } from '../../utils/http';
import { HttpError } from '../../utils/httpError';

export const empleadosRouter = Router();

const nuevo = z.object({
  nombre: z.string().trim().min(1).max(60),
  apellidos: z.string().trim().min(1).max(80),
  puesto: z.string().trim().max(60).default(''),
  correo: z.string().trim().email().max(150),
  contrasena: z.string().min(8).max(100),
  rol: z.enum(['admin', 'mecanico']).default('mecanico'),
});

empleadosRouter.get('/', ...soloAdmin, ah(async (_req, res) => {
  ok(res, await query(
    `SELECT id_empleado AS id, nombre, apellidos, puesto, correo, rol FROM Empleados ORDER BY nombre`
  ));
}));

empleadosRouter.post('/', ...soloAdmin, ah(async (req, res) => {
  const b = nuevo.parse(req.body);
  const correo = b.correo.toLowerCase();
  const ya = await query('SELECT 1 AS x FROM Empleados WHERE correo = @correo', { correo });
  if (ya.length) throw new HttpError(409, 'EMAIL_IN_USE', 'Ya existe un empleado con ese correo');
  const hash = await bcrypt.hash(b.contrasena, 10);
  const r = await query<{ id: number }>(
    `INSERT INTO Empleados (nombre, apellidos, puesto, correo, password_hash, rol)
     OUTPUT INSERTED.id_empleado AS id
     VALUES (@nombre, @apellidos, @puesto, @correo, @hash, @rol)`,
    { nombre: b.nombre, apellidos: b.apellidos, puesto: b.puesto, correo, hash, rol: b.rol }
  );
  ok(res, { id: r[0].id, nombre: b.nombre, apellidos: b.apellidos, puesto: b.puesto, correo, rol: b.rol }, 201);
}));
