# API REST de SIMA · v1

Contrato para la **web (React)** y la **app móvil (Flutter)**. Ambas consumen esta misma API.

- **Base URL:** `http://<IP-de-la-PC>:3000/api/v1`
  - Emulador Android: `http://10.0.2.2:3000/api/v1`
  - Celular físico: la IP local de la PC que corre el backend (misma red Wi‑Fi), por ejemplo `http://192.168.1.50:3000/api/v1`
  - Web en desarrollo: `http://localhost:3000/api/v1`
- **Formato:** JSON (`Content-Type: application/json`), fechas `AAAA-MM-DD`, horas `HH:mm`, dinero en MXN con 2 decimales.
- **Autenticación:** `Authorization: Bearer <token>` (JWT que devuelve el login, vigencia 8 h).
- **Salud del servidor:** `GET http://<host>:3000/health`

## Formato de respuestas

Éxito:

```json
{ "data": { ... } }
```

Error (siempre con este formato):

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "Datos inválidos",
             "details": [ { "campo": "fecha", "mensaje": "Usa el formato AAAA-MM-DD" } ] } }
```

| HTTP | `code` | Cuándo |
|---|---|---|
| 400 | `VALIDATION_ERROR`, `BAD_REQUEST` | Datos mal formados o reglas básicas |
| 401 | `UNAUTHORIZED`, `INVALID_CREDENTIALS` | Sin token, token vencido o credenciales malas |
| 403 | `FORBIDDEN` | El rol no puede hacer esto |
| 404 | `NOT_FOUND` | No existe (o no es tuyo) |
| 409 | `CONFLICT`, `EMAIL_IN_USE`, `DUPLICATE` | Estado que no lo permite (p. ej. confirmar una cita ya rechazada) |
| 429 | `TOO_MANY_REQUESTS` | Demasiados intentos en endpoints públicos |

## Roles

| Rol | Quién | Cómo inicia sesión |
|---|---|---|
| `cliente` | Usuario de la app Flutter | `POST /auth/login` |
| `mecanico` | Personal del taller (web) | `POST /auth/staff/login` |
| `admin` | Encargado (web) | `POST /auth/staff/login` |

Un cliente solo ve **sus** citas, órdenes, vehículos y notificaciones.

## Estados

- **Cita:** `Solicitada` → `Confirmada` | `Rechazada` | `Cancelada`
- **Orden:** `Recibida` → `En diagnóstico` → `Cotizada` → `Autorizada` → `En reparación` → `Lista` → `Entregada`
- **Autorización de cotización:** `Pendiente` | `Autorizada` | `Rechazada`
- **Concepto de cotización (`tipo`):** `Refacción` | `Tornería` | `Labor`
- **Categoría de servicio:** `Preventivo` | `Frenos` | `Eléctrico` | `Suspensión` | `Motor`

Reglas del servidor: no se puede pasar a `Autorizada` o posteriores sin autorización del cliente; `Entregada` solo desde `Lista`; la cotización no se edita una vez enviada. El total ya **incluye IVA 16 %**.

---

## Auth

| Método y ruta | Rol | Descripción |
|---|---|---|
| `POST /auth/register` | público | Crea cuenta de cliente |
| `POST /auth/login` | público | Login de cliente (**Flutter**) |
| `POST /auth/staff/login` | público | Login del personal (**web**) |
| `GET /auth/me` | cualquiera | Perfil de la sesión |

```http
POST /auth/register
{ "nombre": "Ana", "apellidos": "Ruiz", "telefono": "9981234567",
  "correo": "ana@correo.com", "contrasena": "minimo8chars" }
```

```http
POST /auth/login   (staff: POST /auth/staff/login)
{ "correo": "ana@correo.com", "contrasena": "minimo8chars" }

200 → { "data": { "token": "eyJ...", "usuario": { "id": 7, "nombre": "Ana", "apellidos": "Ruiz",
                                                  "correo": "ana@correo.com", "rol": "cliente" } } }
