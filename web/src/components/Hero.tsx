"use client";

import { motion, useReducedMotion } from "motion/react";
import { PhoneMock } from "./PhoneMock";

export function Hero() {
  const reduce = useReducedMotion();

  return (
    <section className="relative overflow-hidden">
      <div className="grid-bg absolute inset-0" aria-hidden />
      <motion.div
        aria-hidden
        className="absolute -top-40 left-1/2 h-[520px] w-[520px] -translate-x-1/2 rounded-full bg-pink/20 blur-3xl"
        animate={reduce ? undefined : { scale: [1, 1.15, 1], opacity: [0.5, 0.8, 0.5] }}
        transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
      />

      <div className="relative mx-auto grid max-w-6xl items-center gap-12 px-4 pt-24 pb-20 sm:px-6 md:grid-cols-2 md:pt-32">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, ease: "easeOut" }}
        >
          <span className="inline-block rounded-full border border-line bg-surface px-3 py-1 font-mono text-xs text-cyan">
            Anti-Doomscroll RPG
          </span>
          <h1 className="mt-6 text-4xl font-bold leading-tight tracking-tight sm:text-6xl">
            Telefonu bırak.
            <br />
            <span className="neon-text">Şehrini kur.</span>
          </h1>
          <p className="mt-6 max-w-md text-lg text-muted">
            OdakLan, telefona dokunmadan geçirdiğin her dakikayı oyuna çevirir. Arkadaşlarınla Odak
            Klanı kur; biri TikTok&apos;a kaçarsa ortak kale hasar alır.
          </p>
          <div className="mt-8 flex flex-wrap gap-3">
            <a
              href="#ozellikler"
              className="rounded-xl bg-cyan px-5 py-3 font-semibold text-bg transition hover:shadow-[0_0_24px_var(--color-cyan)]"
            >
              Nasıl çalışır?
            </a>
            <a
              href="#yol-haritasi"
              className="rounded-xl border border-line px-5 py-3 font-semibold transition hover:border-pink hover:text-pink"
            >
              Yol haritası
            </a>
          </div>
        </motion.div>

        <motion.div
          className="flex justify-center"
          initial={{ opacity: 0, scale: 0.9, rotate: -4 }}
          animate={{ opacity: 1, scale: 1, rotate: 0 }}
          transition={{ duration: 0.9, ease: "easeOut", delay: 0.15 }}
        >
          <PhoneMock />
        </motion.div>
      </div>
    </section>
  );
}
