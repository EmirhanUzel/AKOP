import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { beforeEach, describe, expect, it } from 'vitest'
import App from './App'
import { mockFetch } from './test/mockFetch'

const ORGS = 'GET /institution/api/Organizations'
const TYPES = 'GET /institution/api/OrganizationTypes'
const NEW_TYPE = 'POST /institution/api/OrganizationTypes'
const LOGIN = 'POST /identity/api/Auth/login'

const types = [{ id: 1, name: 'Belediye' }, { id: 2, name: 'Su İdaresi' }]
const orgs = [
  { id: 'o1', name: 'Çankaya Belediyesi', organizationTypeName: 'Belediye', city: 'Ankara', profileInfo: null, createdAt: '2026-10-29T10:00:00Z' },
]

function signedIn(token = 'tok') {
  sessionStorage.setItem('akop_session', JSON.stringify({ token, role: 'SystemAdmin' }))
}

beforeEach(() => window.history.pushState({}, '', '/admin'))

const heading = () => screen.getByRole('heading', { level: 1 })

describe('giriş akışı', () => {
  it('sistem yöneticisi /admin üzerinden girince kurumlar ekranı açılır ve oturum saklanır', async () => {
    mockFetch({ [LOGIN]: { json: { accessToken: 'yeni', role: 'SystemAdmin' } }, [ORGS]: { json: orgs }, [TYPES]: { json: types } })
    render(<App />)
    fireEvent.change(screen.getByLabelText('E-posta'), { target: { value: 'admin@akop.test' } })
    fireEvent.change(screen.getByLabelText('Şifre'), { target: { value: 'Gizli123!' } })
    fireEvent.click(screen.getByRole('button', { name: 'Giriş yap' }))

    expect(await screen.findByText('Çankaya Belediyesi')).toBeTruthy()
    expect(heading().textContent).toBe('Kurumlar')
    expect(JSON.parse(sessionStorage.getItem('akop_session')!)).toEqual({ token: 'yeni', role: 'SystemAdmin' })
  })
})

describe('sayfa yenileme ve çıkış', () => {
  it('kayıtlı oturum varsa yenilemede giriş sayfası yerine panel açılır, token istekte gider', async () => {
    signedIn('kayitli-token')
    const fetchMock = mockFetch({ [ORGS]: { json: orgs }, [TYPES]: { json: types } })
    render(<App />)

    expect(await screen.findByText('Çankaya Belediyesi')).toBeTruthy()
    expect(screen.queryByText('Sistem yöneticisi girişi')).toBeNull()
    const headers = fetchMock.mock.calls[0][1]!.headers as Headers
    expect(headers.get('Authorization')).toBe('Bearer kayitli-token')
  })

  it('Çıkış yap oturumu siler ve giriş sayfasına döner', async () => {
    signedIn()
    mockFetch({ [ORGS]: { json: orgs }, [TYPES]: { json: types } })
    render(<App />)
    await screen.findByText('Çankaya Belediyesi')

    fireEvent.click(screen.getByRole('button', { name: 'Çıkış yap' }))
    expect(screen.getByRole('heading', { name: 'Sistem yöneticisi girişi' })).toBeTruthy()
    expect(sessionStorage.getItem('akop_session')).toBeNull()
  })

  it('geçersiz tokenda (401) otomatik olarak girişe döner', async () => {
    signedIn('suresi-dolmus')
    mockFetch({ [ORGS]: { status: 401 }, [TYPES]: { status: 401 } })
    render(<App />)

    expect(await screen.findByRole('heading', { name: 'Sistem yöneticisi girişi' })).toBeTruthy()
    expect(sessionStorage.getItem('akop_session')).toBeNull()
  })
})