```

## Servicios (catálogo)

| Método y ruta | Rol | Descripción |
|---|---|---|
| `GET /servicios` | público | Servicios activos. Personal: `?incluirInactivos=true` |
| `GET /servicios/:id` | público | Detalle |
| `POST /servicios` | personal | Crear |
| `PUT /servicios/:id` | personal | Editar |
| `PATCH /servicios/:id/activo` | personal | `{ "activo": false }` |

```json
{ "id": 2, "nombre": "Frenos delanteros", "descripcion": "Pastillas cerámicas y rectificado.",
  "categoria": "Frenos", "precio": 1950, "duracion": 2, "garantia": 6, "activo": true }
```

## Vehículos

| Método y ruta | Rol | Descripción |
|---|---|---|
| `GET /vehiculos` | cliente / personal | Cliente: los suyos. Personal: todos o `?clienteId=` |
| `POST /vehiculos` | cliente | `{ "marca", "modelo", "anio", "placas" }` |
| `PUT /vehiculos/:id` | cliente | Editar |
| `DELETE /vehiculos/:id` | cliente | 409 si tiene citas/órdenes |

```json
{ "id": 3, "clienteId": 7, "marca": "Toyota", "modelo": "Hilux", "anio": 2021,
  "placas": "ABC-892", "descripcion": "Toyota Hilux 2021" }
```

## Clientes (solo web)

`GET /clientes` → lista de clientes con sus vehículos (para "Nueva orden"). Rol: personal.

```json
{ "id": 7, "nombre": "Ana Ruiz", "telefono": "9981234567", "sinCuenta": false,
  "vehiculos": [ { "id": 3, "clienteId": 7, "descripcion": "VW Jetta 2017", "placas": "HTR-554" } ] }
```

## Citas

| Método y ruta | Rol | Descripción |
|---|---|---|
| `GET /citas` | cliente / personal | Cliente: las suyas. Filtro `?estado=Solicitada` |
| `GET /citas/:id` | cliente / personal | Detalle |
| `POST /citas` | cliente | Solicita cita |
| `POST /citas/express` | **público** | Cita de alguien **sin cuenta** |
| `PATCH /citas/:id/confirmar` | personal | `Solicitada` → `Confirmada` |
| `PATCH /citas/:id/rechazar` | personal | `{ "motivo": "..." }` |
| `PATCH /citas/:id/cancelar` | cliente | Cancela una cita propia |

```http
POST /citas
{ "vehiculoId": 3, "servicioId": 2, "fecha": "2026-10-26", "hora": "10:00" }
```

```http
POST /citas/express
{ "nombre": "Oswaldo", "apellidos": "Cruz", "telefono": "998 555 0142",
  "marca": "Toyota", "modelo": "Hilux", "anio": 2021, "placas": "ABC-892",
  "servicioId": 2, "fecha": "2026-10-26", "hora": "10:00" }
```

Respuesta de cita:

```json
{ "id": 12, "clienteId": 9, "cliente": "Oswaldo Cruz", "telefono": "998 555 0142", "sinCuenta": true,
  "vehiculoId": 15, "vehiculo": "Toyota Hilux 2021", "placas": "ABC-892",
  "servicioId": 2, "servicio": "Frenos delanteros", "fecha": "2026-10-26", "hora": "10:00",
  "estado": "Solicitada", "expres": true, "motivoRechazo": null }
