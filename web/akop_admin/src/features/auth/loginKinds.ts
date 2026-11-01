/** Giriş sayfası türleri: sistem yöneticisi ayrı bir adresten (/admin), kurumlar ana adresten girer. */
export type LoginKind = 'admin' | 'kurum'

export const LOGIN_COPY: Record<LoginKind, { role: string; title: string; lead: string; denied: string; footnote: string }> = {
  admin: {
    role: 'SystemAdmin',
    title: 'Sistem yöneticisi girişi',
    lead: 'Yönetici hesabınızla oturum açın.',
    denied: 'Bu sayfadan yalnızca sistem yöneticileri giriş yapabilir.',
    footnote: 'Bu sayfa yalnızca sistem yöneticileri içindir.',
  },
  kurum: {
    role: 'OrgManager',
    title: 'Kurum girişi',
    lead: 'Hesabınızla oturum açın.',
    denied: 'Bu sayfadan yalnızca kurum hesapları giriş yapabilir.',
    footnote: 'Hesabınız yok mu? AKOP ekibiyle iletişime geçin.',
  },
}
