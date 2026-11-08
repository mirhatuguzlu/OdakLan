#!/usr/bin/env sh
# Rebuilds the game rules for the `game` Edge Function. Run after changing
# anything in lib/, then deploy: supabase functions deploy game
set -e
cd "$(dirname "$0")/.."
dart compile js -O2 --no-source-maps -o ../../supabase/functions/game/core.js bin/game_server.dart
rm -f ../../supabase/functions/game/core.js.deps
