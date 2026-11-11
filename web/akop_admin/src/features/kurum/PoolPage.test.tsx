import { fireEvent, render, screen, within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import PoolPage from './PoolPage'
import { relativeTime } from './pool'

const items = () => within(screen.getByRole('list')).getAllByRole('button').map((b) => b.querySelector('.pool-item-title')!.textContent)

describe('ihbar havuzu', () => {
  it('kurumla ilgili yeni ihbarlar için bildirim gösterir, Göster yalnızca onları listeler', async () => {
    render(<PoolPage />)
    expect((await screen.findByRole('status')).textContent).toContain('2 yeni ihbar')
    expect(items()).toHaveLength(5)

    fireEvent.click(screen.getByRole('button', { name: 'Göster' }))
    expect(items()).toEqual(['Okul önünde derin çukur', 'Sokak lambası yanmıyor', 'Konteyner taşmış'])
    expect((screen.getByLabelText('Yalnızca kurumumla ilgili olabilecekler') as HTMLInputElement).checked).toBe(true)
  })

  it('ihbar açılınca ayrıntısı görünür ve bildirimden düşer', async () => {
    render(<PoolPage />)
    fireEvent.click(await screen.findByRole('button', { name: /Okul önünde derin çukur/ }))
    const detail = screen.getByRole('region', { name: 'Okul önünde derin çukur' })
    expect(detail.textContent).toContain('Yol hasarı · Çukur')
    expect(detail.textContent).toContain('Neden size gösteriliyor: Çankaya ilçesinde, yol hasarı')
    expect(screen.getByRole('status').textContent).toContain('1 yeni ihbar')

    fireEvent.click(within(detail).getByRole('button', { name: 'Kapat' }))
    expect(screen.queryByRole('region', { name: 'Okul önünde derin çukur' })).toBeNull()
  })

  it('kategori, durum ve arama birlikte süzer', async () => {
    render(<PoolPage />)
    await screen.findByRole('list')
    fireEvent.change(screen.getByLabelText('Durum'), { target: { value: 'Pending' } })
    expect(items()).toEqual(['Okul önünde derin çukur', 'Sokak lambası yanmıyor', 'Boru patlağı'])
    fireEvent.change(screen.getByLabelText('Kategori'), { target: { value: 'WATER_LEAK' } })
    expect(items()).toEqual(['Boru patlağı'])
    fireEvent.change(screen.getByLabelText('İhbarlarda ara'), { target: { value: 'çukur' } })
    expect(screen.getByText('Bu filtrelere uyan ihbar yok.')).toBeTruthy()
  })

  it('göreli zaman', () => {
    const now = Date.parse('2026-11-11T12:00:00Z')
    expect(relativeTime('2026-11-11T11:59:30Z', now)).toBe('Az önce')
    expect(relativeTime('2026-11-11T11:55:00Z', now)).toBe('5 dk önce')
    expect(relativeTime('2026-11-11T09:00:00Z', now)).toBe('3 saat önce')
    expect(relativeTime('2026-11-09T12:00:00Z', now)).toBe('2 gün önce')
  })
})
