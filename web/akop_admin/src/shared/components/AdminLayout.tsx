import type { ReactNode } from 'react'
import './AdminLayout.css'

export type AdminPage = 'organizations' | 'types'

const ADMIN_PAGES: { id: AdminPage; label: string }[] = [
  { id: 'organizations', label: 'Kurumlar' },
  { id: 'types', label: 'Kurum türleri' },
]

type Props<P extends string> = {
  /** Üst menüdeki bölümler; verilmezse sistem yöneticisi bölümleri. */
  pages?: { id: P; label: string }[]
  page?: P
  onNavigate?: (page: P) => void
  onSignOut: () => void
  title: string
  children: ReactNode
}

export default function AdminLayout<P extends string = AdminPage>({ pages, page, onNavigate, onSignOut, title, children }: Props<P>) {
  const items = pages ?? (ADMIN_PAGES as { id: P; label: string }[])
  return (
    <div className="admin-page">
      <header className="admin-topbar">
        <img className="admin-logo" src="/akop-logo.png" alt="AKOP" />
        {onNavigate && (
          <nav className="admin-nav" aria-label="Yönetim bölümleri">
            {items.map((p) => (
              <button key={p.id} type="button" aria-current={p.id === page ? 'page' : undefined} onClick={() => onNavigate(p.id)}>
                {p.label}
              </button>
            ))}
          </nav>
        )}
        <button type="button" className="admin-signout" onClick={onSignOut}>Çıkış yap</button>
      </header>

      <main className="admin-main">
        <h1>{title}</h1>
        {children}
      </main>
    </div>
  )
}
