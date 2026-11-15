import bcrypt from 'bcryptjs';
import { query } from '../../db/pool';
import { signToken } from '../../middlewares/auth';
import { HttpError } from '../../utils/httpError';

export interface RegistroInput {
  nombre: string;
  apellidos: string;
  telefono: string;
  correo: string;
  contrasena: string;
}

const CREDENCIALES = () =>
  new HttpError(401, 'INVALID_CREDENTIALS', 'Correo o contraseña incorrectos');

export async function registrarCliente(i: RegistroInput) {
  const correo = i.correo.toLowerCase();
  const existe = await query('SELECT id_usuario FROM Usuarios WHERE correo = @correo', { correo });
  if (existe.length) throw new HttpError(409, 'EMAIL_IN_USE', 'Ya existe una cuenta con ese correo');

  const hash = await bcrypt.hash(i.contrasena, 10);
  const r = await query<{ id: number }>(
    `INSERT INTO Usuarios (nombre, apellidos, telefono, correo, contrasena, tiene_cuenta)
     OUTPUT INSERTED.id_usuario AS id
     VALUES (@nombre, @apellidos, @telefono, @correo, @hash, 1)`,
    { nombre: i.nombre, apellidos: i.apellidos, telefono: i.telefono, correo, hash }
  );
  const id = r[0].id;
  const nombreCompleto = `${i.nombre} ${i.apellidos}`.trim();
  return {
    token: signToken({ id, role: 'cliente', name: nombreCompleto }),
    usuario: { id, nombre: i.nombre, apellidos: i.apellidos, telefono: i.telefono, correo, rol: 'cliente' as const },
  };
}

export async function loginCliente(correoIn: string, contrasena: string) {
  const correo = correoIn.toLowerCase();
  const rows = await query<{
    id: number; nombre: string; apellidos: string; telefono: string; hash: string | null;
  }>(
    `SELECT id_usuario AS id, nombre, apellidos, telefono, contrasena AS hash
     FROM Usuarios WHERE correo = @correo AND tiene_cuenta = 1`,
    { correo }
  );
  const u = rows[0];
  if (!u || !u.hash || !(await bcrypt.compare(contrasena, u.hash))) throw CREDENCIALES();
  return {
    token: signToken({ id: u.id, role: 'cliente', name: `${u.nombre} ${u.apellidos}`.trim() }),
    usuario: { id: u.id, nombre: u.nombre, apellidos: u.apellidos, telefono: u.telefono, correo, rol: 'cliente' as const },
  };
}

export async function loginPersonal(correoIn: string, contrasena: string) {
  const correo = correoIn.toLowerCase();
  const rows = await query<{
    id: number; nombre: string; apellidos: string; puesto: string | null; rol: 'mecanico' | 'admin'; hash: string | null;
  }>(
    `SELECT id_empleado AS id, nombre, apellidos, puesto, rol, password_hash AS hash
     FROM Empleados WHERE correo = @correo`,
    { correo }
  );
  const e = rows[0];
  if (!e || !e.hash || !(await bcrypt.compare(contrasena, e.hash))) throw CREDENCIALES();
  const nombreCompleto = `${e.nombre} ${e.apellidos}`.trim();
  return {
    token: signToken({ id: e.id, role: e.rol, name: nombreCompleto }),
    usuario: { id: e.id, nombre: e.nombre, apellidos: e.apellidos, puesto: e.puesto, correo, rol: e.rol },
  };
}

export async function perfil(role: string, id: number) {
  if (role === 'cliente') {
    const r = await query(
      `SELECT id_usuario AS id, nombre, apellidos, telefono, correo, N'cliente' AS rol
       FROM Usuarios WHERE id_usuario = @id`,
      { id }
    );
    return r[0] ?? null;
  }
  const r = await query(
    `SELECT id_empleado AS id, nombre, apellidos, puesto, correo, rol FROM Empleados WHERE id_empleado = @id`,
    { id }
  );
  return r[0] ?? null;
}
