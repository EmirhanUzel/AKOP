import { useState, type SubmitEvent } from 'react'
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

export default function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [errors, setErrors] = useState<Errors>({})

  function handleSubmit(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault()
    const next: Errors = {}
    if (!email.trim()) next.email = 'E-posta zorunludur.'
    if (!password) next.password = 'Şifre zorunludur.'
    setErrors(next)
    // shortcut: backend bağlantısı yok, geçerli form şimdilik bir şey yapmaz; /api/Auth/login bağlanınca burada çağrılır
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

        <button type="submit" className="login-submit">Giriş yap</button>

        <p className="login-footnote">
          Hesabınız yok mu? Kurum hesapları sistem yöneticisi tarafından oluşturulur.
        </p>
      </form>
    </main>
  )
}
