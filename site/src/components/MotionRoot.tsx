"use client";

import { MotionConfig } from "motion/react";

/** Every Motion animation honours the OS "reduce motion" setting. */
export function MotionRoot({ children }: { children: React.ReactNode }) {
  return <MotionConfig reducedMotion="user">{children}</MotionConfig>;
}
