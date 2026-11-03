"use client";

import { motion } from "motion/react";
import { features, roadmap, statusLabel, type Status } from "@/content/features";

const badge: Record<Status, string> = {
  live: "border-ok/40 text-ok",
  building: "border-cyan/40 text-cyan",
  planned: "border-line text-muted",
};

const reveal = {
  initial: { opacity: 0, y: 24 },
  whileInView: { opacity: 1, y: 0 },
  viewport: { once: true, margin: "-60px" },
};

function Heading({ kicker, title }: { kicker: string; title: string }) {
  return (
    <motion.div {...reveal} transition={{ duration: 0.5 }} className="mb-12 text-center">
      <p className="font-mono text-sm text-pink">{kicker}</p>
      <h2 className="mt-2 text-3xl font-bold sm:text-4xl">{title}</h2>
    </motion.div>
  );
}

export function Features() {
  return (
    <section id="ozellikler" className="mx-auto max-w-6xl px-4 py-24 sm:px-6">
      <Heading kicker="// özellikler" title="Odaklanmak hiç bu kadar oyun olmamıştı" />
      <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {features.map((f, i) => (
          <motion.article
            key={f.id}
            {...reveal}
            transition={{ duration: 0.5, delay: i * 0.08 }}
            whileHover={{ y: -6 }}
            className="group rounded-2xl border border-line bg-surface p-6 transition-colors hover:border-cyan/60"
          >
            <div className="flex items-start justify-between">
              <span className="text-3xl" aria-hidden>
                {f.icon}
              </span>
              <span className={`rounded-full border px-2.5 py-0.5 text-xs ${badge[f.status]}`}>
                {statusLabel[f.status]}
              </span>
            </div>
            <h3 className="mt-4 text-lg font-semibold group-hover:text-cyan">{f.title}</h3>
            <p className="mt-2 text-sm leading-relaxed text-muted">{f.description}</p>
          </motion.article>
        ))}
      </div>
    </section>
  );
}

const steps = [
  { n: "01", t: "Seansı başlat", d: "Ne kadar odaklanacağını seç ve telefonu bırak." },
  { n: "02", t: "Kaynak topla", d: "Her 10 dakika Enerji ve XP olarak hesabına yazılır." },
  { n: "03", t: "Şehrini ve klanını büyüt", d: "Binalar kur, klan kalesini birlikte güçlendirin." },
];

export function HowItWorks() {
  return (
    <section className="border-y border-line bg-surface/40 py-24">
      <div className="mx-auto max-w-6xl px-4 sm:px-6">
        <Heading kicker="// nasıl çalışır" title="Üç adımda doomscroll'a son" />
        <div className="grid gap-8 md:grid-cols-3">
          {steps.map((s, i) => (
            <motion.div key={s.n} {...reveal} transition={{ duration: 0.5, delay: i * 0.12 }}>
              <p className="neon-text font-mono text-5xl font-bold">{s.n}</p>
              <h3 className="mt-3 text-xl font-semibold">{s.t}</h3>
              <p className="mt-2 text-muted">{s.d}</p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}

export function Roadmap() {
  const done = roadmap.filter((m) => m.status === "live").length;

  return (
    <section id="yol-haritasi" className="mx-auto max-w-3xl px-4 py-24 sm:px-6">
      <Heading kicker="// yol haritası" title="Uygulama şu an nerede?" />
      <div className="mb-10 h-2 overflow-hidden rounded-full bg-line" aria-label={`${done}/${roadmap.length} adım tamamlandı`}>
        <motion.div
          className="h-full bg-gradient-to-r from-cyan to-pink"
          initial={{ width: 0 }}
          whileInView={{ width: `${(done / roadmap.length) * 100}%` }}
          viewport={{ once: true }}
          transition={{ duration: 1.2, ease: "easeOut" }}
        />
      </div>
      <ol className="relative space-y-6 border-l border-line pl-8">
        {roadmap.map((m, i) => (
          <motion.li
            key={m.step}
            initial={{ opacity: 0, x: -16 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.4, delay: i * 0.05 }}
            className="relative"
          >
            <span
              className={`absolute -left-[41px] top-1 h-4 w-4 rounded-full border-2 ${
                m.status === "live"
                  ? "border-ok bg-ok"
                  : m.status === "building"
                    ? "animate-pulse border-cyan bg-cyan/40"
                    : "border-line bg-bg"
              }`}
              aria-hidden
            />
            <div className="flex flex-wrap items-center gap-3">
              <span className="font-mono text-sm text-muted">Adım {m.step}</span>
              <span className={`rounded-full border px-2 py-0.5 text-xs ${badge[m.status]}`}>
                {statusLabel[m.status]}
              </span>
            </div>
            <p className="mt-1 font-medium">{m.title}</p>
          </motion.li>
        ))}
      </ol>
    </section>
  );
}
