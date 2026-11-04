// Same coverage as eslint-config-next (Next, React, hooks, a11y, TS) but built from
// plugins without the vulnerable minimatch@3 chain (GHSA-g3hv-75wg-m249).
import { defineConfig, globalIgnores } from "eslint/config";
import nextPlugin from "@next/eslint-plugin-next";
import reactPlugin from "@eslint-react/eslint-plugin";
import reactHooks from "eslint-plugin-react-hooks";
import jsxA11y from "eslint-plugin-jsx-a11y-x";
import tseslint from "typescript-eslint";

export default defineConfig([
  tseslint.configs.recommended,
  reactPlugin.configs["recommended-typescript"],
  reactHooks.configs.flat["recommended-latest"],
  jsxA11y.configs.recommended,
  nextPlugin.configs["core-web-vitals"],
  globalIgnores([".next/**", "out/**", "build/**", "next-env.d.ts"]),
]);
