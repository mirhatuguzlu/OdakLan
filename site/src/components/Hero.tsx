"use client";

import { motion } from "motion/react";
import { ArrowDown } from "lucide-react";
import { manifest } from "@/content/manifest";
import { PhoneMock } from "./PhoneMock";

const ease = [0.22, 1, 0.36, 1] as const;
const LINES = ["Kaydırma.", "Odaklan.", "Şehrini kur."];

export function Hero() {
  const done = manifest.roadmap.filter((s) => s.done).length;
  return (
    <section className="mx-auto flex max-w-6xl flex-col items-center gap-14 px-4 py-16 sm:px-6 lg:flex-row lg:py-28">
      <div className="flex-1 text-center lg:text-left">
        <motion.p
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, ease }}
          className="inline-block rounded-full border border-pink/50 bg-pink/10 px-3.5 py-1.5 text-sm font-semibold text-pink"
        >
          v{manifest.appVersion} · Geliştiriliyor · {done}/{manifest.roadmap.length} adım
        </motion.p>
        <h1 className="mt-6 font-display text-5xl leading-[0.95] font-bold tracking-tight sm:text-7xl">
          {LINES.map((line, i) => (
            <motion.span
              key={line}
              className="text-brand block pb-1"
              initial={{ opacity: 0, y: 30, filter: "blur(8px)" }}
              animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
              transition={{ duration: 0.7, delay: 0.1 + i * 0.12, ease }}
            >
              {line}
            </motion.span>
          ))}
        </h1>
        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.8, delay: 0.5 }}
          className="mx-auto mt-6 max-w-xl text-lg leading-relaxed text-muted lg:mx-0"
        >
          OdakLan, telefona dokunmadan geçirdiğin her dakikayı oyuna çeviren bir odak
          RPG&apos;si. Arkadaşlarınla Odak Klanı kur; biri TikTok&apos;a dalarsa ortak kale
          hasar alır.
        </motion.p>
        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, delay: 0.65, ease }}
          className="mt-8 flex flex-wrap justify-center gap-3 lg:justify-start"
        >
          <a
            href="#ozellikler"
            className="inline-flex items-center gap-2 rounded-full bg-cyan px-6 py-3.5 font-bold text-bg transition hover:shadow-[0_0_28px_rgba(0,240,255,0.6)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cyan"
          >
            <ArrowDown size={18} aria-hidden /> Nasıl çalışır?
          </a>
          {/* No store listing yet: shown as disabled, not as fake links. */}
          {["Google Play", "App Store"].map((s) => (
            <span
              key={s}
              aria-disabled="true"
              className="rounded-full border border-line px-6 py-3.5 text-muted"
            >
              {s} — yakında
            </span>
          ))}
        </motion.div>
      </div>
      <PhoneMock />
    </section>
  );
}
