import { useEffect, useMemo, useRef, useState } from 'react'
import { fetchPool, POOL_IS_SAMPLE, relativeTime, STATUS_LABEL, type PoolReport, type PoolStatus } from './pool'
import './PoolPage.css'

/** Kurumun ihbar havuzu: tüm ihbarlar, kuruma ait olabilecekler için bildirim ve ayrıntı paneli. */
export default function PoolPage() {
  const [reports, setReports] = useState<PoolReport[] | null>(null)
  const [error, setError] = useState('')
  const [onlyRelevant, setOnlyRelevant] = useState(false)
  const [category, setCategory] = useState('')
  const [status, setStatus] = useState<PoolStatus | ''>('')
  const [query, setQuery] = useState('')
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [seen, setSeen] = useState<Set<string>>(new Set())

  useEffect(() => {
    let active = true
    fetchPool()
      .then((list) => active && setReports(list))
      .catch(() => active && setError('İhbarlar yüklenemedi.'))
    return () => {
      active = false
    }
  }, [])

  const categories = useMemo(() => {
    const map = new Map<string, string>()
    for (const r of reports ?? []) map.set(r.categoryCode, r.categoryName)
    return [...map]
  }, [reports])

  const shown = useMemo(() => {
    const q = query.trim().toLocaleLowerCase('tr')
    return (reports ?? [])
      .filter((r) => !onlyRelevant || r.relevant)
      .filter((r) => !category || r.categoryCode === category)
      .filter((r) => !status || r.status === status)
      .filter((r) => !q || `${r.title} ${r.description} ${r.locationText} ${r.district ?? ''}`.toLocaleLowerCase('tr').includes(q))
  }, [reports, onlyRelevant, category, status, query])

  const unseen = (reports ?? []).filter((r) => r.relevant && r.status === 'Pending' && !seen.has(r.id))
  const selected = reports?.find((r) => r.id === selectedId) ?? null

  function open(r: PoolReport) {
    setSelectedId(r.id)
    setSeen((s) => new Set(s).add(r.id))
  }

  return (
    <>
      {POOL_IS_SAMPLE && (
        <p className="pool-sample" role="note">
          Örnek veri gösteriliyor. İhbar havuzu servisi hazır olduğunda gerçek ihbarlar burada görünecek.
        </p>
      )}

      {unseen.length > 0 && (
        <div className="pool-alert" role="status">
          <span className="pool-alert-dot" aria-hidden="true" />
          <p>
            <strong>{unseen.length} yeni ihbar</strong> kurumunuzla ilgili olabilir.
          </p>
          <button type="button" onClick={() => setOnlyRelevant(true)}>Göster</button>
        </div>
      )}

      <section className="org-card" aria-labelledby="pool-title">
        <h2 id="pool-title">İhbar havuzu</h2>

        <div className="pool-filters">
          <input
            type="search"
            aria-label="İhbarlarda ara"
            placeholder="Başlık, açıklama ya da konum ara"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          <select aria-label="Kategori" value={category} onChange={(e) => setCategory(e.target.value)}>
            <option value="">Tüm kategoriler</option>
            {categories.map(([code, name]) => (
              <option key={code} value={code}>{name}</option>
            ))}
          </select>
          <select aria-label="Durum" value={status} onChange={(e) => setStatus(e.target.value as PoolStatus | '')}>
            <option value="">Tüm durumlar</option>
            {Object.entries(STATUS_LABEL).map(([value, label]) => (
              <option key={value} value={value}>{label}</option>
            ))}
          </select>
          <label className="pool-toggle">
            <input type="checkbox" checked={onlyRelevant} onChange={(e) => setOnlyRelevant(e.target.checked)} />
            Yalnızca kurumumla ilgili olabilecekler
          </label>
        </div>

        {error && <p className="org-form-error" role="alert">{error}</p>}
        {!reports && !error && <p className="org-note">Yükleniyor…</p>}
        {reports && shown.length === 0 && <p className="org-note">Bu filtrelere uyan ihbar yok.</p>}

        <ul className="pool-list">
          {shown.map((r) => (
            <li key={r.id}>
              <button
                type="button"
                className="pool-item"
                aria-current={r.id === selectedId ? 'true' : undefined}
                onClick={() => open(r)}
              >
                <span className="pool-item-head">
                  <span className="pool-item-title">{r.title}</span>
                  <span className={`pool-status pool-status-${r.status}`}>{STATUS_LABEL[r.status]}</span>
                </span>
                <span className="pool-item-meta">
                  {r.categoryName} · {r.district ? `${r.district}, ` : ''}{r.city} · {relativeTime(r.createdAt)}
                </span>
                {r.relevant && <span className="pool-relevant">Kurumunuzla ilgili olabilir</span>}
              </button>
            </li>
          ))}
        </ul>
      </section>

      {selected && <ReportDetail report={selected} onClose={() => setSelectedId(null)} />}
    </>
  )
}

function ReportDetail({ report: r, onClose }: { report: PoolReport; onClose: () => void }) {
  const ref = useRef<HTMLElement>(null)
  // Ayrıntı listenin altında açılır; görünür alana kaydırılır (jsdom'da scrollIntoView yok)
  useEffect(() => {
    ref.current?.scrollIntoView?.({ behavior: 'smooth', block: 'start' })
  }, [r.id])

  return (
    <section ref={ref} className="org-card pool-detail" aria-labelledby="pool-detail-title">
      <div className="pool-detail-head">
        <h2 id="pool-detail-title">{r.title}</h2>
        <button type="button" className="org-secondary" onClick={onClose}>Kapat</button>
      </div>

      {r.imageUrls.length > 0 ? (
        <div className="pool-photos" aria-label="İhbar fotoğrafları" tabIndex={0}>
          {r.imageUrls.map((url, i) => (
            <img key={url} src={url} alt={`Fotoğraf ${i + 1}`} />
          ))}
        </div>
      ) : (
        <p className="pool-no-photo">Bu ihbarın fotoğrafı yok.</p>
      )}

      {r.relevant && r.relevanceReason && (
        <p className="pool-reason">Neden size gösteriliyor: {r.relevanceReason}</p>
      )}

      <dl className="kurum-info">
        <dt>Durum</dt>
        <dd>{STATUS_LABEL[r.status]}</dd>
        <dt>Kategori</dt>
        <dd>{r.subcategoryName ? `${r.categoryName} · ${r.subcategoryName}` : r.categoryName}</dd>
        <dt>Konum</dt>
        <dd>{r.locationText}, {r.district ? `${r.district}, ` : ''}{r.city}</dd>
        <dt>Bildirilme</dt>
        <dd>{new Date(r.createdAt).toLocaleString('tr-TR')} ({relativeTime(r.createdAt)})</dd>
        <dt>Açıklama</dt>
        <dd>{r.description}</dd>
      </dl>
    </section>
  )
}
