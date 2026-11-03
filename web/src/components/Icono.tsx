import type { ReactNode } from 'react'

const trazos: Record<string, ReactNode> = {
  cuadricula: <><rect x="3" y="3" width="7" height="7" rx="1" /><rect x="14" y="3" width="7" height="7" rx="1" /><rect x="3" y="14" width="7" height="7" rx="1" /><rect x="14" y="14" width="7" height="7" rx="1" /></>,
  calendario: <><rect x="3" y="5" width="18" height="16" rx="2" /><path d="M16 3v4M8 3v4M3 11h18" /></>,
  llave: <><path d="M14.7 6.3a5 5 0 0 0-6.4 6.4l-5.8 5.8a2 2 0 0 0 2.8 2.8l5.8-5.8a5 5 0 0 0 6.4-6.4L14 12l-2-2z" /></>,
  capas: <><path d="m12 3 9 5-9 5-9-5 9-5z" /><path d="m3 12 9 5 9-5M3 16l9 5 9-5" /></>,
  busqueda: <><circle cx="11" cy="11" r="7" /><path d="m20 20-4-4" /></>,
  campana: <><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" /></>,
  mas: <><path d="M12 5v14M5 12h14" /></>,
  flecha: <><path d="M5 12h14M13 6l6 6-6 6" /></>,
  reloj: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  automovil: <><path d="m5 11 1.5-4.5A2 2 0 0 1 8.4 5h7.2a2 2 0 0 1 1.9 1.5L19 11M3 11h18v8H3zM6 19v2m12-2v2M6.5 15h.01M17.5 15h.01" /><path d="M3 14h18" /></>,
  marca: <path d="m5 12 4 4L19 6" />,
  cerrar: <path d="m6 6 12 12M18 6 6 18" />,
  regresar: <><path d="m15 18-6-6 6-6" /><path d="M20 12H9" /></>,
  cerrarSesion: <><path d="M10 17l5-5-5-5M15 12H3" /><path d="M12 3h7a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-7" /></>,
}

export default function Icono({ nombre, tamano = 18 }: { nombre: string; tamano?: number }) {
  return <svg aria-hidden="true" width={tamano} height={tamano} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">{trazos[nombre]}</svg>
}