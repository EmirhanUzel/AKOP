import { useState, type SubmitEvent } from 'react'
import { IDENTITY_API, request } from '../../core/api/http'

type Props = {
  token: string
  organization: { id: string; name: string }
  toMessage: (err: unknown) => string
  onDone: () => void
  onCancel: () => void
}

type Errors = { firstName?: string; lastName?: string; email?: string; password?: string }

export default function ManagerForm({ token, organization, toMessage, onDone, onCancel }: Props) {
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [errors, setErrors] = useState<Errors>({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  async function submit(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault()
    const next: Errors = {}
    if (!firstName.trim()) next.firstName = 'Ad zorunludur.'
    if (!lastName.trim()) next.lastName = 'Soyad zorunludur.'
    if (!email.trim()) next.email = 'E-posta zorunludur.'
    if (!password) next.password = 'Şifre zorunludur.'
    setErrors(next)
    setFormError('')
    if (Object.keys(next).length) return

    setSaving(true)
    try {
      await request(
        `${IDENTITY_API}/Users/institution`,
        {
          method: 'POST',
          body: JSON.stringify({
            firstName,
            lastName,
            email,
            password,
            institutionId: organization.id,
            role: 'OrgManager',
          }),
        },
        token,
      )
      onDone()
    } catch (err) {
      setFormError(toMessage(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <section className="org-card" aria-labelledby="manager-title">
      <h2 id="manager-title">Yönetici ekle: {organization.name}</h2>
      <form className="org-form" onSubmit={submit} noValidate>
        <div className="org-field">
          <label htmlFor="mgr-first">Ad</label>
          <input id="mgr-first" value={firstName} onChange={(e) => setFirstName(e.target.value)} aria-invalid={!!errors.firstName} />
          {errors.firstName && <span className="org-error">{errors.firstName}</span>}
        </div>

        <div className="org-field">
          <label htmlFor="mgr-last">Soyad</label>
          <input id="mgr-last" value={lastName} onChange={(e) => setLastName(e.target.value)} aria-invalid={!!errors.lastName} />
          {errors.lastName && <span className="org-error">{errors.lastName}</span>}
        </div>

        <div className="org-field">
          <label htmlFor="mgr-email">E-posta</label>
          <input id="mgr-email" type="email" autoComplete="off" value={email} onChange={(e) => setEmail(e.target.value)} aria-invalid={!!errors.email} />
          {errors.email && <span className="org-error">{errors.email}</span>}
        </div>

        <div className="org-field">
          <label htmlFor="mgr-password">Geçici şifre</label>
          <input id="mgr-password" type="password" autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} aria-invalid={!!errors.password} />
          {errors.password ? (
            <span className="org-error">{errors.password}</span>
          ) : (
            <span className="org-note">En az 6 karakter; büyük harf, küçük harf ve özel karakter içermeli.</span>
          )}
        </div>

        {formError && <p className="org-form-error" role="alert">{formError}</p>}
        <div className="org-actions">
          <button type="submit" className="org-primary" disabled={saving}>
            {saving ? 'Ekleniyor…' : 'Yönetici ekle'}
          </button>
          <button type="button" className="org-secondary" onClick={onCancel}>Vazgeç</button>
        </div>
      </form>
    </section>
  )
}
