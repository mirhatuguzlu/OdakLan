"use client";

import { AnimatePresence, motion } from "motion/react";
import { Lock, LogOut, Timer, Zap } from "lucide-react";
import { useState } from "react";
import { manifest } from "@/content/manifest";
import { Reveal } from "./Reveal";

const rules = manifest.focusRules;

const STEPS = [
  [Timer, "Süreni seç", `${rules.presets.map((p) => p.minutes).join(", ")} dakikalık seanslardan birini başlat.`],
  [Lock, "Telefonu bırak", "Ekranı kilitlemek serbest; seans sen dokunmadıkça işler."],
  [LogOut, "Kaçarsan bozulur", `Başka bir uygulamaya geçersen bildirimde ${rules.leaveGraceSeconds} saniyelik geri sayım başlar; dönmezsen seans bozulur.`],
  [Zap, "Enerji topla", `Her ${rules.energyBlockMinutes} dakika 1 Enerji. Bitirirsen bonus Enerji ve iki kat XP.`],
] as const;

/** Rules and numbers come from the app's Dart code via manifest.json. */
export function HowItWorks() {
  const [minutes, setMinutes] = useState(rules.presets[1]?.minutes ?? rules.presets[0].minutes);
  const preset = rules.presets.find((p) => p.minutes === minutes) ?? rules.presets[0];

  return (
    <div className="grid items-start gap-10 lg:grid-cols-2">
      <ol className="space-y-6">
        {STEPS.map(([Icon, title, body], i) => (
          <Reveal key={title} delay={i * 0.06}>
            <li className="flex gap-4">
              <span className="grid size-10 shrink-0 place-items-center rounded-lg border border-line bg-surface">
                <Icon size={18} aria-hidden />
              </span>
              <div>
                <p className="font-display font-semibold">
                  <span className="mr-2 text-muted tabular-nums">{i + 1}.</span>
                  {title}
                </p>
                <p className="mt-1 text-muted">{body}</p>
              </div>
            </li>
          </Reveal>
        ))}
      </ol>

      <Reveal>
        <div className="rounded-xl border border-line bg-surface p-6">
          <p className="text-sm text-muted">Ödül hesaplayıcı</p>
          <div role="radiogroup" aria-label="Seans süresi" className="mt-4 grid grid-cols-4 gap-1 rounded-lg bg-bg p-1">
            {rules.presets.map((p) => (
              <button
                key={p.minutes}
                role="radio"
                aria-checked={p.minutes === minutes}
                onClick={() => setMinutes(p.minutes)}
                className={`rounded-md py-2 text-sm font-medium transition-colors ${
                  p.minutes === minutes ? "bg-raised text-ink" : "text-muted hover:text-ink"
                }`}
              >
                {p.minutes} dk
              </button>
            ))}
          </div>
          <div className="mt-6 grid grid-cols-2 gap-3">
            <Outcome label="Bitirirsen" reward={preset.completed} good minutes={minutes} />
            <Outcome label="Yarıda kaçarsan" reward={preset.brokenAtHalf} minutes={minutes} />
          </div>
          <p className="mt-4 text-xs text-muted">
            Rakamlar uygulamanın kendi kurallarından otomatik gelir.
          </p>
        </div>
      </Reveal>
    </div>
  );
}

function Outcome({
  label, reward, good = false, minutes,
}: { label: string; reward: { energy: number; xp: number }; good?: boolean; minutes: number }) {
  return (
    <div className="rounded-lg border border-line bg-bg p-4">
      <p className={`text-sm font-medium ${good ? "text-ok" : "text-danger"}`}>{label}</p>
      <AnimatePresence mode="popLayout" initial={false}>
        <motion.div
          key={minutes}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -8 }}
          transition={{ duration: 0.2 }}
        >
          <p className="mt-2 flex items-center gap-1.5 font-display text-2xl font-bold tabular-nums">
            <Zap size={18} className="text-accent" aria-hidden /> +{reward.energy}
          </p>
          <p className="text-sm text-muted tabular-nums">+{reward.xp} XP</p>
        </motion.div>
      </AnimatePresence>
    </div>
  );
}
