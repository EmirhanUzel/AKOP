import { useState } from 'react'
import LoginPage from './features/auth/LoginPage'
import { loadSession, saveSession, type Session } from './features/auth/session'
import OrganizationsPage from './features/organizations/OrganizationsPage'

function App() {
  const [session, setSession] = useState<Session | null>(loadSession)

  function update(next: Session | null) {
    saveSession(next)
    setSession(next)
  }

  if (!session) return <LoginPage onLoggedIn={update} />
  return <OrganizationsPage token={session.token} onSignOut={() => update(null)} />
}

export default App