describe('Kurumlar / Kurum türleri geçişi', () => {
  it('sekmeler arasında geçer, aktif sekmeyi işaretler', async () => {
    signedIn()
    mockFetch({ [ORGS]: { json: orgs }, [TYPES]: { json: types } })
    render(<App />)
    await screen.findByText('Çankaya Belediyesi')

    const nav = within(screen.getByRole('navigation', { name: 'Yönetim bölümleri' }))
    expect(nav.getByRole('button', { name: 'Kurumlar' }).getAttribute('aria-current')).toBe('page')

    fireEvent.click(nav.getByRole('button', { name: 'Kurum türleri' }))
    expect(heading().textContent).toBe('Kurum türleri')
    expect(await screen.findByText('Su İdaresi')).toBeTruthy()
    expect(nav.getByRole('button', { name: 'Kurum türleri' }).getAttribute('aria-current')).toBe('page')

    fireEvent.click(nav.getByRole('button', { name: 'Kurumlar' }))
    expect(heading().textContent).toBe('Kurumlar')
    expect(await screen.findByText('Çankaya Belediyesi')).toBeTruthy()
  })

  it('türler sayfasında yeni tür eklenir ve listeye düşer', async () => {
    signedIn()
    const fetchMock = mockFetch({
      [ORGS]: { json: orgs },
      [TYPES]: { json: types },
      [NEW_TYPE]: { status: 201, json: { id: 3, name: 'Elektrik' } },
    })
    render(<App />)
    fireEvent.click(await screen.findByRole('button', { name: 'Kurum türleri' }))
    await screen.findByText('Su İdaresi')

    fireEvent.change(screen.getByLabelText('Tür adı'), { target: { value: 'Elektrik' } })
    fireEvent.click(screen.getByRole('button', { name: 'Tür ekle' }))

    expect(await screen.findByText('Elektrik')).toBeTruthy()
    const post = fetchMock.mock.calls.find(([, init]) => init?.method === 'POST')!
    expect(JSON.parse(post[1]!.body as string)).toEqual({ name: 'Elektrik' })
  })

  it('aynı tür tekrar eklenirse sunucu mesajını gösterir, boş ad istek atmaz', async () => {
    signedIn()
    mockFetch({
      [ORGS]: { json: orgs },
      [TYPES]: { json: types },
      [NEW_TYPE]: { status: 409, text: 'Bu isimde bir kurum türü zaten mevcut' },
    })
    render(<App />)
    fireEvent.click(await screen.findByRole('button', { name: 'Kurum türleri' }))
    await screen.findByText('Su İdaresi')

    fireEvent.click(screen.getByRole('button', { name: 'Tür ekle' }))
    expect(screen.getByText('Tür adı zorunludur.')).toBeTruthy()

    fireEvent.change(screen.getByLabelText('Tür adı'), { target: { value: 'Belediye' } })
    fireEvent.click(screen.getByRole('button', { name: 'Tür ekle' }))
    await waitFor(() => expect(screen.getByRole('alert').textContent).toBe('Bu isimde bir kurum türü zaten mevcut'))
  })
})

describe('iki ayrı giriş', () => {
  const ORG_ME = 'GET /institution/api/Organizations/me'
  const myOrg = { name: 'ASKİ', organizationTypeName: 'Su İdaresi', city: 'Ankara', profileInfo: 'Su işleri', createdAt: '2026-10-30T10:00:00Z' }

  it('ana adres kurum girişidir, admin paneli açılmaz', () => {
    window.history.pushState({}, '', '/')
    render(<App />)
    expect(screen.getByRole('heading', { name: 'Kurum girişi' })).toBeTruthy()
  })

  it('/admin adresi sistem yöneticisi girişidir', () => {
    render(<App />)
    expect(screen.getByRole('heading', { name: 'Sistem yöneticisi girişi' })).toBeTruthy()
  })

  it('kurum yöneticisi ana adresten girince kendi kurum bilgilerini görür', async () => {
    window.history.pushState({}, '', '/')
    mockFetch({ [LOGIN]: { json: { accessToken: 'ktok', role: 'OrgManager' } }, [ORG_ME]: { json: myOrg } })
    render(<App />)
    fireEvent.change(screen.getByLabelText('E-posta'), { target: { value: 'mudur@akop.test' } })
    fireEvent.change(screen.getByLabelText('Şifre'), { target: { value: 'Gizli123!' } })
    fireEvent.click(screen.getByRole('button', { name: 'Giriş yap' }))

    expect(await screen.findByText('Su İdaresi')).toBeTruthy()
    expect(heading().textContent).toBe('Kurumum')
    expect(screen.getByText('ASKİ')).toBeTruthy()
    expect(screen.queryByRole('navigation', { name: 'Yönetim bölümleri' })).toBeNull()
  })

  it('kayıtlı sistem yöneticisi oturumu ana adreste geçerli sayılmaz', () => {
    window.history.pushState({}, '', '/')
    signedIn()
    render(<App />)
    expect(screen.getByRole('heading', { name: 'Kurum girişi' })).toBeTruthy()
  })

  it('kayıtlı kurum yöneticisi oturumu /admin adresinde geçerli sayılmaz', () => {
    sessionStorage.setItem('akop_session', JSON.stringify({ token: 'ktok', role: 'OrgManager' }))
    render(<App />)
    expect(screen.getByRole('heading', { name: 'Sistem yöneticisi girişi' })).toBeTruthy()
  })

  it('kurum sayfasında çıkış yapınca giriş sayfasına döner, kurum bilgisi 401 verirse de', async () => {
    window.history.pushState({}, '', '/')
    sessionStorage.setItem('akop_session', JSON.stringify({ token: 'ktok', role: 'OrgManager' }))
    mockFetch({ [ORG_ME]: { json: myOrg } })
    render(<App />)
    await screen.findByText('ASKİ')
    fireEvent.click(screen.getByRole('button', { name: 'Çıkış yap' }))
    expect(screen.getByRole('heading', { name: 'Kurum girişi' })).toBeTruthy()
    expect(sessionStorage.getItem('akop_session')).toBeNull()
  })
})
