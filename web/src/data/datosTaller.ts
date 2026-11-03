import { Cita } from '../models/Cita'
import { ServicioTaller } from '../models/ServicioTaller'
import { OrdenTrabajo } from '../models/OrdenTrabajo'

export const citasIniciales = [
  new Cita(1, 'Mariana López', 'Nissan Versa 2021', 'Cambio de aceite', 'Hoy, 29 oct', '09:30', 'Solicitada'),
  new Cita(2, 'Carlos Méndez', 'Honda Civic 2019', 'Revisión de frenos', 'Hoy, 29 oct', '11:00', 'Solicitada'),
  new Cita(3, 'Paola Sánchez', 'Mazda 3 2022', 'Afinación', 'Hoy, 29 oct', '13:30', 'Confirmada'),
  new Cita(4, 'Jorge Ramírez', 'VW Jetta 2018', 'Diagnóstico general', 'Mañana, 30 oct', '10:00', 'Solicitada'),
]

export const ordenesIniciales = [
  new OrdenTrabajo('OT-0248', 'Ana Torres', 'Toyota Corolla 2020', 'YZA-482-B', 'Servicio de frenos', 'En diagnóstico', '29 oct, 08:42', 0),
  new OrdenTrabajo('OT-0247', 'Luis Herrera', 'Ford Focus 2017', 'UVB-190-A', 'Afinación mayor', 'En reparación', '28 oct, 16:15', 4850),
  new OrdenTrabajo('OT-0246', 'Daniela Cruz', 'Kia Rio 2022', 'WXC-735-C', 'Cambio de aceite', 'Lista para entregar', '28 oct, 11:20', 1650),
  new OrdenTrabajo('OT-0245', 'Roberto Díaz', 'Chevrolet Aveo 2019', 'PQR-621-D', 'Revisión de suspensión', 'Cotizada', '27 oct, 14:50', 3200),
]

export const serviciosIniciales = [
  new ServicioTaller('Cambio de aceite', 'Aceite y filtro de motor', 950, true),
  new ServicioTaller('Afinación básica', 'Revisión y mantenimiento preventivo', 1800, true),
  new ServicioTaller('Revisión de frenos', 'Inspección de balatas y discos', 650, true),
  new ServicioTaller('Diagnóstico general', 'Escaneo y revisión multipunto', 500, false),
]