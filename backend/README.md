# SIMA · Backend (API REST)

Node.js + TypeScript + Express + SQL Server (`mssql`). Lo consumen la web (React) y la app móvil (Flutter).
Contrato completo de endpoints: [`../docs/API.md`](../docs/API.md).

## Puesta en marcha

> **Equipo nuevo / instalación limpia:** no necesitas nada de esto; usa `docker compose up --build` desde la raíz del repo (ver `../README.md`). Esta guía es para correr el backend sin Docker.

### 1. Actualizar una base de datos que YA existía
(Solo si tenías la BD anterior; una instalación limpia usa `../db/init/`.)
1. Abre `sql/01_migracion_simadb.sql` en DBeaver conectado a tu servidor (`localhost:1433`).
2. Ejecútalo completo con **Ejecutar script (Alt+X)**. Es una sola transacción: si falla algo, no deja nada a medias.
3. Revisa los resultados del final ("diagnóstico"): si aparecen filas, hay datos viejos por corregir.

### 2. Preparar SQL Server para recibir conexiones de la API
- En *SQL Server Configuration Manager* → *Protocolos de SQL Server* → activa **TCP/IP** (puerto **1433**) y reinicia el servicio.
- Activa la autenticación mixta (usuario y contraseña de SQL).
- Crea un usuario exclusivo para la API: el bloque comentado al final del script SQL ya lo trae.

### 3. Configurar y arrancar
```bash
cd SIMA/backend
cp .env.example .env      # edita DB_USER, DB_PASSWORD y JWT_SECRET
npm install
npm run seed              # crea el administrador (y catálogo de ejemplo si está vacío)
npm run dev               # http://localhost:3000
```

Pruebas rápidas:
- `http://localhost:3000/health` → `{"status":"ok","db":true}`
- Login de personal: `POST http://localhost:3000/api/v1/auth/staff/login` con `{"correo":"taller@sima.mx","contrasena":"sima1234"}`

### 4. Compartirlo con el equipo de Flutter
- Mismo Wi‑Fi: que usen `http://<IP de tu PC>:3000/api/v1` (`ip a` en Linux). En el emulador Android: `http://10.0.2.2:3000/api/v1`.
- Si el firewall bloquea: `sudo ufw allow 3000/tcp`.
- Pásales `docs/API.md`.

## Estructura

```
backend/
├── sql/01_migracion_simadb.sql     migración de la BD (SQL Server)
└── src/
    ├── config/env.ts               variables de entorno validadas
    ├── db/pool.ts                  conexión, query(), execute(), withTransaction()
    ├── middlewares/                auth (JWT + roles), errorHandler, rateLimit
    ├── modules/                    cada módulo: *.routes.ts (rutas + validación) y *.service.ts (SQL + reglas)
    │   ├── auth  servicios  vehiculos  clientes
    │   ├── citas  ordenes  notificaciones  empleados
    ├── utils/                      http, errores, formato
    ├── scripts/seed.ts             datos iniciales
    ├── app.ts                      Express + rutas /api/v1
    └── server.ts
```

## Scripts
| Comando | Qué hace |
|---|---|
| `npm run dev` | Servidor con recarga automática |
| `npm run build` / `npm start` | Compila a `dist/` y lo ejecuta |
| `npm run typecheck` | Revisa tipos sin compilar |
| `npm run seed` | Administrador + catálogo de ejemplo |

## Seguridad (ya incluida)
- Contraseñas con **bcrypt**; nunca se guardan ni se devuelven en texto.
- Consultas **parametrizadas** (sin concatenar texto) → sin inyección SQL.
- Validación de entrada con **zod** en cada endpoint.
- JWT con rol; un cliente solo accede a sus propios datos.
- Límite de intentos en login/registro/cita exprés.

> Si tu tabla `Usuarios` ya tenía contraseñas en texto plano, esos usuarios no podrán iniciar sesión hasta registrarse de nuevo o restablecerla: la API solo acepta hashes bcrypt.