```

## Órdenes de trabajo

| Método y ruta | Rol | Descripción |
|---|---|---|
| `GET /ordenes` | cliente / personal | Lista (cliente: las suyas). Filtro `?estado=` |
| `GET /ordenes/:id` | cliente / personal | Detalle con `conceptos`, `subtotal`, `iva`, `total` |
| `POST /ordenes` | personal | Recepción del vehículo (opcional `citaId`) |
| `PUT /ordenes/:id/diagnostico` | personal | `{ "diagnostico": "..." }` |
| `PATCH /ordenes/:id/estado` | personal | `{ "estado": "En reparación" }` |
| `POST /ordenes/:id/conceptos` | personal | Agrega concepto a la cotización |
| `DELETE /ordenes/:id/conceptos/:conceptoId` | personal | Quita concepto |
| `POST /ordenes/:id/enviar-cotizacion` | personal | Envía la cotización a la app del cliente |
| `PATCH /ordenes/:id/autorizacion` | cliente / personal* | `{ "decision": "Autorizada" \| "Rechazada" }` |

\* El personal solo puede registrar la decisión de un cliente **sin cuenta** (autorización por teléfono). El cliente con cuenta la responde desde la app **(Flutter)**.

```http
POST /ordenes
{ "clienteId": 7, "vehiculoId": 3, "servicioId": 2, "kilometraje": 45210,
  "notas": "Ruido metálico al frenar", "citaId": 12 }
```

```http
POST /ordenes/21/conceptos
{ "concepto": "Pastillas cerámicas delanteras", "tipo": "Refacción", "cantidad": 1, "precio": 1450 }
```

Respuesta de detalle:

```json
{ "id": 21, "folio": "OT-1082", "estado": "Cotizada", "diagnostico": "Pastillas con desgaste severo.",
  "autorizacion": "Pendiente", "cotizacionEnviada": true, "kilometraje": 45210, "notas": null,
  "fechaIngreso": "2026-10-24T09:41:00", "citaId": 12,
  "clienteId": 7, "cliente": "Carlos Mendoza", "telefono": "9981234567", "sinCuenta": false,
  "vehiculoId": 3, "vehiculo": "Toyota Hilux 2021", "placas": "ABC-892",
  "servicioId": 2, "servicio": "Frenos delanteros", "mecanico": "Carlos Méndez",
  "conceptos": [ { "id": 40, "concepto": "Pastillas cerámicas delanteras", "tipo": "Refacción",
                   "cantidad": 1, "precio": 1450, "subtotal": 1450 } ],
  "subtotal": 1250, "iva": 200, "total": 1450 }
```

## Notificaciones

El personal recibe avisos del taller; el cliente, los suyos. La app Flutter puede consultar `GET /notificaciones/contador` cada cierto tiempo (por ejemplo cada 30 s) para el globo de "sin leer".

| Método y ruta | Descripción |
|---|---|
| `GET /notificaciones` | Lista. Filtros `?soloNoLeidas=true`, `?tipo=cita\|orden\|cotizacion` |
| `GET /notificaciones/contador` | `{ "noLeidas": 3 }` |
| `PATCH /notificaciones/:id/leida` | Marca una |
| `PATCH /notificaciones/leidas` | Marca todas |

```json
{ "id": 5, "tipo": "cotizacion", "tono": "green", "titulo": "Cotización autorizada",
  "detalle": "Carlos Mendoza autorizó la cotización de OT-1082 · $3,100.00",
  "leida": false, "fecha": "2026-10-24T09:52:00", "refTipo": "orden", "refId": 21 }
```

`refTipo`/`refId` indican a dónde llevar al usuario al tocar el aviso (`cita` o `orden` con su `id`).

## Empleados (solo admin)

| Método y ruta | Descripción |
|---|---|
| `GET /empleados` | Lista del personal |
| `POST /empleados` | `{ "nombre", "apellidos", "puesto", "correo", "contrasena", "rol" }` |

## Qué recibe cada app

- **Flutter (cliente):** `auth/register`, `auth/login`, `servicios`, `vehiculos`, `citas` (incluye `express` y `cancelar`), `ordenes` (solo lectura + `autorizacion`), `notificaciones`.
- **Web (personal):** `auth/staff/login`, `clientes`, `citas` (confirmar/rechazar), `ordenes` (todo), `servicios` (alta/edición), `notificaciones`, `empleados` (admin).
