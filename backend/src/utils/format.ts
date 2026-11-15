const MESES = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/** '2026-10-24' -> '24 oct' */
export function fmtFecha(iso: string): string {
  const [, m, d] = iso.split('-');
  return `${Number(d)} ${MESES[Number(m) - 1]}`;
}

export function fmtMoney(n: number): string {
  return '$' + n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

export const round2 = (n: number): number => Math.round((n + Number.EPSILON) * 100) / 100;

/** Fecha local del servidor en formato YYYY-MM-DD */
export const hoyISO = (): string => new Date().toLocaleDateString('sv-SE');

/** '2026-10-24' -> '20261024' (formato que SQL Server interpreta igual con cualquier idioma) */
export const sqlDate = (iso: string): string => iso.replace(/-/g, '');
