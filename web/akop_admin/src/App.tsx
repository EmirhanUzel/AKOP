import { useState } from 'react'
import LoginPage from './features/auth/LoginPage'
import { loadSession, saveSession, type Session } from './features/auth/session'
import OrganizationsPage from './features/organizations/OrganizationsPage'
import OrganizationTypesPage from './features/organizations/OrganizationTypesPage'
import AdminLayout, { type AdminPage } from './shared/components/AdminLayout'

function App() {
  const [session, setSession] = useState<Session | null>(loadSession)
  const [page, setPage] = useState<AdminPage>('organizations')

  function update(next: Session | null) {
    saveSession(next)
    setSession(next)
    setPage('organizations')
  }

  if (!session) return <LoginPage onLoggedIn={update} />

  const signOut = () => update(null)
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
