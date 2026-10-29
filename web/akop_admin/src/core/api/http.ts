// shortcut: adresler Vite proxy önekleri; servisler yayına çıkınca gerçek adres/gateway ile değişir
export const IDENTITY_API = '/identity/api'
export const INSTITUTION_API = '/institution/api'

export class ApiError extends Error {
  status: number

  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

/** Backend düz metin ya da ProblemDetails döner; kullanıcıya gösterilecek tek cümleyi çıkarır. */
function messageFrom(body: string, status: number): string {
  try {
    const json = JSON.parse(body)
    // Identity hataları [{ code, description }] dizisi gelir
    if (Array.isArray(json) && json[0]?.description) {
      return json.map((e: { description: string }) => e.description).join(' ')
    }
    const first = json?.errors && Object.values<string[]>(json.errors)[0]?.[0]
    if (first) return first
  } catch {
    // düz metin
  }
  return body.trim() || `İstek başarısız (${status}).`
}

export async function request<T>(url: string, init: RequestInit = {}, token?: string): Promise<T> {
  const headers = new Headers(init.headers)
  if (init.body) headers.set('Content-Type', 'application/json')
  if (token) headers.set('Authorization', `Bearer ${token}`)

  let res: Response
  try {
    res = await fetch(url, { ...init, headers })
  } catch {
    throw new ApiError(0, 'Sunucuya ulaşılamadı.')
  }
  const body = await res.text()
  if (!res.ok) throw new ApiError(res.status, messageFrom(body, res.status))
  if (!body) return undefined as T
  // Bazı uçlar JSON yerine düz metin döner (örn. "Kurum kullanıcısı oluşturuldu.")
  return (res.headers.get('Content-Type')?.includes('json') ? JSON.parse(body) : body) as T
}
