# SIMA · Servicios Integrales de Mantenimiento Automotriz

Proyecto escolar compartido: **web del taller** (React + TypeScript), **app móvil** (Flutter) y **API REST** (Node + TypeScript) sobre **SQL Server**.

```
SIMA/
├── backend/   API REST (Node + TypeScript + Express)
├── web/       Administración del taller (React + TypeScript + Vite)
├── mobile/    App de clientes (Flutter, solo frontend: consume la API)
├── db/init/   Scripts que crean la base de datos automáticamente
├── docs/      API.md = contrato de la API (para Flutter y web)
└── docker-compose.yml
```

## Arranque rápido (cualquier computadora)

**Solo necesitas:** [Git](https://git-scm.com/) y [Docker](https://docs.docker.com/get-docker/) (Docker Desktop en Windows/Mac; Docker Engine + plugin Compose en Linux).
**No** necesitas instalar SQL Server, ni Node, ni crear la base de datos a mano.

```bash
git clone <URL-DEL-REPO>
cd SIMA
docker compose up --build
```

La primera vez tarda unos minutos (descarga SQL Server, ~1.5 GB). Cuando veas `API SIMA en http://localhost:3000` ya está todo:

| Qué | Dónde |
|---|---|
| API | http://localhost:3000/api/v1 |
| Salud de la API | http://localhost:3000/health → `{"status":"ok","db":true}` |
| Base de datos | `localhost`, puerto **14330** |

Para detenerlo: `Ctrl+C` (o `docker compose down`). Los datos se conservan entre arranques.

### Web (React)
Necesita [Node 20+](https://nodejs.org/). En otra terminal:
```bash
cd web
npm install
npm run dev          # http://localhost:5173
```

### App móvil (Flutter)
Solo apunta a la API. URL base según dónde corra la app:

| Dónde corre la app | Base URL |
|---|---|
| Emulador Android | `http://10.0.2.2:3000/api/v1` |
| Simulador iOS | `http://localhost:3000/api/v1` |
| Celular físico (misma red Wi‑Fi que la PC que corre Docker) | `http://<IP-de-esa-PC>:3000/api/v1` |

Endpoints y ejemplos de JSON: [`docs/API.md`](docs/API.md). Si el celular no conecta, abre el puerto 3000 en el firewall de la PC que corre Docker.

## Usuarios de prueba (datos de demostración)

| Para | Correo | Contraseña |
|---|---|---|
| Web del taller (administrador) | `taller@sima.mx` | `sima1234` |
| App Flutter (cliente) | `cliente@sima.mx` | `sima1234` |

Hay además 6 clientes más (`andrea@demo.sima.mx`, `roberto@…`, `mariana@…`, `luis@…`, `ana@…`), con la misma contraseña, y un cliente **sin cuenta** (Oswaldo Cruz) para probar la cita exprés. Los datos de demo solo se cargan cuando la base está vacía.

## Conectarte a la base con DBeaver (o similar)

| Campo | Valor |
|---|---|
| Servidor | `localhost` |
| Puerto | `14330` |
| Base de datos | `SIMADB` |
| Usuario / contraseña | `sa` / `Sima_Dev_2026!` |
| Opciones del driver | `trustServerCertificate=true` (en DBeaver: *Driver properties*) |

## Comandos útiles

```bash
docker compose up --build -d      # arrancar en segundo plano
docker compose logs -f api        # ver el log de la API
docker compose down               # detener (conserva los datos)
docker compose down -v            # detener y BORRAR la base: vuelve a crearse limpia con datos demo
docker compose up --build -d api  # reconstruir la API después de un git pull
```

Cada quien tiene **su propia copia local** de la base de datos (idéntica para todos al arrancar). Lo que haga en su computadora no afecta a los demás.

## Trabajo en equipo

- **Nunca** subas `.env` ni contraseñas reales al repo. Solo `.env.example`. Para cambiar algo: `cp .env.example .env`.
- **Cambios en la estructura de la BD:** actualiza `db/init/01_schema.sql` (instalaciones nuevas) y agrega un script de migración numerado en `backend/sql/` (BDs que ya existen). Avisen al equipo para hacer `docker compose down -v`.
- **Cambios en la API:** actualiza `docs/API.md` en el mismo commit; es el contrato con Flutter.
- Ramas sugeridas: `main` estable; cada quien trabaja en `feature/…` y abre Pull Request.

## Problemas frecuentes

| Síntoma | Solución |
|---|---|
| `port is already allocated` (14330 o 3000) | Algo más usa ese puerto. Crea `.env` y cambia `DB_HOST_PORT` o `API_PORT`. |
| `db` se queda "unhealthy" | SQL Server necesita **≥ 2 GB de RAM** para Docker (Docker Desktop → Settings → Resources). |
| Windows: Docker no arranca | Activa WSL2 y virtualización en la BIOS (lo pide Docker Desktop). |
| Mac con chip Apple (M1/M2/M3) | Docker Desktop → Settings → *Use Rosetta for x86/amd64 emulation*. Es más lento pero funciona. |
| `Login failed for user 'sima_api'` | Cambiaste `API_DB_PASSWORD` con datos ya creados: `docker compose down -v` y vuelve a levantar. |
| Contraseñas con `$` o comillas | Evítalas en `.env`; rompen los scripts. |
| Quiero ver el error de la BD | `docker compose logs db-init` |

## Sin Docker (alternativa)
Si prefieres usar tu propio SQL Server: ejecuta en orden `db/init/00_crear_bd.sql`, `01_schema.sql`, `02_login_api.sql` (en DBeaver, con *Ejecutar script*; el `02` usa la variable `$(API_PASSWORD)`: reemplázala por tu contraseña), luego `cd backend && cp .env.example .env && npm install && npm run seed && npm run dev`. Más detalle en [`backend/README.md`](backend/README.md).
