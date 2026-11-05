"use client";

import { AnimatePresence, motion } from "motion/react";
import { Flame, Shield, Zap } from "lucide-react";
import { useState } from "react";
import { manifest } from "@/content/manifest";
import { Reveal } from "./Reveal";

const p = manifest.progress;

/** Contract calculator + quest pool; every number comes from the app's Dart rules. */
export function ProgressDemo() {
  const [stake, setStake] = useState(p.stakes[1]?.stake ?? p.stakes[0].stake);
  const won = p.stakes.find((s) => s.stake === stake)?.won ?? 0;

  return (
    <div className="grid items-start gap-6 lg:grid-cols-2">
      <Reveal>
        <div className="rounded-xl border border-line bg-surface p-6">
          <p className="font-display text-lg font-semibold">Odak Sözleşmesi</p>
          <p className="mt-1 text-sm text-muted">
            Seanstan önce kendine söz ver: Enerji yatır. Bitirirsen fazlasıyla geri al, kaçarsan kaybet.
          </p>
          <div role="radiogroup" aria-label="Yatırılan Enerji" className="mt-5 grid grid-cols-3 gap-1 rounded-lg bg-bg p-1">
            {p.stakes.map((s) => (
              <button
                key={s.stake}
                role="radio"
                aria-checked={s.stake === stake}
                onClick={() => setStake(s.stake)}
                className={`rounded-md py-2 text-sm font-medium transition-colors ${
                  s.stake === stake ? "bg-raised text-ink" : "text-muted hover:text-ink"
                }`}
              >
                {s.stake} Enerji
              </button>
            ))}
          </div>
          <div className="mt-5 grid grid-cols-2 gap-3">
            <Outcome label={`Bitirirsen geri al (+${won - stake})`} value={`${won}`} good k={stake} />
            <Outcome label="Kaçarsan" value={`-${stake}`} k={stake} />
          </div>
          <div className="mt-6 flex items-start gap-3 rounded-lg border border-line bg-bg p-4">
            <Shield className="mt-0.5 shrink-0 text-accent" size={18} aria-hidden />
            <p className="text-sm text-muted">
              <span className="font-medium text-ink">Seri Kalkanı</span> — {p.freezeCost} Enerji. Kaçırdığın günü
              kurtarır; en fazla {p.maxFreezes} tane taşıyabilirsin.
            </p>
          </div>
        </div>
      </Reveal>

      <Reveal delay={0.08}>
        <div className="rounded-xl border border-line bg-surface p-6">
          <p className="flex items-center gap-2 font-display text-lg font-semibold">
            <Flame size={18} className="text-accent" aria-hidden /> Günlük görevler
          </p>
          <p className="mt-1 text-sm text-muted">
            Her gün herkese bu havuzdan aynı {p.questsPerDay} görev düşer. Arkadaşınla aynı hedefe koşarsın.
            Toplamayı unuttuğun ödüller ertesi gün kendiliğinden toplanır.
          </p>
          <ul className="mt-5 divide-y divide-line">
            {p.quests.map((q) => (
              <li key={q.title} className="flex items-center justify-between py-2.5 text-sm">
                {q.title}
                <span className="flex items-center gap-1 font-medium tabular-nums">
                  <Zap size={14} className="text-accent" aria-hidden />+{q.reward}
                </span>
              </li>
            ))}
          </ul>
          <p className="mt-4 text-xs text-muted">Niyetler: {p.tags.join(" · ")}</p>
        </div>
      </Reveal>
    </div>
  );
}

function Outcome({ label, value, good = false, k }: { label: string; value: string; good?: boolean; k: number }) {
  return (
    <div className="rounded-lg border border-line bg-bg p-4">
      <p className={`text-sm font-medium ${good ? "text-ok" : "text-danger"}`}>{label}</p>
      <AnimatePresence mode="popLayout" initial={false}>
        <motion.p
          key={k}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -8 }}
          transition={{ duration: 0.2 }}
          className="mt-2 flex items-center gap-1.5 font-display text-2xl font-bold tabular-nums"
        >
          <Zap size={18} className="text-accent" aria-hidden /> {value}
        </motion.p>
      </AnimatePresence>
    </div>
  );
}
