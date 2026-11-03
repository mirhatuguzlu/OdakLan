"use client";

import { animate, motion, useMotionValue, useReducedMotion, useTransform } from "motion/react";
import { Bolt, Shield } from "lucide-react";
import { useEffect, useState } from "react";

const R = 88;
const C = 2 * Math.PI * R;

/** Phone frame previewing the focus timer: a compressed 25-minute session loop. */
export function PhoneMock() {
  const reduce = useReducedMotion();
  const progress = useMotionValue(reduce ? 0.62 : 0);
  const dashOffset = useTransform(progress, (p) => C * (1 - p));
  const [p, setP] = useState(progress.get());

  useEffect(() => {
    const unsub = progress.on("change", setP);
    const controls = reduce
      ? undefined
      : animate(progress, [0, 1], { duration: 8, ease: "linear", repeat: Infinity });
    return () => {
      unsub();
      controls?.stop();
    };
  }, [progress, reduce]);

  const minutesLeft = Math.ceil(25 * (1 - p));
  const energy = Math.floor((25 * p) / 10);

  return (
    <motion.div
      role="img"
      aria-label="Odak zamanlayıcısı önizlemesi"
      initial={{ opacity: 0, y: 40 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.9, delay: 0.25, ease: [0.22, 1, 0.36, 1] }}
      className="relative mx-auto w-[280px] shrink-0"
    >
      <motion.div
        animate={reduce ? undefined : { y: [0, -12, 0] }}
        transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
        className="h-[560px] rounded-[44px] border-2 border-line bg-[#05050a] p-3 shadow-[0_0_60px_-10px_rgba(0,240,255,0.35),20px_40px_80px_rgba(255,46,136,0.18)]"
      >
        <div className="flex h-full flex-col items-center overflow-hidden rounded-[32px] bg-bg">
          <p className="mt-7 text-xs font-bold tracking-[0.3em] text-muted">ODAK SEANSI</p>
          <div className="relative my-auto">
            <svg width="200" height="200" viewBox="0 0 200 200" className="-rotate-90">
              <defs>
                <linearGradient id="ring" x1="0" y1="0" x2="1" y2="1">
                  <stop offset="0%" stopColor="#00f0ff" />
                  <stop offset="50%" stopColor="#8b5cff" />
                  <stop offset="100%" stopColor="#ff2e88" />
                </linearGradient>
                <filter id="glow">
                  <feGaussianBlur stdDeviation="6" />
                </filter>
              </defs>
              <circle cx="100" cy="100" r={R} fill="none" stroke="#2a2a45" strokeWidth="12" />
              <motion.circle
                cx="100" cy="100" r={R} fill="none" stroke="#00f0ff" strokeOpacity="0.4"
                strokeWidth="18" strokeDasharray={C} style={{ strokeDashoffset: dashOffset }}
                filter="url(#glow)"
              />
              <motion.circle
                cx="100" cy="100" r={R} fill="none" stroke="url(#ring)" strokeWidth="12"
                strokeLinecap="round" strokeDasharray={C} style={{ strokeDashoffset: dashOffset }}
              />
            </svg>
            <span className="absolute inset-0 grid place-items-center font-display text-4xl font-bold tabular-nums">
              {minutesLeft} dk
            </span>
          </div>
          <Chip className="border-cyan/40 bg-cyan/10 text-cyan">
            <Bolt size={16} /> +{energy} Enerji
          </Chip>
          <Chip className="mt-2.5 mb-8 border-ok/40 bg-ok/10 text-ok">
            <Shield size={16} /> Klan kalesi güvende
          </Chip>
        </div>
      </motion.div>
    </motion.div>
  );
}

function Chip({ children, className }: { children: React.ReactNode; className: string }) {
  return (
    <span className={`flex items-center gap-1.5 rounded-full border px-3.5 py-2 text-sm font-semibold ${className}`}>
      {children}
    </span>
  );
}
