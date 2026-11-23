import type { CSSProperties } from 'react';
import logoImage from '../assets/images/logo.png';

export type IconName =
  | 'home' | 'calendar' | 'clipboard' | 'grid' | 'bell' | 'car' | 'wrench'
  | 'check' | 'clock' | 'logout' | 'receipt' | 'x';

const PATHS: Record<IconName, string> = {
  home: 'M3 11l9-8 9 8M5 10v10h5v-6h4v6h5V10',
  calendar: 'M4 6h16v14H4zM4 10h16M8 3v4M16 3v4',
  clipboard: 'M8 4h8v3H8zM6 5H5v16h14V5h-1M9 12h6M9 16h6',
  grid: 'M4 4h6v6H4zM14 4h6v6h-6zM4 14h6v6H4zM14 14h6v6h-6z',
  bell: 'M6 16V11a6 6 0 0112 0v5l2 2H4zM10 21h4',
  car: 'M3 15l2-6a2 2 0 012-1h10a2 2 0 012 1l2 6v4h-3v-2H6v2H3zM7 14h.01M17 14h.01',
  wrench: 'M14 6a4 4 0 005 5l-9 9a2.1 2.1 0 01-3-3l9-9a4 4 0 01-2-2z',
  check: 'M5 13l4 4L19 7',
  clock: 'M12 7v5l3 2M12 3a9 9 0 100 18 9 9 0 000-18z',
  logout: 'M15 4h4v16h-4M10 8l-4 4 4 4M6 12h10',
  receipt: 'M6 3h12v18l-3-2-3 2-3-2-3 2zM9 8h6M9 12h6',
  x: 'M6 6l12 12M18 6L6 18',
};

interface Props {
  name: IconName;
  size?: number;
  style?: CSSProperties;
}

export function Icon({ name, size = 16, style }: Props) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2}
      strokeLinecap="round"
      strokeLinejoin="round"
      style={style}
      aria-hidden="true"
    >
      <path d={PATHS[name]} />
    </svg>
  );
}

export function Logo() {
  return (
    <div className="logo-box">
      <img
        className="logo-image"
        src={logoImage}
        alt="SIMA — Servicios integrales de mantenimiento automotriz"
      />
    </div>
  );
}
