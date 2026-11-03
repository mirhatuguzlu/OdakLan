import { Hero } from "@/components/Hero";
import { Features, HowItWorks, Roadmap } from "@/components/Sections";

export default function Home() {
  return (
    <main className="flex-1">
      <Hero />
      <Features />
      <HowItWorks />
      <Roadmap />
      <footer className="border-t border-line py-10 text-center text-sm text-muted">
        <p>
          <span className="neon-text font-semibold">OdakLan</span> · Takip yok, reklam yok. Sadece
          odak.
        </p>
      </footer>
    </main>
  );
}
