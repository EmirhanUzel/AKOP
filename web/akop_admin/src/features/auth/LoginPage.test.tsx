import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { mockFetch } from '../../test/mockFetch'
import LoginPage from './LoginPage'

const LOGIN = 'POST /identity/api/Auth/login'

function fill(email: string, password: string) {
  fireEvent.change(screen.getByLabelText('E-posta'), { target: { value: email } })
  fireEvent.change(screen.getByLabelText('Şifre'), { target: { value: password } })
  fireEvent.click(screen.getByRole('button', { name: 'Giriş yap' }))
}

describe('LoginPage', () => {
  it('boş formda alan hatalarını gösterir ve istek atmaz', () => {
    const fetchMock = mockFetch({})
    render(<LoginPage kind="admin" onLoggedIn={vi.fn()} />)
    fireEvent.click(screen.getByRole('button', { name: 'Giriş yap' }))
    expect(screen.getByText('E-posta zorunludur.')).toBeTruthy()
    expect(screen.getByText('Şifre zorunludur.')).toBeTruthy()
    expect(fetchMock).not.toHaveBeenCalled()
  })

  it('SystemAdmin girişinde token ve rolü iletir, doğru gövdeyi gönderir', async () => {
    const fetchMock = mockFetch({ [LOGIN]: { json: { accessToken: 'tok', role: 'SystemAdmin' } } })
    const onLoggedIn = vi.fn()
    render(<LoginPage kind="admin" onLoggedIn={onLoggedIn} />)
    fill(' admin@akop.test ', 'Gizli123!')
    await waitFor(() => expect(onLoggedIn).toHaveBeenCalledWith({ token: 'tok', role: 'SystemAdmin' }))
    expect(JSON.parse(fetchMock.mock.calls[0][1]!.body as string)).toEqual({
      email: 'admin@akop.test',
      password: 'Gizli123!',
    })
  })

  it('SystemAdmin olmayan rolü içeri almaz', async () => {
    mockFetch({ [LOGIN]: { json: { accessToken: 'tok', role: 'Citizen' } } })
    const onLoggedIn = vi.fn()
    render(<LoginPage kind="admin" onLoggedIn={onLoggedIn} />)
    fill('vatandas@akop.test', 'Gizli123!')
    expect(await screen.findByText('Bu sayfadan yalnızca sistem yöneticileri giriş yapabilir.')).toBeTruthy()
    expect(onLoggedIn).not.toHaveBeenCalled()
  })

  it('yanlış şifrede sunucu mesajını gösterir', async () => {
    mockFetch({ [LOGIN]: { status: 401, text: 'E-posta veya şifre hatalı' } })
    const onLoggedIn = vi.fn()
    render(<LoginPage kind="admin" onLoggedIn={onLoggedIn} />)
    fill('admin@akop.test', 'yanlis')
    expect(await screen.findByText('E-posta veya şifre hatalı')).toBeTruthy()
    expect(onLoggedIn).not.toHaveBeenCalled()
  })

  it('sunucuya ulaşılamazsa bunu söyler', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')))
    render(<LoginPage kind="admin" onLoggedIn={vi.fn()} />)
    fill('admin@akop.test', 'Gizli123!')
    expect(await screen.findByText('Sunucuya ulaşılamadı.')).toBeTruthy()
  })

  it('şifre göster/gizle düğmesi alan türünü değiştirir', () => {
    render(<LoginPage kind="admin" onLoggedIn={vi.fn()} />)
    const password = screen.getByLabelText('Şifre') as HTMLInputElement
    expect(password.type).toBe('password')
    fireEvent.click(screen.getByRole('button', { name: 'Şifreyi göster' }))
    expect(password.type).toBe('text')
    fireEvent.click(screen.getByRole('button', { name: 'Şifreyi gizle' }))
    expect(password.type).toBe('password')
  })

  it('sistem yöneticisi girişi kendi başlığını gösterir ve kurum metnini içermez', () => {
    render(<LoginPage kind="admin" onLoggedIn={vi.fn()} />)
    expect(screen.getByRole('heading', { name: 'Sistem yöneticisi girişi' })).toBeTruthy()
    expect(screen.queryByText(/sistem yöneticisi tarafından/)).toBeNull()
  })
})

describe('LoginPage (kurum)', () => {
  it('kurum yöneticisini içeri alır', async () => {
    mockFetch({ [LOGIN]: { json: { accessToken: 'tok', role: 'OrgManager' } } })
    const onLoggedIn = vi.fn()
    render(<LoginPage kind="kurum" onLoggedIn={onLoggedIn} />)
    expect(screen.getByRole('heading', { name: 'Kurum girişi' })).toBeTruthy()
    fill('mudur@akop.test', 'Gizli123!')
    await waitFor(() => expect(onLoggedIn).toHaveBeenCalledWith({ token: 'tok', role: 'OrgManager' }))
  })

  it('sistem yöneticisini bu sayfadan içeri almaz', async () => {
    mockFetch({ [LOGIN]: { json: { accessToken: 'tok', role: 'SystemAdmin' } } })
    const onLoggedIn = vi.fn()
    render(<LoginPage kind="kurum" onLoggedIn={onLoggedIn} />)
    fill('admin@akop.test', 'Gizli123!')
    expect(await screen.findByText('Bu sayfadan yalnızca kurum hesapları giriş yapabilir.')).toBeTruthy()
    expect(onLoggedIn).not.toHaveBeenCalled()
  })

  it('sistem yöneticisi yazısı geçmez', () => {
    render(<LoginPage kind="kurum" onLoggedIn={vi.fn()} />)
    expect(screen.queryByText(/sistem yöneticisi/i)).toBeNull()
  })
})
