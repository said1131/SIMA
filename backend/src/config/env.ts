import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  PORT: z.coerce.number().default(3000),
  DB_SERVER: z.string().default('localhost'),
  DB_PORT: z.coerce.number().default(1433),
  DB_NAME: z.string().default('SIMADB'),
  DB_USER: z.string().min(1, 'DB_USER es obligatorio'),
  DB_PASSWORD: z.string().min(1, 'DB_PASSWORD es obligatorio'),
  DB_ENCRYPT: z.enum(['true', 'false']).default('false'),
  JWT_SECRET: z.string().min(16, 'JWT_SECRET debe tener al menos 16 caracteres'),
  JWT_EXPIRES_IN: z.string().default('8h'),
  CORS_ORIGINS: z.string().default('http://localhost:5173'),
  SEED_ADMIN_EMAIL: z.string().default('taller@sima.mx'),
  SEED_ADMIN_PASSWORD: z.string().default('sima1234'),
  SEED_DEMO: z.enum(['true', 'false']).default('true'),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('Configuración inválida en .env:');
  for (const i of parsed.error.issues) console.error(` - ${i.path.join('.')}: ${i.message}`);
  process.exit(1);
}

export const env = {
  ...parsed.data,
  DB_ENCRYPT: parsed.data.DB_ENCRYPT === 'true',
  SEED_DEMO: parsed.data.SEED_DEMO === 'true',
  corsOrigins: parsed.data.CORS_ORIGINS.split(',').map((s) => s.trim()).filter(Boolean),
};
