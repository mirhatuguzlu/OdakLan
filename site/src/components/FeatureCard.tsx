"use client";

import {
  Ban, Building2, Flame, Lock, Radar, ShieldCheck, Sparkles, Timer, Users,
  type LucideIcon,
} from "lucide-react";
import type { Feature, FeatureStatus } from "@/content/manifest";

const ICONS: Record<string, LucideIcon> = {
  focus_session: Timer,
  anti_doomscroll: Ban,
  city: Building2,
  clans: Users,
  fair_rewards: ShieldCheck,
  quests: Flame,
  social_detect: Radar,
  privacy: Lock,
};

const STATUS: Record<FeatureStatus, [string, string]> = {
  live: ["Yayında", "text-ok"],
  inProgress: ["Geliştiriliyor", "text-pink"],
  planned: ["Yakında", "text-muted"],
};

/** Card with a cursor-following neon spotlight. */
export function FeatureCard({ feature }: { feature: Feature }) {
  const Icon = ICONS[feature.id] ?? Sparkles;
  const [label, color] = STATUS[feature.status];

  return (
    <article
      onPointerMove={(e) => {
        const r = e.currentTarget.getBoundingClientRect();
        e.currentTarget.style.setProperty("--x", `${e.clientX - r.left}px`);
        e.currentTarget.style.setProperty("--y", `${e.clientY - r.top}px`);
      }}
      className="group relative h-full overflow-hidden rounded-2xl border border-line bg-surface/75 p-6 backdrop-blur transition duration-300 hover:-translate-y-1.5 hover:border-cyan/70 hover:shadow-[0_0_32px_rgba(0,240,255,0.2)]"
    >
      <div
        aria-hidden
        className="pointer-events-none absolute inset-0 opacity-0 transition-opacity duration-300 group-hover:opacity-100"
        style={{
          background:
            "radial-gradient(260px circle at var(--x) var(--y), rgba(0,240,255,0.12), transparent 70%)",
        }}
      />
      <div className="relative">
        <div className="flex items-center">
          <Icon className="text-cyan" size={30} aria-hidden />
          <span className={`ml-auto text-xs font-bold ${color}`}>{label}</span>
        </div>
        <h3 className="mt-5 font-display text-xl font-bold">{feature.title}</h3>
        <p className="mt-2 leading-relaxed text-muted">{feature.description}</p>
        {feature.platformNote && (
          <p className="mt-3 text-xs font-semibold text-pink">{feature.platformNote}</p>
        )}
      </div>
    </article>
  );
}
