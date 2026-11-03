"use client";

import { animate, motion, useMotionValue, useReducedMotion, useTransform } from "motion/react";
import { Shield, Zap } from "lucide-react";
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
      : animate(progress, [0, 1], { duration: 10, ease: "linear", repeat: Infinity });
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
      initial={{ opacity: 0, y: 24 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.8, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
      className="mx-auto w-[280px] shrink-0"
    >
      <div className="h-[560px] rounded-[44px] border border-line bg-black p-3 shadow-2xl shadow-black/60">
        <div className="flex h-full flex-col items-center overflow-hidden rounded-[32px] bg-bg">
          <p className="mt-7 text-xs font-semibold tracking-[0.25em] text-muted">ODAK SEANSI</p>
          <div className="relative my-auto">
            <svg width="200" height="200" viewBox="0 0 200 200" className="-rotate-90">
              <circle cx="100" cy="100" r={R} fill="none" stroke="#2a2d35" strokeWidth="10" />
              <motion.circle
                cx="100" cy="100" r={R} fill="none" stroke="#f5a524" strokeWidth="10"
                strokeLinecap="round" strokeDasharray={C} style={{ strokeDashoffset: dashOffset }}
              />
            </svg>
            <span className="absolute inset-0 grid place-items-center font-display text-4xl font-bold tabular-nums">
              {minutesLeft} dk
            </span>
          </div>
          <div className="mb-8 w-full space-y-2 px-5">
            <Row icon={<Zap size={16} className="text-accent" />} label="Enerji" value={`+${energy}`} />
            <Row icon={<Shield size={16} className="text-ok" />} label="Klan kalesi" value="Güvende" />
          </div>
        </div>
      </div>
    </motion.div>
  );
}

function Row({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div className="flex items-center gap-2 rounded-xl bg-surface px-3.5 py-2.5 text-sm">
      {icon}
      <span className="text-muted">{label}</span>
      <span className="ml-auto font-semibold tabular-nums">{value}</span>
    </div>
  );
}
