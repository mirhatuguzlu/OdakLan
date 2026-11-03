"use client";

import { useEffect, useRef } from "react";

/**
 * Full-screen synthwave floor grid + drifting glow orbs on a canvas.
 * Pauses when the tab is hidden; draws one still frame under reduced motion.
 */
export function NeonGrid() {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    const ctx = canvas?.getContext("2d");
    if (!canvas || !ctx) return;

    const reduce = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    let raf = 0;
    let w = 0;
    let h = 0;

    const resize = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      w = window.innerWidth;
      h = window.innerHeight;
      canvas.width = w * dpr;
      canvas.height = h * dpr;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };

    const orb = (color: string, t: number, phase: number, r: number) => {
      const x = w * (0.5 + 0.35 * Math.sin(t * 0.15 + phase));
      const y = h * (0.3 + 0.2 * Math.cos(t * 0.12 + phase * 1.7));
      const g = ctx.createRadialGradient(x, y, 0, x, y, r);
      g.addColorStop(0, color);
      g.addColorStop(1, "transparent");
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, w, h);
    };

    const draw = (ms: number) => {
      const t = ms / 1000;
      ctx.fillStyle = "#0b0b14";
      ctx.fillRect(0, 0, w, h);

      const r = Math.min(w, h) * 0.6;
      orb("rgba(0,240,255,0.22)", t, 0, r);
      orb("rgba(255,46,136,0.2)", t, 2.1, r * 0.9);
      orb("rgba(139,92,255,0.2)", t, 4.2, r * 0.8);

      const horizon = h * 0.58;
      const floor = h - horizon;
      const scroll = (t * 0.25) % 1;
      ctx.lineWidth = 1;
      for (let i = 0; i < 18; i++) {
        const z = (i + scroll) / 18;
        const y = horizon + floor * z * z;
        ctx.strokeStyle = `rgba(0,240,255,${0.04 + 0.22 * z})`;
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(w, y);
        ctx.stroke();
      }
      const cx = w / 2;
      ctx.strokeStyle = "rgba(255,46,136,0.16)";
      for (let i = -12; i <= 12; i++) {
        ctx.beginPath();
        ctx.moveTo(cx + i * 8, horizon);
        ctx.lineTo(cx + (i * w) / 10, h);
        ctx.stroke();
      }
      const fade = ctx.createLinearGradient(0, horizon - 40, 0, horizon + 80);
      fade.addColorStop(0, "#0b0b14");
      fade.addColorStop(1, "rgba(11,11,20,0)");
      ctx.fillStyle = fade;
      ctx.fillRect(0, horizon - 40, w, 120);
    };

    const loop = (ms: number) => {
      draw(ms);
      raf = requestAnimationFrame(loop);
    };
    const onVisibility = () => {
      cancelAnimationFrame(raf);
      if (!document.hidden && !reduce) raf = requestAnimationFrame(loop);
    };
    const onResize = () => {
      resize();
      if (reduce) draw(0);
    };

    resize();
    if (reduce) draw(0);
    else raf = requestAnimationFrame(loop);
    window.addEventListener("resize", onResize);
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", onResize);
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, []);

  return <canvas ref={ref} aria-hidden className="fixed inset-0 -z-10 h-full w-full" />;
}
