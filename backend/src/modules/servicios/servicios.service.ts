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

const SERVICIOS_OFICIALES: Omit<ServicioInput, 'activo'>[] = [
  { nombre: 'Cambios de aceite de motor', categoria: 'Preventivo', descripcion: 'Cambio de aceite multigrado o sintético, filtro de aceite y revisión de niveles.', precio: 950, duracion: 1, garantia: 3 },
  { nombre: 'Lubricación', categoria: 'Preventivo', descripcion: 'Engrasado general de chasis, rótulas, terminales y puntos de articulación.', precio: 650, duracion: 1, garantia: 3 },
  { nombre: 'Servicio al sistema de enfriamiento', categoria: 'Preventivo', descripcion: 'Limpieza de radiador, revisión de mangueras, termostato y cambio de anticongelante.', precio: 1100, duracion: 2, garantia: 6 },
  { nombre: 'Alineación y balanceo', categoria: 'Preventivo', descripcion: 'Ajuste de ángulos de dirección y balanceo computarizado de las 4 ruedas.', precio: 850, duracion: 1, garantia: 3 },
  { nombre: 'Frenos', categoria: 'Correctivo', descripcion: 'Revisión y reemplazo de balatas, rectificado de discos/tambores y purga de líquido.', precio: 1450, duracion: 2, garantia: 6 },
  { nombre: 'Suspensiones', categoria: 'Correctivo', descripcion: 'Diagnóstico y cambio de amortiguadores, horquillas, bujes y bases.', precio: 1800, duracion: 3, garantia: 6 },
  { nombre: 'Reparaciones de motor (medios ajustes y ajustes completos)', categoria: 'Correctivo', descripcion: 'Servicio estrella: rectificación, cambio de anillos, metales, empaques y ajuste completo.', precio: 8500, duracion: 24, garantia: 12 },
  { nombre: 'Fallas electrónicas', categoria: 'Correctivo', descripcion: 'Diagnóstico con escáner automotriz, sensores, cableado y módulos electrónicos.', precio: 900, duracion: 2, garantia: 3 },
  { nombre: 'Sistemas ABS', categoria: 'Correctivo', descripcion: 'Diagnóstico y reparación de sensores de rueda, módulo hidráulico y testigos ABS.', precio: 1600, duracion: 3, garantia: 6 },
  { nombre: 'Transmisiones automáticas', categoria: 'Correctivo', descripcion: 'Diagnóstico, cambio de aceite ATF, filtro, solenoides y reparación de caja automática.', precio: 3200, duracion: 8, garantia: 6 },
  { nombre: 'Transmisiones estándar', categoria: 'Correctivo', descripcion: 'Ajuste y reparación de caja manual, clutch, collarín y sincronizadores.', precio: 2800, duracion: 6, garantia: 6 },
  { nombre: 'Hojalatería y pintura', categoria: 'Correctivo', descripcion: 'Enderezado de carrocería, igualación de color y acabado automotriz en cabina.', precio: 3500, duracion: 16, garantia: 12 },
  { nombre: 'Sistema de dirección hidráulica, electroasistida y electrónica', categoria: 'Correctivo', descripcion: 'Reparación de cremallera, bomba hidráulica, columna electroasistida y sensores.', precio: 2200, duracion: 4, garantia: 6 },
  { nombre: 'Elevadores, accesorios, puertas eléctricas y tableros', categoria: 'Correctivo', descripcion: 'Reparación de elevadores de cristales, seguros eléctricos, controles y tablero.', precio: 1100, duracion: 2, garantia: 3 },
];

export async function sincronizarCatalogoOficial(): Promise<void> {
  const nombres = SERVICIOS_OFICIALES.map((_, idx) => `@n${idx}`).join(', ');
  const paramsExcluir: Record<string, unknown> = {};
  SERVICIOS_OFICIALES.forEach((s, idx) => {
    paramsExcluir[`n${idx}`] = s.nombre;
  });

  // 1. Desvincula citas u órdenes viejas que apuntaban a servicios eliminados
  await query(
    `UPDATE Citas
     SET id_servicio = NULL
     WHERE id_servicio IN (SELECT id_servicio FROM Servicios WHERE nombre NOT IN (${nombres}))`,
    paramsExcluir
  );

  await query(
    `UPDATE OrdenesTrabajo
     SET id_servicio = NULL
     WHERE id_servicio IN (SELECT id_servicio FROM Servicios WHERE nombre NOT IN (${nombres}))`,
    paramsExcluir
  );

  // 2. Elimina definitivamente los servicios viejos que no están en el catálogo oficial
  await query(
    `DELETE FROM Servicios WHERE nombre NOT IN (${nombres})`,
    paramsExcluir
  );

  // 3. Inserta los nuevos o actualiza/activa los 14 oficiales
  for (const s of SERVICIOS_OFICIALES) {
    const existe = await query<{ id: number }>(
      'SELECT TOP 1 id_servicio AS id FROM Servicios WHERE nombre = @nombre',
      { nombre: s.nombre }
    );

    if (existe[0]) {
      await query(
        `UPDATE Servicios
         SET categoria = @categoria, descripcion = @descripcion, precio_estimado = @precio,
             duracion_horas = @duracion, garantia_meses = @garantia, activo = 1
         WHERE id_servicio = @id`,
        { ...s, id: existe[0].id }
      );
    } else {
      await query(
        `INSERT INTO Servicios (nombre, descripcion, categoria, precio_estimado, duracion_horas, garantia_meses, activo)
         VALUES (@nombre, @descripcion, @categoria, @precio, @duracion, @garantia, 1)`,
        s
      );
    }
  }
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