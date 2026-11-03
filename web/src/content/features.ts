// Single source of truth for what the app does. Update after every app step
// so the site never promises more (or less) than the app actually ships.

export type Status = "live" | "building" | "planned";

export type Feature = {
  id: string;
  title: string;
  description: string;
  icon: string; // emoji keeps the site dependency-free
  status: Status;
};

export const features: Feature[] = [
  {
    id: "focus",
    title: "Odak Seansı",
    description:
      "Zamanlayıcıyı başlat, telefonu bırak. Her kesintisiz 10 dakika sana Enerji ve XP kazandırır.",
    icon: "⏱️",
    status: "planned",
  },
  {
    id: "city",
    title: "Siberpunk Şehrin",
    description:
      "Topladığın Enerji ile binalar kur, yükselt ve neon şehrini büyüt. Odaklandıkça şehir canlanır.",
    icon: "🌆",
    status: "planned",
  },
  {
    id: "clan",
    title: "Odak Klanları",
    description:
      "Arkadaşlarınla klan kur. Biri seansı bozarsa ortak kale hasar alır — kimse grubu yarı yolda bırakmak istemez.",
    icon: "🛡️",
    status: "planned",
  },
  {
    id: "anticheat",
    title: "Hilesiz Ödüller",
    description:
      "Ödüller sunucu saatine göre hesaplanır. Telefonun saatiyle oynamak işe yaramaz.",
    icon: "🔒",
    status: "planned",
  },
  {
    id: "social-detect",
    title: "Sosyal Medya Algılama",
    description:
      "Android'de seans sırasında Instagram veya TikTok açılırsa uygulama bunu fark eder.",
    icon: "📵",
    status: "planned",
  },
  {
    id: "quests",
    title: "Seriler ve Görevler",
    description: "Günlük görevler, odak serileri ve hatırlatıcılarla alışkanlık kazan.",
    icon: "🔥",
    status: "planned",
  },
];

export type Milestone = { step: number; title: string; status: Status };

export const roadmap: Milestone[] = [
  { step: 1, title: "Uygulama iskeleti ve tasarım dili", status: "live" },
  { step: 2, title: "Odak motoru ve animasyonlu zamanlayıcı", status: "building" },
  { step: 3, title: "Kaynaklar, seviye ve şehir inşası", status: "planned" },
  { step: 4, title: "Hesaplar ve güvenli veritabanı", status: "planned" },
  { step: 5, title: "Sunucu doğrulamalı seanslar", status: "planned" },
  { step: 6, title: "Odak Klanları ve ortak kale", status: "planned" },
  { step: 7, title: "Bildirimler, seriler, günlük görevler", status: "planned" },
  { step: 8, title: "Android sosyal medya algılama", status: "planned" },
  { step: 9, title: "Güvenlik sıkılaştırma ve yayın", status: "planned" },
];

export const statusLabel: Record<Status, string> = {
  live: "Hazır",
  building: "Geliştiriliyor",
  planned: "Planlandı",
};
