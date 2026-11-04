/// Single source of truth for what OdakLan offers.
///
/// Update this file in every development step, then run
/// `dart run tool/export_manifest.dart` so the website picks it up.
library;

import 'dart:convert';

import 'city.dart';
import 'focus.dart';

/// live = in the stores; ready = built in the app, not released yet.
enum FeatureStatus { live, ready, inProgress, planned }

/// The manifest as the website consumes it (site/src/content/manifest.json).
String manifestJson() =>
    '${const JsonEncoder.withIndent('  ').convert({
      'appVersion': appVersion,
      'focusRules': {
        'energyBlockMinutes': energyBlockMinutes,
        'leaveGraceSeconds': leaveGrace.inSeconds,
        'presets': [
          for (final m in sessionPresetsMinutes) {'minutes': m, 'completed': _reward(rewardFor(Duration(minutes: m), completed: true)), 'brokenAtHalf': _reward(rewardFor(Duration(minutes: m ~/ 2), completed: false))},
        ],
      },
      'city': {
        'levelXp': [for (var l = 1; l <= 10; l++) xpForLevel(l)],
        'buildings': [
          for (final b in buildings) {
              'id': b.id,
              'name': b.name,
              'description': b.description,
              'unlockLevel': b.unlockLevel,
              'costs': [for (var l = 1; l <= b.maxLevel; l++) b.costToReach(l)],
            },
        ],
      },
      'features': [
        for (final f in features) {'id': f.id, 'title': f.title, 'description': f.description, 'status': f.status.name, 'platformNote': ?f.platformNote},
      ],
      'roadmap': [
        for (final s in roadmap) {'number': s.number, 'title': s.title, 'done': s.done},
      ],
    })}\n';

Map<String, int> _reward(FocusReward r) => {'energy': r.energy, 'xp': r.xp};

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

const appVersion = '0.3.0';

const features = <Feature>[
  Feature(
    id: 'focus_session',
    title: 'Odak Seansı',
    description:
        'Her $energyBlockMinutes dakikalık odak 1 Enerji. Seansı bitirirsen '
        '+1 bonus Enerji ve iki kat XP.',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'anti_doomscroll',
    title: 'Kaydırma Kalkanı',
    description:
        'Telefonu kilitlemek serbest. Başka uygulamaya geçersen seans bozulur; '
        'tamamlanan bloklar yine senin.',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'city',
    title: 'Siber Şehrin',
    description:
        'Kazandığın Enerji ile şehrini kur, binalarını seviye atlat. '
        'XP topladıkça yeni binaların kilidi açılır.',
    status: FeatureStatus.ready,
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
  RoadmapStep(2, 'Odak motoru ve zamanlayıcı', done: true),
  RoadmapStep(3, 'Siber şehir ve seviyeler', done: true),
  RoadmapStep(4, 'Hesaplar ve güvenli veritabanı'),
  RoadmapStep(5, 'Sunucu doğrulamalı seanslar'),
  RoadmapStep(6, 'Odak Klanları ve ortak kale'),
  RoadmapStep(7, 'Bildirimler, seriler, görevler'),
  RoadmapStep(8, 'Sosyal medya dedektörü (Android)'),
  RoadmapStep(9, 'Güvenlik sıkılaştırma ve yayın'),
];
