import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { mockFetch } from '../../test/mockFetch'
import OrganizationsPage from './OrganizationsPage'

const ORGS = 'GET /institution/api/Organizations'
const TYPES = 'GET /institution/api/OrganizationTypes'
const NEW_ORG = 'POST /institution/api/Organizations'
const NEW_MANAGER = 'POST /identity/api/Users/institution'

const types = [{ id: 1, name: 'Belediye' }, { id: 2, name: 'Su İdaresi' }]
const orgs = [
  { id: 'org-1', name: 'Çankaya Belediyesi', organizationTypeName: 'Belediye', city: 'Ankara', profileInfo: null, createdAt: '2026-10-29T10:00:00Z' },
  { id: 'org-2', name: 'ASKİ', organizationTypeName: 'Su İdaresi', city: 'Ankara', profileInfo: 'Su işleri', createdAt: '2026-10-30T10:00:00Z' },
]

async function renderPage(extra: Parameters<typeof mockFetch>[0] = {}) {
  const fetchMock = mockFetch({ [ORGS]: { json: orgs }, [TYPES]: { json: types }, ...extra })
  const onSignOut = vi.fn()
  render(<OrganizationsPage token="tok" onSignOut={onSignOut} />)
  await screen.findByText('Çankaya Belediyesi')
  return { fetchMock, onSignOut }
}

function openManagerForm(orgName: string) {
  const row = screen.getByText(orgName).closest('tr')!
  fireEvent.click(within(row).getByRole('button', { name: 'Yönetici ekle' }))
}

function fillManager(values: { first?: string; last?: string; email?: string; password?: string }) {
  const set = (label: string, value = '') => fireEvent.change(screen.getByLabelText(label), { target: { value } })
  set('Ad', values.first)
  set('Soyad', values.last)
  set('E-posta', values.email)
  set('Geçici şifre', values.password)
}

const submitManager = () => fireEvent.click(screen.getAllByRole('button', { name: 'Yönetici ekle' }).find((b) => (b as HTMLButtonElement).type === 'submit')!)

