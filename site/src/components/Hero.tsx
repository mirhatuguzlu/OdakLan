"use client";

import { motion, useReducedMotion } from "motion/react";
import { ArrowDown, Building2, Sparkles, Zap } from "lucide-react";
import { manifest } from "@/content/manifest";

// MotionSites "Agent Wave" layout: one dark viewport, copy anchored to the bottom, three plain stats.
// Free background loop from motionsites.ai/backgrounds ("Eclipse Ring").
const VIDEO =
  "https://d8j0ntlcm91z4.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/hf_20261021_005636_b3cfb8b5-d8a7-4627-b543-4194e24ab5b7.mp4";

const ease = [0.16, 1, 0.3, 1] as const;

export function Hero() {
  const reduce = useReducedMotion();
  const done = manifest.roadmap.filter((s) => s.done).length;
  const ready = manifest.features.filter((f) => f.status === "ready" || f.status === "live").length;
  const stats = [
    [Zap, `${manifest.focusRules.energyBlockMinutes} dakika odak = 1 Enerji`],
    [Building2, `${manifest.city.buildings.length} farklı güce sahip bina`],
    [Sparkles, `${ready} özellik hazır, ${manifest.features.length - ready} yolda`],
  ] as const;
  const rise = (delay: number, y = 14) => ({
    initial: { opacity: 0, y },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 1.05, delay, ease },
  });

  return (
    <section className="relative isolate flex min-h-[calc(100dvh-4rem)] flex-col overflow-hidden">
      {!reduce && (
        <video
          // The clip's top is empty black: push it down so the arc glows under the buttons, not behind the copy.
          className="absolute inset-x-0 top-[12%] -z-10 h-full w-full object-cover object-top opacity-90 [mask-image:linear-gradient(to_bottom,transparent,#000_30%)]"
          src={VIDEO}
          autoPlay
          muted
          loop
          playsInline
          preload="auto"
          aria-hidden
        />
      )}
      {/* Scrim: keeps the copy readable and melts the hero into the page below. */}
      <div
        className="absolute inset-0 -z-10 bg-[linear-gradient(to_bottom,rgb(13_14_17/0.6),transparent_40%,transparent_82%,var(--color-bg))]"
        aria-hidden
      />

      <div className="mx-auto flex w-full max-w-4xl flex-1 flex-col items-center justify-end px-5 pt-16 pb-14 text-center sm:pb-20">
        <motion.p
          {...rise(0.22)}
          className="inline-flex items-center gap-2 rounded-md bg-[linear-gradient(90deg,#7d7d7d,#2a2a2a_52%,#0a0a0a)] px-4 py-2 text-[13px] text-ink"
        >
          <span className="size-1.5 rounded-full bg-accent shadow-[0_0_8px_var(--color-accent)]" aria-hidden />
          v{manifest.appVersion} · Geliştiriliyor · {done}/{manifest.roadmap.length} adım
        </motion.p>

        <h1 className="mt-6 font-display text-[clamp(2.6rem,7vw,5.25rem)] leading-[1.02] font-semibold tracking-[-0.045em]">
          <MaskLine delay={0.42}>Kaydırma.</MaskLine>
          <MaskLine delay={0.62}>
            <em className="font-serif text-[1.08em] font-normal tracking-[-0.02em] text-accent">Odaklan.</em>{" "}
            Şehrini kur.
          </MaskLine>
        </h1>

        <motion.p {...rise(0.82)} className="mt-5 max-w-xl text-lg leading-relaxed text-muted">
          Telefona dokunmadan geçirdiğin her dakika oyuna dönüşür. Arkadaşlarınla Odak Klanı kur;
          biri TikTok&apos;a dalarsa ortak kale hasar alır.
        </motion.p>

        <motion.div {...rise(0.96, 18)} className="mt-8 flex flex-wrap justify-center gap-2.5">
          <a
            href="#nasil-calisir"
            className="inline-flex h-12 items-center gap-2 rounded-md border border-white bg-[linear-gradient(180deg,#fff,#e7e7e7_48%,#cfcfcf)] px-5 font-medium text-[#111] shadow-[inset_0_1px_0_#fff] transition hover:shadow-[inset_0_1px_0_#fff,0_0_26px_rgb(245_165_36/0.45)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
          >
            <ArrowDown size={18} aria-hidden /> Nasıl çalışır?
          </a>
          {/* No store listing yet: shown as disabled, not as fake links. */}
          <span
            aria-disabled="true"
            className="inline-flex h-12 items-center rounded-md border border-white/30 bg-[linear-gradient(135deg,rgb(255_255_255/0.12),rgb(0_0_0/0.5)_46%,rgb(150_170_200/0.1))] px-5 text-ink/80 backdrop-blur-xl"
          >
            Google Play · App Store yakında
          </span>
        </motion.div>
      </div>

      <ul className="flex flex-col items-center gap-4 px-5 pb-8 text-[15px] text-[#d8d8d8] sm:flex-row sm:justify-between sm:px-10 lg:px-16">
        {stats.map(([Icon, label], i) => (
          <motion.li key={label} {...rise(1.12 + i * 0.16, 20)} className="flex items-center gap-3">
            <span className="grid size-7 place-items-center rounded-md border border-white/15 bg-white/5">
              <Icon size={15} className="text-accent" aria-hidden />
            </span>
            {label}
          </motion.li>
        ))}
      </ul>
    </section>
  );
}

/** A headline line that rises out of its own slot. */
function MaskLine({ delay, children }: { delay: number; children: React.ReactNode }) {
  return (
    <span className="block overflow-hidden px-[0.1em] pb-[0.12em]">
      <motion.span
        className="block"
        initial={{ opacity: 0, y: "60%" }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 1.05, delay, ease }}
      >
        {children}
      </motion.span>
    </span>
  );
}
