import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
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

const heading = () => screen.getByRole('heading', { level: 1 })

describe('giriş akışı', () => {
  it('SystemAdmin girince kurumlar ekranı açılır ve oturum saklanır', async () => {
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
    expect(screen.queryByText('Kurum girişi')).toBeNull()
    const headers = fetchMock.mock.calls[0][1]!.headers as Headers
    expect(headers.get('Authorization')).toBe('Bearer kayitli-token')
  })

  it('Çıkış yap oturumu siler ve giriş sayfasına döner', async () => {
    signedIn()
    mockFetch({ [ORGS]: { json: orgs }, [TYPES]: { json: types } })
    render(<App />)
    await screen.findByText('Çankaya Belediyesi')

    fireEvent.click(screen.getByRole('button', { name: 'Çıkış yap' }))
    expect(screen.getByText('Kurum girişi')).toBeTruthy()
    expect(sessionStorage.getItem('akop_session')).toBeNull()
  })

  it('geçersiz tokenda (401) otomatik olarak girişe döner', async () => {
    signedIn('suresi-dolmus')
    mockFetch({ [ORGS]: { status: 401 }, [TYPES]: { status: 401 } })
    render(<App />)

    expect(await screen.findByText('Kurum girişi')).toBeTruthy()
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
