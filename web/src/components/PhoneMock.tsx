"use client";

import { motion, useReducedMotion } from "motion/react";
import { useEffect, useState } from "react";

const SESSION = 25 * 60;
const R = 70;
const CIRC = 2 * Math.PI * R;

// Illustrative preview of the focus screen; the clock runs 60x faster for the demo.
export function PhoneMock() {
  const reduce = useReducedMotion();
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    if (reduce) return;
    const id = setInterval(() => setElapsed((e) => (e + 60) % SESSION), 1000);
    return () => clearInterval(id);
  }, [reduce]);

  const left = SESSION - elapsed;
  const mm = String(Math.floor(left / 60)).padStart(2, "0");
  const ss = String(left % 60).padStart(2, "0");
  const energy = Math.floor(elapsed / 600);

  return (
    <div className="relative h-[540px] w-[270px] rounded-[44px] border-4 border-line bg-surface p-3 shadow-[0_0_60px_-10px_var(--color-cyan)]">
      <div className="flex h-full flex-col items-center rounded-[34px] bg-bg px-5 pt-10">
        <p className="font-mono text-xs tracking-widest text-muted">ODAK SEANSI</p>

        <div className="relative mt-8">
          <svg width="180" height="180" viewBox="0 0 180 180" role="img" aria-label={`${mm}:${ss} kaldı`}>
            <circle cx="90" cy="90" r={R} fill="none" stroke="var(--color-line)" strokeWidth="10" />
            <motion.circle
              cx="90"
              cy="90"
              r={R}
              fill="none"
              stroke="url(#ring)"
              strokeWidth="10"
              strokeLinecap="round"
              strokeDasharray={CIRC}
              animate={{ strokeDashoffset: CIRC * (1 - elapsed / SESSION) }}
              transition={{ duration: 0.8, ease: "easeOut" }}
              transform="rotate(-90 90 90)"
            />
            <defs>
              <linearGradient id="ring" x1="0" x2="1">
                <stop offset="0%" stopColor="var(--color-cyan)" />
                <stop offset="100%" stopColor="var(--color-pink)" />
              </linearGradient>
            </defs>
          </svg>
          <span className="absolute inset-0 flex items-center justify-center font-mono text-3xl font-bold">
            {mm}:{ss}
          </span>
        </div>

        <motion.div
          key={energy}
          initial={{ scale: 0.6, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className="mt-8 rounded-xl border border-line bg-surface px-4 py-2 text-sm"
        >
          ⚡ <span className="font-semibold text-ok">+{energy}</span> Enerji
        </motion.div>

        <div className="mt-auto mb-4 grid w-full grid-cols-4 gap-1 text-center text-[10px] text-muted">
          {["Odak", "Şehir", "Klan", "Profil"].map((t, i) => (
            <span key={t} className={i === 0 ? "text-cyan" : undefined}>
              {t}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
