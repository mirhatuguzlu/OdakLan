import { Check, Menu, TrendingDown, UserPlus, Wrench, Trophy, Zap } from "lucide-react";
import { ClanDemo } from "@/components/ClanDemo";
import { FeatureCard } from "@/components/FeatureCard";
import { Hero } from "@/components/Hero";
import { HowItWorks } from "@/components/HowItWorks";
import { Reveal } from "@/components/Reveal";
import { manifest } from "@/content/manifest";

const NAV = [
  ["#nasil-calisir", "Nasıl çalışır"],
  ["#ozellikler", "Özellikler"],
  ["#klanlar", "Klanlar"],
  ["#yol-haritasi", "Yol haritası"],
] as const;

export default function Home() {
  return (
    <>
      <Nav />
      <main>
        <Hero />
        <How />
        <Features />
        <Clans />
        <Roadmap />
      </main>
      <Footer />
    </>
  );
}

function Nav() {
  return (
    <header className="sticky top-0 z-50 border-b border-line bg-bg/80 backdrop-blur-md">
      <nav className="mx-auto flex h-16 max-w-6xl items-center px-4 sm:px-6" aria-label="Ana menü">
        <a href="#" className="flex items-center gap-1.5 font-display text-xl font-bold">
          <Zap className="text-accent" size={20} fill="currentColor" aria-hidden />
          OdakLan
        </a>
        <ul className="ml-auto hidden gap-8 md:flex">
          {NAV.map(([href, label]) => (
            <li key={href}>
              <a href={href} className="text-sm text-muted transition hover:text-ink">
                {label}
              </a>
            </li>
          ))}
        </ul>
        {/* JS-free mobile menu. */}
        <details className="relative ml-auto md:hidden">
          <summary className="cursor-pointer list-none p-2" aria-label="Menüyü aç">
            <Menu aria-hidden />
          </summary>
          <ul className="absolute right-0 mt-2 w-48 rounded-xl border border-line bg-surface p-2 shadow-xl">
            {NAV.map(([href, label]) => (
              <li key={href}>
                <a href={href} className="block rounded-lg px-3 py-2 hover:bg-line">
                  {label}
                </a>
              </li>
            ))}
          </ul>
        </details>
      </nav>
    </header>
  );
}

function SectionTitle({ eyebrow, title, subtitle }: { eyebrow: string; title: string; subtitle: string }) {
  return (
    <Reveal className="mb-12 text-center">
      <p className="text-sm font-semibold tracking-[0.2em] text-accent uppercase">{eyebrow}</p>
      <h2 className="mt-3 font-display text-3xl font-bold tracking-tight sm:text-4xl">{title}</h2>
      <p className="mx-auto mt-3 max-w-2xl text-lg text-muted">{subtitle}</p>
    </Reveal>
  );
}

function How() {
  return (
    <section id="nasil-calisir" className="mx-auto max-w-6xl px-4 py-24 sm:px-6">
      <SectionTitle
        eyebrow="Nasıl çalışır"
        title="Basit kurallar, gerçek sonuçlar"
        subtitle="Odaklandığın süre ödüle dönüşür; kaçtığın an seans biter."
      />
      <HowItWorks />
    </section>
  );
}

function Features() {
  return (
    <section id="ozellikler" className="mx-auto max-w-6xl px-4 py-24 sm:px-6">
      <SectionTitle
        eyebrow="Özellikler"
        title="Dikkat dağıtıcıları oyuna çevir"
        subtitle="Forest'ın sadeliği, Habitica'nın RPG ruhu ve arkadaş grubunun gücü tek uygulamada."
      />
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {manifest.features.map((f, i) => (
          <Reveal key={f.id} delay={(i % 4) * 0.06}>
            <FeatureCard feature={f} />
          </Reveal>
        ))}
      </div>
    </section>
  );
}

const CLAN_POINTS = [
  [UserPlus, "Davet koduyla arkadaşlarını klana çağır."],
  [TrendingDown, "Biri seansı bozarsa ortak kale can kaybeder."],
  [Wrench, "Odaklanan herkes kaleyi onarır, klan puanı kazanır."],
  [Trophy, "Klanlar haftalık liderlik tablosunda yarışır."],
] as const;

function Clans() {
  return (
    <section id="klanlar" className="mx-auto max-w-6xl px-4 py-24 sm:px-6">
      <SectionTitle
        eyebrow="Odak Klanları"
        title="Arkadaş grubunu rezil etme"
        subtitle="Akran baskısını verimliliğe çeviren sosyal hesap verebilirlik."
      />
      <div className="grid items-center gap-12 lg:grid-cols-2">
        <ul className="space-y-5">
          {CLAN_POINTS.map(([Icon, text], i) => (
            <Reveal key={text} delay={i * 0.08}>
              <li className="flex items-center gap-4 text-lg">
                <span className="grid size-10 shrink-0 place-items-center rounded-lg border border-line bg-surface"><Icon size={18} aria-hidden /></span> {text}
              </li>
            </Reveal>
          ))}
        </ul>
        <Reveal>
          <ClanDemo />
        </Reveal>
      </div>
    </section>
  );
}

function Roadmap() {
  const current = manifest.roadmap.find((s) => !s.done);
  return (
    <section id="yol-haritasi" className="mx-auto max-w-6xl px-4 py-24 sm:px-6">
      <SectionTitle
        eyebrow="Yol haritası"
        title="Açık geliştiriliyor"
        subtitle="Bu sayfa uygulamayla aynı kaynaktan beslenir; her adımda güncellenir."
      />
      <ol className="mx-auto max-w-xl">
        {manifest.roadmap.map((s, i) => {
          const isCurrent = s === current;
          const last = i === manifest.roadmap.length - 1;
          return (
            <Reveal key={s.number} delay={i * 0.04}>
              <li className="flex gap-5" aria-current={isCurrent ? "step" : undefined}>
                <div className="flex flex-col items-center">
                  <span
                    className={`grid size-7 shrink-0 place-items-center rounded-full border-2 ${
                      s.done
                        ? "border-ok bg-ok text-bg"
                        : isCurrent
                          ? "border-accent"
                          : "border-line"
                    }`}
                  >
                    {s.done && <Check size={16} aria-label="tamamlandı" />}
                  </span>
                  {!last && <span className="w-0.5 flex-1 bg-line" />}
                </div>
                <p className="pb-7 text-lg">
                  <span
                    className={`mr-2 font-bold ${s.done ? "text-ok" : isCurrent ? "text-accent" : "text-muted"}`}
                  >
                    Adım {s.number}
                  </span>
                  {s.title}
                  {isCurrent && <span className="ml-2 rounded-full bg-accent/15 px-2 py-0.5 text-xs font-medium text-accent">şu an</span>}
                </p>
              </li>
            </Reveal>
          );
        })}
      </ol>
    </section>
  );
}

function Footer() {
  return (
    <footer className="border-t border-line bg-bg">
      <div className="mx-auto flex max-w-6xl flex-wrap justify-between gap-4 px-4 py-10 text-muted sm:px-6">
        <p>© {new Date().getFullYear()} OdakLan</p>
        <p>Reklam yok · Veri satışı yok · KVKK uyumlu tasarım</p>
      </div>
    </footer>
  );
}
