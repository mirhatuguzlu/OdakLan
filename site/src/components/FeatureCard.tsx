import {
  Ban, Building2, ChartColumn, Handshake, Flame, Lock, Radar, ShieldCheck, Sparkles, Timer, Users,
  type LucideIcon,
} from "lucide-react";
import type { Feature, FeatureStatus } from "@/content/manifest";

const ICONS: Record<string, LucideIcon> = {
  focus_session: Timer,
  anti_doomscroll: Ban,
  city: Building2,
  focus_contract: Handshake,
  focus_map: ChartColumn,
  clans: Users,
  fair_rewards: ShieldCheck,
  quests: Flame,
  social_detect: Radar,
  privacy: Lock,
};

const STATUS: Record<FeatureStatus, [string, string]> = {
  live: ["Yayında", "border-ok/40 text-ok"],
  ready: ["Uygulamada hazır", "border-ok/40 text-ok"],
  inProgress: ["Geliştiriliyor", "border-accent/40 text-accent"],
  planned: ["Yakında", "border-line text-muted"],
};

export function FeatureCard({ feature }: { feature: Feature }) {
  const Icon = ICONS[feature.id] ?? Sparkles;
  const [label, badge] = STATUS[feature.status];

  return (
    <article className="h-full rounded-xl border border-line bg-surface p-6 transition-colors duration-200 hover:border-muted/50 hover:bg-raised">
      <div className="flex items-center">
        <span className="grid size-10 place-items-center rounded-lg bg-raised">
          <Icon className="text-ink" size={20} aria-hidden />
        </span>
        <span className={`ml-auto rounded-full border px-2.5 py-0.5 text-xs font-medium ${badge}`}>
          {label}
        </span>
      </div>
      <h3 className="mt-5 font-display text-lg font-semibold">{feature.title}</h3>
      <p className="mt-2 text-sm leading-relaxed text-muted">{feature.description}</p>
      {feature.platformNote && (
        <p className="mt-3 text-xs font-medium text-muted">● {feature.platformNote}</p>
      )}
    </article>
  );
}
