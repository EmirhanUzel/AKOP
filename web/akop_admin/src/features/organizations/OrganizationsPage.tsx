import { useCallback, useEffect, useState, type SubmitEvent } from 'react'
import { ApiError, INSTITUTION_API, request } from '../../core/api/http'
import './OrganizationsPage.css'

type Organization = {
  id: string
  name: string
  organizationTypeName: string
  city: string
  profileInfo: string | null
  createdAt: string
}
type OrganizationType = { id: number; name: string }
type Errors = { name?: string; type?: string; city?: string }

export default function OrganizationsPage({ token, onSignOut }: { token: string; onSignOut: () => void }) {
  const [organizations, setOrganizations] = useState<Organization[]>([])
  const [types, setTypes] = useState<OrganizationType[]>([])
  const [loading, setLoading] = useState(true)
  const [loadError, setLoadError] = useState('')

  const [name, setName] = useState('')
  const [typeId, setTypeId] = useState('')
  const [city, setCity] = useState('')
  const [profileInfo, setProfileInfo] = useState('')
  const [errors, setErrors] = useState<Errors>({})
  const [formError, setFormError] = useState('')
  const [saving, setSaving] = useState(false)

  const [newType, setNewType] = useState('')
  const [typeError, setTypeError] = useState('')

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
    Promise.all([
      request<Organization[]>(`${INSTITUTION_API}/Organizations`, {}, token),
      request<OrganizationType[]>(`${INSTITUTION_API}/OrganizationTypes`, {}, token),
    ])
      .then(([orgs, orgTypes]) => {
        if (!active) return
        setOrganizations(orgs)
        setTypes(orgTypes)
      })
      .catch((err) => active && setLoadError(messageOf(err)))
      .finally(() => active && setLoading(false))
    return () => {
      active = false
    }
  }, [token, messageOf])

  async function addOrganization(e: SubmitEvent<HTMLFormElement>) {
    e.preventDefault()
    const next: Errors = {}
    if (!name.trim()) next.name = 'Kurum adı zorunludur.'
    if (!typeId) next.type = 'Kurum türü seçin.'
    if (!city.trim()) next.city = 'Şehir zorunludur.'
    setErrors(next)
    setFormError('')
    if (next.name || next.type || next.city) return

    setSaving(true)
    try {
      const created = await request<Organization>(
        `${INSTITUTION_API}/Organizations`,
        {
          method: 'POST',
          body: JSON.stringify({
            name,
            organizationTypeId: Number(typeId),
            city,
            profileInfo: profileInfo || null,
          }),
        },
        token,
      )
      setOrganizations((list) => [created, ...list])
      setName('')
      setCity('')
      setProfileInfo('')
    } catch (err) {
      setFormError(messageOf(err))
    } finally {
      setSaving(false)
    }
  }

  async function addType() {
    if (!newType.trim()) return
    setTypeError('')
    try {
      const created = await request<OrganizationType>(
        `${INSTITUTION_API}/OrganizationTypes`,
        { method: 'POST', body: JSON.stringify({ name: newType }) },
        token,
      )
      setTypes((list) => [...list, created])
      setTypeId(String(created.id))
      setNewType('')
    } catch (err) {
      setTypeError(messageOf(err))
    }
  }

  return (
    <div className="org-page">
      <header className="org-topbar">
        <div className="org-wordmark">
          AKOP<span className="org-accent" aria-hidden="true" />
        </div>
        <button type="button" className="org-signout" onClick={onSignOut}>Çıkış yap</button>
      </header>

      <main className="org-main">
        <h1>Kurumlar</h1>

        <section className="org-card" aria-labelledby="add-title">
          <h2 id="add-title">Kurum ekle</h2>
          <form className="org-form" onSubmit={addOrganization} noValidate>
            <div className="org-field">
              <label htmlFor="org-name">Kurum adı</label>
              <input id="org-name" value={name} onChange={(e) => setName(e.target.value)} aria-invalid={!!errors.name} />
              {errors.name && <span className="org-error">{errors.name}</span>}
            </div>

            <div className="org-field">
              <label htmlFor="org-city">Şehir</label>
              <input id="org-city" value={city} onChange={(e) => setCity(e.target.value)} aria-invalid={!!errors.city} />
              {errors.city && <span className="org-error">{errors.city}</span>}
            </div>

            <div className="org-field">
              <label htmlFor="org-type">Kurum türü</label>
              <select id="org-type" value={typeId} onChange={(e) => setTypeId(e.target.value)} aria-invalid={!!errors.type}>
                <option value="">Seçin</option>
                {types.map((t) => (
                  <option key={t.id} value={t.id}>{t.name}</option>
                ))}
              </select>
              {errors.type && <span className="org-error">{errors.type}</span>}
              <div className="org-inline">
                <input
                  aria-label="Yeni kurum türü adı"
                  placeholder={types.length ? 'Listede yok mu? Yeni tür' : 'İlk kurum türünü ekleyin'}
                  value={newType}
                  onChange={(e) => setNewType(e.target.value)}
                />
                <button type="button" className="org-secondary" onClick={addType}>Tür ekle</button>
              </div>
              {typeError && <span className="org-error">{typeError}</span>}
            </div>

            <div className="org-field">
              <label htmlFor="org-profile">Profil bilgisi (isteğe bağlı)</label>
              <textarea id="org-profile" rows={3} maxLength={1000} value={profileInfo} onChange={(e) => setProfileInfo(e.target.value)} />
            </div>

            {formError && <p className="org-form-error" role="alert">{formError}</p>}
            <button type="submit" className="org-primary" disabled={saving}>
              {saving ? 'Ekleniyor…' : 'Kurum ekle'}
            </button>
          </form>
        </section>

        <section className="org-card" aria-labelledby="list-title">
          <h2 id="list-title">Kayıtlı kurumlar</h2>
          {loading && <p className="org-note">Yükleniyor…</p>}
          {loadError && <p className="org-form-error" role="alert">{loadError}</p>}
          {!loading && !loadError && organizations.length === 0 && (
            <p className="org-note">Henüz kurum eklenmemiş.</p>
          )}
          {organizations.length > 0 && (
            <div className="org-table-wrap">
              <table className="org-table">
                <thead>
                  <tr>
                    <th>Kurum</th>
                    <th>Tür</th>
                    <th>Şehir</th>
                    <th>Eklenme</th>
                  </tr>
                </thead>
                <tbody>
                  {organizations.map((o) => (
                    <tr key={o.id}>
                      <td>
                        {o.name}
                        {o.profileInfo && <div className="org-sub">{o.profileInfo}</div>}
                      </td>
                      <td>{o.organizationTypeName}</td>
                      <td>{o.city}</td>
                      <td>{new Date(o.createdAt).toLocaleDateString('tr-TR')}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </main>
    </div>
  )
}
