/// Single source of truth for what OdakLan offers.
///
/// Update this file in every development step, then run
/// `dart run tool/export_manifest.dart` so the website picks it up.
library;

import 'dart:convert';

import 'city.dart';
import 'focus.dart';
import 'progress.dart';

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
        'decay': {'tendedDayMinutes': tendedDayMinutes, 'perDay': const City().decayPerDay, 'breakDamage': const City().breakDamage, 'repairPerBlock': const City().repairPerBlock, 'workingCondition': workingCondition, 'conditionAfterCollapse': conditionAfterCollapse},
        'buildings': [
          for (final b in buildings) {
              'id': b.id,
              'name': b.name,
              'description': b.description,
              'unlockLevel': b.unlockLevel,
              'effect': b.effect,
              'costs': [for (var l = 1; l <= b.maxLevel; l++) b.costToReach(l)],
            },
        ],
      },
      'progress': {
        'tags': [for (final t in focusTags) t.label],
        'stakes': [
          for (final s in stakeOptions.where((s) => s > 0)) {'stake': s, 'won': stakePayout(s, completed: true)},
        ],
        'freezeCost': freezeCost,
        'maxFreezes': maxFreezes,
        'quests': [
          for (final q in questPool) {'title': q.title, 'reward': q.reward},
        ],
        'questsPerDay': questsPerDay,
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

const appVersion = '0.5.0';

const features = <Feature>[
  Feature(
    id: 'focus_session',
    title: 'Odak Seansı',
    description:
        'Her $energyBlockMinutes dakikalık odak 1 Enerji. Seansı bitirirsen '
        '+1 bonus Enerji ve iki kat XP. Seans boyunca ekran açık kalır, kalan süre '
        'bildirimde ve kilit ekranında görünür.',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'anti_doomscroll',
    title: 'Kaydırma Kalkanı',
    description:
        'Telefonu kilitlemek serbest. Başka uygulamaya geçersen bildirimde canlı '
        'bir geri sayım başlar; dönmezsen seans bozulur, tamamlanan bloklar yine '
        'senin. (Geri sayım bildirimi şimdilik Android’de.)',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'city',
    title: 'Siber Şehrin',
    description:
        'Kazandığın Enerji ile şehrini kur. Her binanın farklı bir gücü var: '
        'XP, Enerji, onarım ya da savunma. Hangi sırayla kuracağın senin stratejin.',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'city_decay',
    title: 'Çürüyen Şehir',
    description:
        'Odaklanmadığın her gün binaların yıpranır, seansı yarıda bırakmak en değerli binanı çatlatır. '
        'Sıfıra inen bina bir seviye çöker. Tek onarım yolu: odaklanmak. Harabeler yarı fiyatına yeniden kurulur.',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'focus_contract',
    title: 'Odak Sözleşmesi',
    description:
        'Kendine söz ver: Enerji yatır, seansı bitirirsen %50 fazlasıyla geri al. '
        'Kaçarsan yatırdığın gider.',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'focus_map',
    title: 'Odak Haritası',
    description:
        'Her seansa bir niyet ver. Haftalık grafik, 12 haftalık ısı haritası ve '
        'niyetlere göre dağılımla nereye odaklandığını gör.',
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
    description:
        'Her gün herkese aynı 3 görev. Toplamayı unuttuğun ödüller ertesi gün '
        'kendiliğinden toplanır ve bildirimle haber verilir. Serini koru; '
        'kaçırdığın bir günü Enerjiyle aldığın Seri Kalkanı kurtarır.',
    status: FeatureStatus.ready,
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
    id: 'account',
    title: 'Google ile Giriş',
    description:
        'Tek dokunuşla Google hesabınla gir. Hesap şart değil: giriş yapmadan da '
        'odaklanabilir, şehrini kurabilirsin. Oturum anahtarın telefonun güvenli kasasında saklanır.',
    status: FeatureStatus.ready,
  ),
  Feature(
    id: 'privacy',
    title: 'Gizlilik Önce',
    description:
        'Başkalarına yalnızca rastgele takma adın görünür; Google adın ve e-postan hiçbir oyuncuya gösterilmez. '
        'Mesajlarına, galerine dokunmayız. KVKK uyumlu.',
    status: FeatureStatus.planned,
  ),
];

const roadmap = <RoadmapStep>[
  RoadmapStep(1, 'Uygulama ve site iskeleti', done: true),
  RoadmapStep(2, 'Odak motoru ve zamanlayıcı', done: true),
  RoadmapStep(3, 'Siber şehir ve seviyeler', done: true),
  RoadmapStep(4, 'Seriler, görevler, Odak Sözleşmesi, istatistik', done: true),
  RoadmapStep(5, 'Hesaplar ve güvenli veritabanı', done: true),
  RoadmapStep(6, 'Sunucu doğrulamalı seanslar'),
  RoadmapStep(7, 'Odak Klanları ve ortak kale'),
  RoadmapStep(8, 'Bildirimler ve hatırlatıcılar'),
  RoadmapStep(9, 'Sosyal medya dedektörü (Android)'),
  RoadmapStep(10, 'Güvenlik sıkılaştırma ve yayın'),
];
