import sql from 'mssql';
import { env } from '../config/env';

let pool: sql.ConnectionPool | null = null;
let poolPromise: Promise<sql.ConnectionPool> | null = null;

export async function getPool(): Promise<sql.ConnectionPool> {
  if (pool && pool.connected) return pool;
  if (poolPromise) return poolPromise;

  const pending = new sql.ConnectionPool({
    server: env.DB_SERVER,
    port: env.DB_PORT,
    database: env.DB_NAME,
    user: env.DB_USER,
    password: env.DB_PASSWORD,
    options: { encrypt: env.DB_ENCRYPT, trustServerCertificate: true },
    pool: { max: 10, min: 0, idleTimeoutMillis: 30_000 },
  }).connect();
  poolPromise = pending;

  try {
    const connectedPool = await pending;
    pool = connectedPool;
    connectedPool.on('error', (error) => {
      console.error('Error en el pool de SQL Server:', error);
      if (pool === connectedPool) {
        pool = null;
        poolPromise = null;
      }
    });
    return connectedPool;
  } catch (error) {
    if (poolPromise === pending) poolPromise = null;
    throw error;
  }
}

type Params = Record<string, unknown>;

async function buildRequest(params?: Params, tx?: sql.Transaction): Promise<sql.Request> {
  const req = tx ? new sql.Request(tx) : (await getPool()).request();
  for (const [k, v] of Object.entries(params ?? {})) {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    req.input(k, (v === undefined ? null : v) as any);
  }
  return req;
}

/** Ejecuta un SELECT (o INSERT ... OUTPUT) con parámetros @nombre y devuelve las filas. */
export async function query<T = any>(text: string, params?: Params, tx?: sql.Transaction): Promise<T[]> {
  const r = await (await buildRequest(params, tx)).query(text);
  return (r.recordset ?? []) as T[];
}

/** Ejecuta UPDATE/DELETE/INSERT y devuelve cuántas filas se afectaron. */
export async function execute(text: string, params?: Params, tx?: sql.Transaction): Promise<number> {
  const r = await (await buildRequest(params, tx)).query(text);
  return r.rowsAffected.reduce((a, b) => a + b, 0);
}

export async function withTransaction<T>(fn: (tx: sql.Transaction) => Promise<T>): Promise<T> {
  const tx = new sql.Transaction(await getPool());
  await tx.begin();
  try {
    const result = await fn(tx);
    await tx.commit();
    return result;
  } catch (e) {
    try {
      await tx.rollback();
    } catch {
      /* ya estaba revertida */
    }
    throw e;
  }
}
