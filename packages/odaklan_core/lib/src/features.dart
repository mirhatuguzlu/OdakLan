/// Single source of truth for what OdakLan offers.
///
/// Update this file in every development step, then run
/// `dart run tool/export_manifest.dart` so the website picks it up.
library;

import 'dart:convert';

enum FeatureStatus { live, inProgress, planned }

/// The manifest as the website consumes it (site/src/content/manifest.json).
String manifestJson() => '${const JsonEncoder.withIndent('  ').convert({
  'appVersion': appVersion,
  'features': [
    for (final f in features)
      {
        'id': f.id,
        'title': f.title,
        'description': f.description,
        'status': f.status.name,
        'platformNote': ?f.platformNote,
      },
  ],
  'roadmap': [
    for (final s in roadmap)
      {'number': s.number, 'title': s.title, 'done': s.done},
  ],
})}\n';

class Feature {
  const Feature({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.platformNote,
  });

  /// Stable key; the website maps it to an icon.
  final String id;
  final String title;
  final String description;
  final FeatureStatus status;

  /// e.g. "Yalnızca Android" when a feature is platform-limited.
  final String? platformNote;
}

class RoadmapStep {
  const RoadmapStep(this.number, this.title, {this.done = false});

  final int number;
  final String title;
  final bool done;
}

const appVersion = '0.1.0';

const features = <Feature>[
  Feature(
    id: 'focus_session',
    title: 'Odak Seansı',
    description:
        'Telefona dokunmadan geçen her 10 dakika sana Enerji ve XP kazandırır.',
    status: FeatureStatus.planned,
  ),
  Feature(
    id: 'anti_doomscroll',
    title: 'Kaydırma Kalkanı',
    description:
        'Seans sırasında uygulamadan çıkarsan seans bozulur, ödül kaybolur.',
    status: FeatureStatus.planned,
  ),
  Feature(
    id: 'city',
    title: 'Siber Şehrin',
    description:
        'Kazandığın Enerji ile neon şehrini kur, binalarını seviye atlat.',
    status: FeatureStatus.planned,
  ),
  Feature(
    id: 'clans',
    title: 'Odak Klanları',
    description:
        'Arkadaşlarınla klan kur. Biri kaydırmaya dalarsa ortak kale hasar alır.',
    status: FeatureStatus.planned,
  ),
  Feature(
    id: 'fair_rewards',
    title: 'Hilesiz Ödüller',
    description:
        'Ödüller sunucuda, sunucu saatiyle hesaplanır; saat oynatmak işe yaramaz.',
    status: FeatureStatus.planned,
  ),
  Feature(
    id: 'quests',
    title: 'Seriler ve Görevler',
    description: 'Günlük görevler ve odak serileriyle her gün geri gel.',
    status: FeatureStatus.planned,
  ),
  Feature(
    id: 'social_detect',
    title: 'Sosyal Medya Dedektörü',
    description:
        'Seans sırasında Instagram veya TikTok açılırsa klanın anında haberdar olur.',
    status: FeatureStatus.planned,
    platformNote: 'Yalnızca Android',
  ),
  Feature(
    id: 'privacy',
    title: 'Gizlilik Önce',
    description:
        'Yalnızca e-posta ve takma ad. Mesajlarına, galerine dokunmayız. KVKK uyumlu.',
    status: FeatureStatus.planned,
  ),
];

const roadmap = <RoadmapStep>[
  RoadmapStep(1, 'Uygulama ve site iskeleti', done: true),
  RoadmapStep(2, 'Odak motoru ve zamanlayıcı'),
  RoadmapStep(3, 'Siber şehir ve seviyeler'),
  RoadmapStep(4, 'Hesaplar ve güvenli veritabanı'),
  RoadmapStep(5, 'Sunucu doğrulamalı seanslar'),
  RoadmapStep(6, 'Odak Klanları ve ortak kale'),
  RoadmapStep(7, 'Bildirimler, seriler, görevler'),
  RoadmapStep(8, 'Sosyal medya dedektörü (Android)'),
  RoadmapStep(9, 'Güvenlik sıkılaştırma ve yayın'),
];
