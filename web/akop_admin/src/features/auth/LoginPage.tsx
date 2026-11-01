import { useState, type SubmitEvent } from 'react'
import { IDENTITY_API, request } from '../../core/api/http'
import type { Session } from './session'
import './LoginPage.css'

type Errors = { email?: string; password?: string }

function EyeIcon({ off }: { off: boolean }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7-10-7-10-7Z" />
      <circle cx="12" cy="12" r="3" />
      {off && <path d="M4 4l16 16" />}
    </svg>
  )
}

export default function LoginPage({ onLoggedIn }: { onLoggedIn: (session: Session) => void }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [errors, setErrors] = useState<Errors>({})
  const [formError, setFormError] = useState('')
  const [busy, setBusy] = useState(false)

  async function handleSubmit(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault()
    const next: Errors = {}
    if (!email.trim()) next.email = 'E-posta zorunludur.'
    if (!password) next.password = 'Şifre zorunludur.'
    setErrors(next)
    setFormError('')
    if (next.email || next.password) return

    setBusy(true)
    try {
      const res = await request<{ accessToken: string; role: string }>(`${IDENTITY_API}/Auth/login`, {
        method: 'POST',
        body: JSON.stringify({ email: email.trim(), password }),
      })
      // Şimdilik yalnızca sistem yöneticisi ekranları var
      if (res.role !== 'SystemAdmin') {
        setFormError('Bu hesabın panele erişimi yok.')
        return
      }
      onLoggedIn({ token: res.accessToken, role: res.role })
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Giriş yapılamadı.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <main className="login-page">
      <div className="login-brand">
        <div className="login-wordmark">
          AKOP<span className="login-accent" aria-hidden="true" />
        </div>
        <p>Vatandaş bildirimlerini tek yerden yönetin.</p>
      </div>

      <form className="login-card" onSubmit={handleSubmit} noValidate>
        <h1>Kurum girişi</h1>
        <p className="login-lead">Hesabınızla oturum açın.</p>

        <label htmlFor="email">E-posta</label>
        <input
          id="email"
          type="email"
          autoComplete="username"
          placeholder="ornek@kurum.gov.tr"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          aria-invalid={!!errors.email}
          aria-describedby={errors.email ? 'email-error' : undefined}
        />
        {errors.email && <span id="email-error" className="login-error">{errors.email}</span>}

        <label htmlFor="password">Şifre</label>
        <div className="login-password">
          <input
            id="password"
            type={showPassword ? 'text' : 'password'}
            autoComplete="current-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            aria-invalid={!!errors.password}
            aria-describedby={errors.password ? 'password-error' : undefined}
          />
          <button
            type="button"
            className="login-toggle"
            aria-label={showPassword ? 'Şifreyi gizle' : 'Şifreyi göster'}
            onClick={() => setShowPassword((v) => !v)}
          >
            <EyeIcon off={showPassword} />
          </button>
        </div>
        {errors.password && <span id="password-error" className="login-error">{errors.password}</span>}

        {formError && <p className="login-form-error" role="alert">{formError}</p>}

        <button type="submit" className="login-submit" disabled={busy}>
          {busy ? 'Giriş yapılıyor…' : 'Giriş yap'}
        </button>

        <p className="login-footnote">
          Hesabınız yok mu? Kurum hesapları sistem yöneticisi tarafından oluşturulur.
        </p>
      </form>
    </main>
  )
}
