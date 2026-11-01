export type Session = { token: string; role: string }

const KEY = 'akop_session'

// shortcut: refresh token kullanılmıyor; access token bitince kullanıcı yeniden giriş yapar
export function loadSession(): Session | null {
  try {
    return JSON.parse(sessionStorage.getItem(KEY) ?? 'null')
  } catch {
    return null
  }
}

export function saveSession(session: Session | null) {
  try {
    if (session) sessionStorage.setItem(KEY, JSON.stringify(session))
    else sessionStorage.removeItem(KEY)
  } catch {
    // depolama kapalıysa oturum yalnızca bellekte kalır
  }
}
