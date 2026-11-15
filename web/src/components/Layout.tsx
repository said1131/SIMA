import type { ReactNode } from 'react';
import type { Page } from '../types';
import { Icon, Logo } from './Icons';
import type { IconName } from './Icons';

export interface ShellProps {
  unread: number;
  toast: string | null;
  userName: string;
  onNavigate: (p: Page) => void;
  onLogout: () => void;
}

interface LayoutProps {
  shell: ShellProps;
  active: 'dashboard' | 'citas' | 'ordenes' | 'catalogo' | 'notificaciones';
  title: string;
  subtitle?: string;
  actions?: ReactNode;
  children: ReactNode;
}

const NAV: { id: LayoutProps['active']; label: string; icon: IconName; page: Page }[] = [
  { id: 'dashboard', label: 'Panel de inicio', icon: 'home', page: { name: 'dashboard' } },
  { id: 'citas', label: 'Citas', icon: 'calendar', page: { name: 'citas' } },
  { id: 'ordenes', label: 'Órdenes de trabajo', icon: 'clipboard', page: { name: 'ordenes' } },
  { id: 'catalogo', label: 'Catálogo de servicios', icon: 'grid', page: { name: 'catalogo' } },
  { id: 'notificaciones', label: 'Notificaciones', icon: 'bell', page: { name: 'notificaciones' } },
];

function initials(name: string): string {
  return name
    .replace(/^Ing\.\s*/, '')
    .split(' ')
    .map((p) => p[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
}

export function Layout({ shell, active, title, subtitle, actions, children }: LayoutProps) {
  return (
    <div className="app">
      <aside className="sidebar">
        <Logo />
        <div className="nav-label">OPERACIÓN</div>
        <nav>
          {NAV.map((n) => (
            <button
              key={n.id}
              className={'nav-item' + (active === n.id ? ' active' : '')}
              onClick={() => shell.onNavigate(n.page)}
            >
              <Icon name={n.icon} />
              {n.label}
              {n.id === 'notificaciones' && shell.unread > 0 && <span className="badge">{shell.unread}</span>}
            </button>
          ))}
        </nav>
        <div className="sidebar-user">
          <div className="avatar">{initials(shell.userName)}</div>
          <div className="who">
            {shell.userName}
            <small>Encargado del taller</small>
          </div>
          <button className="icon-btn" onClick={shell.onLogout} title="Cerrar sesión">
            <Icon name="logout" />
          </button>
        </div>
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <h1>{title}</h1>
            {subtitle && <p>{subtitle}</p>}
          </div>
          <div className="topbar-right">
            {shell.toast && <span className="toast">✓ {shell.toast}</span>}
            {actions}
            <button className="bell" onClick={() => shell.onNavigate({ name: 'notificaciones' })} aria-label="Notificaciones">
              <Icon name="bell" size={18} />
              {shell.unread > 0 && <span className="dot">{shell.unread}</span>}
            </button>
          </div>
        </header>
        {children}
      </main>
    </div>
  );
}
