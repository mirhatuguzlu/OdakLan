"use client";

import { motion } from "motion/react";
import { Lock, Minus, Plus, Zap } from "lucide-react";
import { useState } from "react";
import { manifest } from "@/content/manifest";

const { buildings, levelXp } = manifest.city;
// Same plots as the app's city_view.dart.
const PLOTS: Record<string, [number, number]> = {
  tower: [0, 0], library: [1, 0], workshop: [0, 1], home: [1, 1], park: [2, 1],
};
const TW = 96, TH = 48, OX = 165, OY = 140;
const top = (c: number, r: number): [number, number] => [OX + ((c - r) * TW) / 2, OY + ((c + r) * TH) / 2];
const pts = (...p: [number, number][]) => "M" + p.map(([x, y]) => `${x.toFixed(1)} ${y.toFixed(1)}`).join(" L") + " Z";
const diamond = ([x, y]: [number, number], w: number, h: number) =>
  pts([x, y], [x + w / 2, y + h / 2], [x, y + h], [x - w / 2, y + h / 2]);

const completed25 = manifest.focusRules.presets.find((p) => p.minutes === 25)?.completed.energy ?? 1;
const START: Record<string, number> = { home: 2, library: 1 };

/** Costs and unlock levels come from the app's Dart rules via manifest.json. */
export function CityDemo() {
  const [levels, setLevels] = useState(START);
  const spent = buildings.reduce((s, b) => s + b.costs.slice(0, levels[b.id] ?? 0).reduce((a, c) => a + c, 0), 0);
  const needLevel = Math.max(1, ...buildings.filter((b) => levels[b.id]).map((b) => b.unlockLevel));
  const set = (id: string, d: number, max: number) =>
    setLevels((l) => ({ ...l, [id]: Math.min(max, Math.max(0, (l[id] ?? 0) + d)) }));

  const order = [...buildings].sort((a, b) => PLOTS[a.id][0] + PLOTS[a.id][1] - PLOTS[b.id][0] - PLOTS[b.id][1]);

  return (
    <div className="grid items-center gap-10 lg:grid-cols-2">
      <div className="rounded-xl border border-line bg-surface p-4">
        <svg viewBox="0 0 330 300" className="w-full" role="img" aria-label="Örnek şehir">
          {[0, 1, 2].flatMap((r) =>
            [0, 1, 2].map((c) => (
              <path key={`${c}${r}`} d={diamond(top(c, r), TW, TH)} className="fill-bg stroke-line" />
            )),
          )}
          {order.map((b) => <Plot key={b.id} id={b.id} level={levels[b.id] ?? 0} />)}
        </svg>
        <div className="mt-2 flex flex-wrap justify-between gap-2 text-sm">
          <span className="flex items-center gap-1.5 font-semibold tabular-nums">
            <Zap size={16} className="text-accent" aria-hidden /> {spent} Enerji
          </span>
          <span className="text-muted tabular-nums">
            ≈ {Math.ceil(spent / completed25)} tamamlanmış 25 dk seans · Seviye {needLevel} ({levelXp[needLevel - 1]} XP)
          </span>
        </div>
      </div>

      <ul className="space-y-2">
        {buildings.map((b) => {
          const l = levels[b.id] ?? 0;
          const max = b.costs.length;
          return (
            <li key={b.id} className="flex items-center gap-3 rounded-xl border border-line bg-surface px-4 py-3">
              <div className="min-w-0 flex-1">
                <p className="font-display font-semibold">
                  {b.name} <span className="text-sm font-normal text-muted tabular-nums">Sv {l}/{max}</span>
                </p>
                <p className="flex items-center gap-1 text-sm text-muted">
                  {b.unlockLevel > 1 && <Lock size={12} aria-hidden />}
                  {b.unlockLevel > 1 ? `Seviye ${b.unlockLevel}’de açılır · ` : ""}
                  {l < max ? `Sonraki: ${b.costs[l]} Enerji` : "Tam seviye"}
                </p>
              </div>
              <Step label={`${b.name} seviye düşür`} disabled={l === 0} onClick={() => set(b.id, -1, max)}><Minus size={16} /></Step>
              <Step label={`${b.name} yükselt`} disabled={l === max} onClick={() => set(b.id, 1, max)}><Plus size={16} /></Step>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function Step({ label, disabled, onClick, children }: { label: string; disabled: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      aria-label={label}
      disabled={disabled}
      onClick={onClick}
      className="grid size-9 place-items-center rounded-lg border border-line bg-raised text-ink transition hover:border-muted disabled:opacity-30"
    >
      {children}
    </button>
  );
}

function Plot({ id, level }: { id: string; level: number }) {
  const [c, r] = PLOTS[id];
  const t = top(c + 0.15, r + 0.15);
  const w = TW * 0.7, h = TH * 0.7;
  const [x, y] = t;
  const L: [number, number] = [x - w / 2, y + h / 2], R: [number, number] = [x + w / 2, y + h / 2], B: [number, number] = [x, y + h];
  const spring = { type: "spring", stiffness: 160, damping: 16 } as const;

  if (id === "park") {
    return (
      <g>
        <path d={diamond(t, w, h)} className={level ? "fill-ok/20" : "fill-none stroke-accent/40"} />
        {Array.from({ length: 5 }, (_, i) => {
          const a = (i / 5) * 2 * Math.PI;
          return (
            <motion.circle
              key={i} cx={x + Math.cos(a) * w * 0.22} cy={y + h / 2 + Math.sin(a) * h * 0.22 - 8}
              className="fill-ok/75" initial={false} animate={{ r: i < level ? 6 : 0 }} transition={spring}
            />
          );
        })}
      </g>
    );
  }
  if (!level) return <path d={diamond(t, w, h)} className="fill-none stroke-accent/40" />;

  const hgt = TH * (0.35 + 0.3 * level) * (id === "tower" ? 1.4 : 1);
  const up = (p: [number, number]): [number, number] => [p[0], p[1] - hgt];
  const lerp = (a: [number, number], b: [number, number], u: number, v: number): [number, number] => [
    a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u - hgt * v,
  ];
  const windows = Array.from({ length: level }, (_, f) => {
    const v0 = (f + 0.35) / (level + 0.5), v1 = (f + 0.75) / (level + 0.5);
    return ([[L, B], [B, R]] as const).map(([a, b]) =>
      pts(lerp(a, b, 0.3, v0), lerp(a, b, 0.7, v0), lerp(a, b, 0.7, v1), lerp(a, b, 0.3, v1)),
    );
  }).flat();

  return (
    <motion.g initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} transition={spring}>
      <motion.path initial={false} animate={{ d: pts(L, B, up(B), up(L)) }} transition={spring} className="fill-raised" />
      <motion.path initial={false} animate={{ d: pts(B, R, up(R), up(B)) }} transition={spring} className="fill-[#24272e]" />
      <motion.path initial={false} animate={{ d: diamond(up(t), w, h) }} transition={spring} className="fill-line" />
      {windows.map((d, i) => (
        <motion.path key={`${level}-${i}`} d={d} className="fill-accent/85" initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.15 }} />
      ))}
    </motion.g>
  );
}