describe('kurum yöneticisi ekleme', () => {
  it('satırdaki butona basınca o kurumun formu açılır, başka kuruma geçince form temizlenir', async () => {
    await renderPage()
    openManagerForm('Çankaya Belediyesi')
    expect(screen.getByRole('heading', { name: 'Yönetici ekle: Çankaya Belediyesi' })).toBeTruthy()
    fireEvent.change(screen.getByLabelText('Ad'), { target: { value: 'Ayşe' } })

    openManagerForm('ASKİ')
    expect(screen.getByRole('heading', { name: 'Yönetici ekle: ASKİ' })).toBeTruthy()
    expect((screen.getByLabelText('Ad') as HTMLInputElement).value).toBe('')
  })

  it('Vazgeç formu kapatır', async () => {
    await renderPage()
    openManagerForm('ASKİ')
    fireEvent.click(screen.getByRole('button', { name: 'Vazgeç' }))
    expect(screen.queryByLabelText('Geçici şifre')).toBeNull()
  })

  it('boş formda dört alan hatasını gösterir ve istek atmaz', async () => {
    const { fetchMock } = await renderPage()
    openManagerForm('ASKİ')
    submitManager()
    for (const text of ['Ad zorunludur.', 'Soyad zorunludur.', 'E-posta zorunludur.', 'Şifre zorunludur.']) {
      expect(screen.getByText(text)).toBeTruthy()
    }
    expect(fetchMock.mock.calls.some(([, init]) => init?.method === 'POST')).toBe(false)
  })

  it('doğru gövdeyi gönderir (OrgManager rolü, satırdaki kurumun kimliği) ve başarı uyarısı gösterir', async () => {
    const { fetchMock } = await renderPage({ [NEW_MANAGER]: { status: 201, text: 'Kurum kullanıcısı oluşturuldu.' } })
    openManagerForm('ASKİ')
    fillManager({ first: 'Ayşe', last: 'Demir', email: 'ayse@aski.test', password: 'Gizli123!' })
    submitManager()

    expect((await screen.findByRole('status')).textContent).toBe('ASKİ için yönetici hesabı oluşturuldu.')
    expect(screen.queryByLabelText('Geçici şifre')).toBeNull()
    const call = fetchMock.mock.calls.find(([url]) => url === '/identity/api/Users/institution')!
    expect(JSON.parse(call[1]!.body as string)).toEqual({
      firstName: 'Ayşe',
      lastName: 'Demir',
      email: 'ayse@aski.test',
      password: 'Gizli123!',
      institutionId: 'org-2',
      role: 'OrgManager',
    })
    expect((call[1]!.headers as Headers).get('Authorization')).toBe('Bearer tok')
  })

  it('Identity hata dizisini tek mesaj olarak gösterir ve formu açık bırakır', async () => {
    await renderPage({
      [NEW_MANAGER]: {
        status: 400,
        json: [{ code: 'DuplicateEmail', description: 'Bu e-posta adresi zaten kayıtlı.' }],
      },
    })
    openManagerForm('ASKİ')
    fillManager({ first: 'Ayşe', last: 'Demir', email: 'ayse@aski.test', password: 'Gizli123!' })
    submitManager()

    await waitFor(() => expect(screen.getByRole('alert').textContent).toBe('Bu e-posta adresi zaten kayıtlı.'))
    expect(screen.getByLabelText('Geçici şifre')).toBeTruthy()
  })

  it('token geçersizse (401) çıkış yapılır', async () => {
    const { onSignOut } = await renderPage({ [NEW_MANAGER]: { status: 401 } })
    openManagerForm('ASKİ')
    fillManager({ first: 'Ayşe', last: 'Demir', email: 'ayse@aski.test', password: 'Gizli123!' })
    submitManager()
    await waitFor(() => expect(onSignOut).toHaveBeenCalled())
  })
})

describe('kurum ekleme', () => {
  it('boş formda hataları gösterir, doluyken istek atar ve yeni kurumu listenin başına koyar', async () => {
    const { fetchMock } = await renderPage({
      [NEW_ORG]: {
        status: 201,
        json: { id: 'org-3', name: 'İzmir Belediyesi', organizationTypeName: 'Belediye', city: 'İzmir', district: 'Konak', profileInfo: null, createdAt: '2026-11-01T10:00:00Z' },
      },
    })
    const submit = screen.getAllByRole('button', { name: 'Kurum ekle' }).find((b) => (b as HTMLButtonElement).type === 'submit')!
    fireEvent.click(submit)
    expect(screen.getByText('Kurum adı zorunludur.')).toBeTruthy()
    expect(screen.getByText('Kurum türü seçin.')).toBeTruthy()
    expect(screen.getByText('Şehir zorunludur.')).toBeTruthy()

    fireEvent.change(screen.getByLabelText('Kurum adı'), { target: { value: 'İzmir Belediyesi' } })
    fireEvent.change(screen.getByLabelText('Şehir'), { target: { value: 'izmir' } })
    fireEvent.change(screen.getByLabelText('İlçe (isteğe bağlı)'), { target: { value: ' Konak ' } })
    fireEvent.change(screen.getByLabelText('Kurum türü'), { target: { value: '1' } })
    fireEvent.click(submit)

    const rows = await waitFor(() => {
      const r = screen.getAllByRole('row')
      expect(r[1].textContent).toContain('İzmir Belediyesi')
      return r
    })
    expect(rows).toHaveLength(4)
    expect(rows[1].textContent).toContain('İzmir / Konak')
    const post = fetchMock.mock.calls.find(([url, init]) => url === '/institution/api/Organizations' && init?.method === 'POST')!
    expect(JSON.parse(post[1]!.body as string)).toMatchObject({ name: 'İzmir Belediyesi', organizationTypeId: 1, city: 'izmir', district: 'Konak' })
  })
})
