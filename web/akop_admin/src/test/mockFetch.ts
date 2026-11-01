import { vi } from 'vitest'

type Reply = { status?: number; json?: unknown; text?: string }
type Handler = Reply | ((init: RequestInit) => Reply)

/**
 * fetch'i "METHOD /yol" anahtarlı cevaplarla değiştirir. Tanımsız bir istek testi düşürür,
 * böylece beklenmeyen API çağrıları sessizce geçmez.
 */
export function mockFetch(routes: Record<string, Handler>) {
  const fn = vi.fn(async (url: string, init: RequestInit = {}) => {
    const key = `${init.method ?? 'GET'} ${url}`
    const route = routes[key]
    if (!route) throw new Error(`Beklenmeyen istek: ${key}`)
    const reply = typeof route === 'function' ? route(init) : route
    const status = reply.status ?? 200
    if (reply.json !== undefined) {
      return new Response(JSON.stringify(reply.json), { status, headers: { 'Content-Type': 'application/json' } })
    }
    return new Response(reply.text ?? '', { status })
  })
  vi.stubGlobal('fetch', fn)
  return fn
}
