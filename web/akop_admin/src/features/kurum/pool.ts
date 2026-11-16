export type PoolStatus = 'Pending' | 'InProgress' | 'Resolved'

/** Kurumların gördüğü ihbar havuzundaki bir ihbar. */
export type PoolReport = {
  id: string
  title: string
  description: string
  categoryCode: string
  categoryName: string
  subcategoryName: string | null
  city: string
  district: string | null
  locationText: string
  createdAt: string
  status: PoolStatus
  imageUrls: string[]
  /** Sistem bu ihbarın kuruma ait olabileceğini düşünüyor; [relevanceReason] nedenini söyler. */
  relevant: boolean
  relevanceReason: string | null
}

export const STATUS_LABEL: Record<PoolStatus, string> = {
  Pending: 'Onay bekleyen',
  InProgress: 'Devam eden',
  Resolved: 'Çözülen',
}

const hoursAgo = (h: number) => new Date(Date.now() - h * 3_600_000).toISOString()

// shortcut: ReportService'te kurumlara açık havuz uç noktası yok; arayüz bu örnek veriyle çalışır.
// Uç nokta gelince fetchPool içi `request<PoolReport[]>(...)` olur, ekran değişmez.
const SAMPLE: PoolReport[] = [
  {
    id: 'r-101',
    title: 'Okul önünde derin çukur',
    description: 'Atatürk İlkokulu girişinin önündeki yolda yaklaşık 40 cm genişliğinde çukur var, araçlar zorlanıyor.',
    categoryCode: 'ROAD_DAMAGE',
    categoryName: 'Yol hasarı',
    subcategoryName: 'Çukur',
    city: 'Ankara',
    district: 'Çankaya',
    locationText: 'Kızılay Mah., Atatürk Blv. No: 12',
    createdAt: hoursAgo(1),
    status: 'Pending',
    imageUrls: [],
    relevant: true,
    relevanceReason: 'Çankaya ilçesinde, yol hasarı',
  },
  {
    id: 'r-102',
    title: 'Sokak lambası yanmıyor',
    description: 'Park girişindeki iki lamba üç gündür yanmıyor, akşam saatlerinde yol çok karanlık.',
    categoryCode: 'LIGHTING',
    categoryName: 'Aydınlatma',
    subcategoryName: 'Yanmayan lamba',
    city: 'Ankara',
    district: 'Çankaya',
    locationText: 'Kuğulu Park girişi',
    createdAt: hoursAgo(5),
    status: 'Pending',
    imageUrls: [],
    relevant: true,
    relevanceReason: 'Çankaya ilçesinde, aydınlatma',
  },
  {
    id: 'r-103',
    title: 'Konteyner taşmış',
    description: 'Çöp konteyneri iki gündür boşaltılmadı, çevreye kötü koku yayılıyor.',
    categoryCode: 'WASTE',
    categoryName: 'Çöp ve temizlik',
    subcategoryName: 'Taşan konteyner',
    city: 'Ankara',
    district: 'Çankaya',
    locationText: 'Bahçelievler, 7. Cadde',
    createdAt: hoursAgo(26),
    status: 'InProgress',
    imageUrls: [],
    relevant: true,
    relevanceReason: 'Çankaya ilçesinde, temizlik',
  },
  {
    id: 'r-104',
    title: 'Boru patlağı',
    description: 'Kaldırım kenarından sürekli su akıyor, yol buz tutabilir.',
    categoryCode: 'WATER_LEAK',
    categoryName: 'Su ve kanalizasyon',
    subcategoryName: 'Boru patlağı veya su sızıntısı',
    city: 'Ankara',
    district: 'Keçiören',
    locationText: 'Etlik Cad. No: 48 önü',
    createdAt: hoursAgo(3),
    status: 'Pending',
    imageUrls: [],
    relevant: false,
    relevanceReason: null,
  },
  {
    id: 'r-105',
    title: 'Trafik ışığı arızalı',
    description: 'Kavşaktaki trafik ışığı sürekli sarı yanıp sönüyor.',
    categoryCode: 'TRAFFIC_SIGN',
    categoryName: 'Trafik işaretleri',
    subcategoryName: 'Trafik ışığı arızası',
    city: 'Ankara',
    district: 'Yenimahalle',
    locationText: 'Ostim kavşağı',
    createdAt: hoursAgo(50),
    status: 'Resolved',
    imageUrls: [],
    relevant: false,
    relevanceReason: null,
  },
]

export const POOL_IS_SAMPLE = true

export async function fetchPool(): Promise<PoolReport[]> {
  return SAMPLE
}

/** "Az önce", "5 dk önce", "3 saat önce", "2 gün önce" (mobil uygulamadaki ile aynı). */
export function relativeTime(iso: string, now = Date.now()): string {
  const minutes = Math.floor((now - new Date(iso).getTime()) / 60_000)
  if (minutes < 1) return 'Az önce'
  if (minutes < 60) return `${minutes} dk önce`
  if (minutes < 60 * 24) return `${Math.floor(minutes / 60)} saat önce`
  return `${Math.floor(minutes / (60 * 24))} gün önce`
}
