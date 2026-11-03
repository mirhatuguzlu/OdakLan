import type { Metadata, Viewport } from "next";
import { Geist, Space_Grotesk } from "next/font/google";
import { MotionRoot } from "@/components/MotionRoot";
import "./globals.css";

// next/font downloads these at build time and self-hosts them:
// visitors never contact Google.
const body = Geist({ variable: "--font-body", subsets: ["latin", "latin-ext"] });
const display = Space_Grotesk({
  variable: "--font-display",
  subsets: ["latin", "latin-ext"],
});

const title = "OdakLan — Kaydırma. Odaklan. Şehrini kur.";
const description =
  "OdakLan, telefona dokunmadan geçirdiğin her dakikayı oyuna çeviren bir odak RPG'si. Arkadaşlarınla Odak Klanı kur, birlikte odaklan.";

export const metadata: Metadata = {
  title,
  description,
  openGraph: { title, description, type: "website", locale: "tr_TR" },
  twitter: { card: "summary_large_image", title, description },
};

export const viewport: Viewport = { themeColor: "#0b0b14" };

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="tr" className={`${body.variable} ${display.variable} antialiased`}>
      <body className="min-h-dvh font-sans">
        <MotionRoot>{children}</MotionRoot>
      </body>
    </html>
  );
}
