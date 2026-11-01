import type { ReactNode } from 'react'
import './AdminLayout.css'

export type AdminPage = 'organizations' | 'types'

const PAGES: { id: AdminPage; label: string }[] = [
  { id: 'organizations', label: 'Kurumlar' },
  { id: 'types', label: 'Kurum türleri' },
]

type Props = {
  page: AdminPage
  onNavigate: (page: AdminPage) => void
  onSignOut: () => void
  title: string
  children: ReactNode
}

export default function AdminLayout({ page, onNavigate, onSignOut, title, children }: Props) {
  return (
    <div className="admin-page">
      <header className="admin-topbar">
        <img className="admin-logo" src="/akop-logo.png" alt="AKOP" />
        <nav className="admin-nav" aria-label="Yönetim bölümleri">
          {PAGES.map((p) => (
            <button key={p.id} type="button" aria-current={p.id === page ? 'page' : undefined} onClick={() => onNavigate(p.id)}>
              {p.label}
            </button>
          ))}
        </nav>
        <button type="button" className="admin-signout" onClick={onSignOut}>Çıkış yap</button>
      </header>

      <main className="admin-main">
        <h1>{title}</h1>
        {children}
      </main>
    </div>
  )
}
