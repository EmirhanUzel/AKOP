import { useEffect, useState } from 'react'
import { ApiError, INSTITUTION_API, request } from '../../core/api/http'
import AdminLayout from '../../shared/components/AdminLayout'
import PoolPage from './PoolPage'
import '../organizations/OrganizationsPage.css'
import './KurumPage.css'

type Organization = {
  name: string
  organizationTypeName: string
  city: string
  district: string | null
  profileInfo: string | null
  createdAt: string
}

type KurumTab = 'pool' | 'org'

const TABS: { id: KurumTab; label: string }[] = [
  { id: 'pool', label: 'İhbar havuzu' },
  { id: 'org', label: 'Kurumum' },
]

/** Kurum paneli: ihbar havuzu ve kurum bilgileri (GET /api/Organizations/me). */
export default function KurumPage({ token, onSignOut }: { token: string; onSignOut: () => void }) {
  const [org, setOrg] = useState<Organization | null>(null)
  const [error, setError] = useState('')
  const [tab, setTab] = useState<KurumTab>('pool')

  useEffect(() => {
    let active = true
    request<Organization>(`${INSTITUTION_API}/Organizations/me`, {}, token)
      .then((o) => active && setOrg(o))
      .catch((err) => {
        if (!active) return
        if (err instanceof ApiError && err.status === 401) onSignOut()
        setError(err instanceof Error ? err.message : 'Bir hata oluştu.')
      })
    return () => {
      active = false
    }
  }, [token, onSignOut])

  return (
    <AdminLayout
      pages={TABS}
      page={tab}
      onNavigate={setTab}
      onSignOut={onSignOut}
      title={tab === 'pool' ? org?.name ?? 'İhbar havuzu' : 'Kurumum'}
    >
      {tab === 'pool' ? <PoolPage /> : <section className="org-card" aria-labelledby="kurum-title">
        <h2 id="kurum-title">Kurum bilgileri</h2>
        {error && <p className="org-form-error" role="alert">{error}</p>}
        {!org && !error && <p className="org-note">Yükleniyor…</p>}
        {org && (
          <dl className="kurum-info">
            <dt>Kurum adı</dt>
            <dd>{org.name}</dd>
            <dt>Tür</dt>
            <dd>{org.organizationTypeName}</dd>
            <dt>Şehir</dt>
            <dd>{org.city}</dd>
            {org.district && (
              <>
                <dt>İlçe</dt>
                <dd>{org.district}</dd>
              </>
            )}
            {org.profileInfo && (
              <>
                <dt>Profil bilgisi</dt>
                <dd>{org.profileInfo}</dd>
              </>
            )}
            <dt>Eklenme tarihi</dt>
            <dd>{new Date(org.createdAt).toLocaleDateString('tr-TR')}</dd>
          </dl>
        )}
      </section>}
    </AdminLayout>
  )
}
