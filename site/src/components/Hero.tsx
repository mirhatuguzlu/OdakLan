"use client";

import { motion } from "motion/react";
import { ArrowDown } from "lucide-react";
import { manifest } from "@/content/manifest";
import { PhoneMock } from "./PhoneMock";

const ease = [0.22, 1, 0.36, 1] as const;

export function Hero() {
  const done = manifest.roadmap.filter((s) => s.done).length;
  const fadeUp = (delay: number) => ({
    initial: { opacity: 0, y: 16 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.6, delay, ease },
  });

  return (
    <section className="mx-auto flex max-w-6xl flex-col items-center gap-16 px-4 py-16 sm:px-6 lg:flex-row lg:py-28">
      <div className="flex-1 text-center lg:text-left">
        <motion.p
          {...fadeUp(0)}
          className="inline-flex items-center gap-2 rounded-full border border-line bg-surface px-3 py-1 text-sm text-muted"
        >
          <span className="size-1.5 rounded-full bg-accent" aria-hidden />
          v{manifest.appVersion} · Geliştiriliyor · {done}/{manifest.roadmap.length} adım
        </motion.p>
        <motion.h1
          {...fadeUp(0.08)}
          className="mt-6 font-display text-5xl leading-[1.02] font-bold tracking-tight sm:text-7xl"
        >
          Kaydırma.
          <br />
          <span className="text-accent">Odaklan.</span>
          <br />
          <span className="text-muted">Şehrini kur.</span>
        </motion.h1>
        <motion.p
          {...fadeUp(0.18)}
          className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-muted lg:mx-0"
        >
          OdakLan, telefona dokunmadan geçirdiğin her dakikayı oyuna çeviren bir odak
          RPG&apos;si. Arkadaşlarınla Odak Klanı kur; biri TikTok&apos;a dalarsa ortak kale
          hasar alır.
        </motion.p>
        <motion.div
          {...fadeUp(0.28)}
          className="mt-8 flex flex-wrap justify-center gap-3 lg:justify-start"
        >
          <a
            href="#ozellikler"
            className="inline-flex items-center gap-2 rounded-lg bg-accent px-5 py-3 font-semibold text-bg transition hover:brightness-110 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
          >
            <ArrowDown size={18} aria-hidden /> Nasıl çalışır?
          </a>
          {/* No store listing yet: shown as disabled, not as fake links. */}
          {["Google Play", "App Store"].map((s) => (
            <span
              key={s}
              aria-disabled="true"
              className="rounded-lg border border-line px-5 py-3 text-muted"
            >
              {s} · yakında
            </span>
          ))}
        </motion.div>
      </div>
      <PhoneMock />
    </section>
  );
}
