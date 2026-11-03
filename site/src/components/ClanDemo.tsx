"use client";

import { animate, useMotionValue, useReducedMotion } from "motion/react";
import { Castle } from "lucide-react";
import { useEffect, useState } from "react";

const MEMBERS = ["Ayşe", "Mert", "Deniz", "Can"];

// Loop 0..1: 0–0.3 healthy, 0.3–0.4 hit, 0.4–0.9 repair.
function hpAt(t: number) {
  const easeOut = (x: number) => 1 - (1 - x) ** 3;
  const easeInOut = (x: number) => (x < 0.5 ? 4 * x ** 3 : 1 - (-2 * x + 2) ** 3 / 2);
  if (t < 0.3) return 1;
  if (t < 0.4) return 1 - 0.35 * easeOut((t - 0.3) / 0.1);
  if (t < 0.9) return 0.65 + 0.35 * easeInOut((t - 0.4) / 0.5);
  return 1;
}

/** A member slips, the shared fortress takes damage, the clan repairs it. */
export function ClanDemo() {
  const reduce = useReducedMotion();
  const clock = useMotionValue(reduce ? 0.45 : 0);
  const [t, setT] = useState(clock.get());

  useEffect(() => {
    const unsub = clock.on("change", setT);
    const controls = reduce
      ? undefined
      : animate(clock, [0, 1], { duration: 7, ease: "linear", repeat: Infinity });
    return () => {
      unsub();
      controls?.stop();
    };
  }, [clock, reduce]);

  const hp = hpAt(t);
  const hit = t >= 0.3 && t < 0.55;
  // Red at 0.65 HP → green at full.
  const hue = Math.round(((hp - 0.65) / 0.35) * 150);
  const color = `hsl(${hue} 100% 60%)`;

  return (
    <div
      className={`rounded-3xl border bg-surface/85 p-6 backdrop-blur transition-colors duration-300 ${
        hit ? "border-danger" : "border-line"
      }`}
    >
      <div className="flex items-center gap-3">
        <Castle size={34} style={{ color }} />
        <span className="font-display text-xl font-bold">Neon Kale</span>
        <span className="ml-auto font-semibold tabular-nums" style={{ color }}>
          {Math.round(hp * 100)} HP
        </span>
      </div>
      <div
        className="mt-4 h-3 overflow-hidden rounded-full bg-line"
        role="progressbar"
        aria-label="Kale canı"
        aria-valuenow={Math.round(hp * 100)}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div className="h-full rounded-full" style={{ width: `${hp * 100}%`, background: color }} />
      </div>
      <ul className="mt-5 space-y-3">
        {MEMBERS.map((m) => (
          <li key={m} className="flex items-center gap-3">
            <span className="grid size-7 place-items-center rounded-full bg-violet/30 text-xs">
              {m[0]}
            </span>
            {m}
            {m === "Mert" && hit ? (
              <span className="ml-auto font-bold text-danger">TikTok&apos;a girdi! −35 HP</span>
            ) : (
              <span className="ml-auto text-ok">odaklanıyor</span>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}
