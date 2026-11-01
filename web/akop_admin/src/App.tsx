import { useState } from 'react'
import KurumPage from './features/kurum/KurumPage'
import LoginPage from './features/auth/LoginPage'
import { LOGIN_COPY, type LoginKind } from './features/auth/loginKinds'
import { loadSession, saveSession, type Session } from './features/auth/session'
import OrganizationsPage from './features/organizations/OrganizationsPage'
import OrganizationTypesPage from './features/organizations/OrganizationTypesPage'
import AdminLayout, { type AdminPage } from './shared/components/AdminLayout'

function App() {
  // shortcut: router kütüphanesi yok, adrese göre iki ayrı arayüz; yeni sayfalar gelirse router eklenir
  const kind: LoginKind = window.location.pathname.startsWith('/admin') ? 'admin' : 'kurum'
  // Başka arayüzün oturumu bu adreste geçerli sayılmaz
  const [session, setSession] = useState<Session | null>(() => {
    const saved = loadSession()
    return saved?.role === LOGIN_COPY[kind].role ? saved : null
  })
  const [page, setPage] = useState<AdminPage>('organizations')

  function update(next: Session | null) {
    saveSession(next)
    setSession(next)
    setPage('organizations')
  }

  if (!session) return <LoginPage kind={kind} onLoggedIn={update} />

  const signOut = () => update(null)
  if (kind === 'kurum') return <KurumPage token={session.token} onSignOut={signOut} />

  return (
    <AdminLayout
      page={page}
      onNavigate={setPage}
      onSignOut={signOut}
      title={page === 'organizations' ? 'Kurumlar' : 'Kurum türleri'}
    >
      {page === 'organizations' ? (
        <OrganizationsPage token={session.token} onSignOut={signOut} />
      ) : (
        <OrganizationTypesPage token={session.token} onSignOut={signOut} />
      )}
    </AdminLayout>
  )
}

export default App
