import { useCallback, useEffect, useState, type SubmitEvent } from 'react'
import { ApiError, INSTITUTION_API, request } from '../../core/api/http'
import './OrganizationsPage.css'

type OrganizationType = { id: number; name: string }

export default function OrganizationTypesPage({ token, onSignOut }: { token: string; onSignOut: () => void }) {
  const [types, setTypes] = useState<OrganizationType[]>([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')

  const [name, setName] = useState('')
  const [nameError, setNameError] = useState('')
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  // Süresi dolan ya da geçersiz token: girişe dön
  const messageOf = useCallback(
    (err: unknown) => {
      if (err instanceof ApiError && err.status === 401) onSignOut()
      return err instanceof Error ? err.message : 'Bir hata oluştu.'
    },
    [onSignOut],
  )

  useEffect(() => {
    let active = true
    request<OrganizationType[]>(`${INSTITUTION_API}/OrganizationTypes`, {}, token)
      .then((list) => active && setTypes(list))
      .catch((err) => active && setLoadError(messageOf(err)))
      .finally(() => active && setLoading(false))
    return () => {
      active = false
    }
  }, [token, messageOf])

  async function addType(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault()
    setFormError('')
    if (!name.trim()) {
      setNameError('Tür adı zorunludur.')
      return
    }
    setNameError('')

    setSaving(true)
    try {
      const created = await request<OrganizationType>(
        `${INSTITUTION_API}/OrganizationTypes`,
        { method: 'POST', body: JSON.stringify({ name }) },
        token,
      )
      setTypes((list) => [...list, created])
      setName('')
    } catch (err) {
      setFormError(messageOf(err))
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <section className="org-card" aria-labelledby="type-add-title">
        <h2 id="type-add-title">Kurum türü ekle</h2>
        <form className="org-form" onSubmit={addType} noValidate>
          <div className="org-field">
            <label htmlFor="type-name">Tür adı</label>
            <input id="type-name" value={name} onChange={(e) => setName(e.target.value)} aria-invalid={!!nameError} />
            {nameError && <span className="org-error">{nameError}</span>}
          </div>

          {formError && <p className="org-form-error" role="alert">{formError}</p>}
          <button type="submit" className="org-primary" disabled={saving}>
            {saving ? 'Ekleniyor…' : 'Tür ekle'}
          </button>
        </form>
      </section>

      <section className="org-card" aria-labelledby="type-list-title">
        <h2 id="type-list-title">Kayıtlı türler</h2>
        {loading && <p className="org-note">Yükleniyor…</p>}
        {loadError && <p className="org-form-error" role="alert">{loadError}</p>}
        {!loading && !loadError && types.length === 0 && <p className="org-note">Henüz kurum türü eklenmemiş.</p>}
        {types.length > 0 && (
          <ul className="org-type-list">
            {types.map((t) => (
              <li key={t.id}>{t.name}</li>
            ))}
          </ul>
        )}
      </section>
    </>
  )
}
