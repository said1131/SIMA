import { query } from '../../db/pool';
import { notFound } from '../../utils/httpError';

const SELECT = `
  SELECT id_servicio AS id, nombre, descripcion, categoria,
         CAST(precio_estimado AS decimal(12,2)) AS precio,
         CAST(duracion_horas AS float) AS duracion, garantia_meses AS garantia,
         CAST(CASE WHEN activo = 0 THEN 0 ELSE 1 END AS bit) AS activo
  FROM Servicios`;

export interface ServicioInput {
  nombre: string;
  descripcion: string;
  categoria: string;
  precio: number;
  duracion: number;
  garantia: number;
  activo: boolean;
}

export const listar = (incluirInactivos: boolean) =>
  query(`${SELECT} WHERE (@todos = 1 OR activo <> 0) ORDER BY categoria, nombre`, { todos: incluirInactivos });

export async function obtener(id: number) {
  const r = await query(`${SELECT} WHERE id_servicio = @id`, { id });
  if (!r[0]) throw notFound('Servicio no encontrado');
  return r[0];
}

export async function crear(i: ServicioInput) {
  const r = await query<{ id: number }>(
    `INSERT INTO Servicios (nombre, descripcion, categoria, precio_estimado, duracion_horas, garantia_meses, activo)
     OUTPUT INSERTED.id_servicio AS id
     VALUES (@nombre, @descripcion, @categoria, @precio, @duracion, @garantia, @activo)`,
    { ...i }
  );
  return obtener(r[0].id);
}

export async function actualizar(id: number, i: Partial<ServicioInput>) {
  const actual = (await obtener(id)) as ServicioInput;
  const m = { ...actual, ...i };
  await query(
    `UPDATE Servicios SET nombre=@nombre, descripcion=@descripcion, categoria=@categoria,
       precio_estimado=@precio, duracion_horas=@duracion, garantia_meses=@garantia, activo=@activo
     WHERE id_servicio=@id`,
    { id, nombre: m.nombre, descripcion: m.descripcion, categoria: m.categoria, precio: m.precio,
      duracion: m.duracion, garantia: m.garantia, activo: m.activo }
  );
  return obtener(id);
}
