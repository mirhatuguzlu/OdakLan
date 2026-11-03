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
      : animate(clock, [0, 1], { duration: 8, ease: "linear", repeat: Infinity });
    return () => {
      unsub();
      controls?.stop();
    };
  }, [clock, reduce]);

  const hp = hpAt(t);
  const hit = t >= 0.3 && t < 0.55;
  const damaged = hp < 0.95;

  return (
    <div className="rounded-xl border border-line bg-surface p-6">
      <div className="flex items-center gap-3">
        <span className="grid size-10 place-items-center rounded-lg bg-raised">
          <Castle size={20} aria-hidden />
        </span>
        <div>
          <p className="font-display font-semibold">Neon Kale</p>
          <p className="text-xs text-muted">4 üye · Klan seviyesi 3</p>
        </div>
        <span
          className={`ml-auto font-semibold tabular-nums ${damaged ? "text-danger" : "text-ok"}`}
        >
          {Math.round(hp * 100)} / 100
        </span>
      </div>
      <div
        className="mt-5 h-2 overflow-hidden rounded-full bg-line"
        role="progressbar"
        aria-label="Kale canı"
        aria-valuenow={Math.round(hp * 100)}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className={`h-full rounded-full transition-colors duration-300 ${damaged ? "bg-danger" : "bg-ok"}`}
          style={{ width: `${hp * 100}%` }}
        />
      </div>
      <ul className="mt-5 divide-y divide-line">
        {MEMBERS.map((m) => {
          const slipped = m === "Mert" && hit;
          return (
            <li key={m} className="flex items-center gap-3 py-2.5 text-sm">
              <span className="grid size-7 place-items-center rounded-full bg-raised text-xs text-muted">
                {m[0]}
              </span>
              {m}
              <span className={`ml-auto flex items-center gap-1.5 ${slipped ? "text-danger" : "text-muted"}`}>
                <span
                  className={`size-1.5 rounded-full ${slipped ? "bg-danger" : "bg-ok"}`}
                  aria-hidden
                />
                {slipped ? "TikTok açtı · −35" : "Odakta"}
              </span>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
