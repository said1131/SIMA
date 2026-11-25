import { env } from './config/env';
import { getPool } from './db/pool';
import { createApp } from './app';
import { sincronizarCatalogoOficial } from './modules/servicios/servicios.service';

async function main() {
  try {
    await getPool();
    console.log(`✔ Conectado a SQL Server (${env.DB_SERVER}:${env.DB_PORT}/${env.DB_NAME})`);
    await sincronizarCatalogoOficial();
    console.log('✔ Catálogo oficial de servicios sincronizado');
  } catch (e) {
    console.error('✖ No se pudo conectar a SQL Server. Revisa .env, TCP/IP en el puerto 1433 y el usuario.');
    console.error(e);
    process.exit(1);
  }

  // 0.0.0.0 para que el celular / emulador Flutter pueda alcanzar la API desde la red local
  createApp().listen(env.PORT, '0.0.0.0', () => {
    console.log(`✔ API SIMA en http://localhost:${env.PORT}/api/v1  (health: /health)`);
  });
}

main();