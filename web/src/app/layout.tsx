import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

// next/font self-hosts these at build time; no request goes to Google at runtime.
const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin", "latin-ext"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin", "latin-ext"],
});

export const metadata: Metadata = {
  title: "OdakLan — Odaklan, şehrini kur, klanını koru",
  description:
    "Telefona dokunmadan geçirdiğin her dakika siberpunk şehrini büyütür. Arkadaşlarınla Odak Klanı kur, birlikte odaklanın.",
  openGraph: {
    title: "OdakLan",
    description: "Doomscroll'a karşı oyunlaştırılmış odak uygulaması.",
    locale: "tr_TR",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#0b0b14",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="tr"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col font-sans">{children}</body>
    </html>
  );
}
