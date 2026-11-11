#!/usr/bin/env bash
#
# The development server under Serverpod's runner, with hot reload.
#
# `serverpod start` keeps the server running, watches the source, and reloads
# the running isolate when a file changes: about 1.5 s from saving to the server
# answering with the change, against 10-20 s for a restart. This script is that
# with this project's settings filled in. It reads the runner's log and, through
# tool/mcp.py, calls the runner's MCP tools, so the whole loop works from a
# shell: no terminal UI, and no MCP server registered with the agent (which is
# not allowed here).
#
# Usage:
#   ./tool/dev.sh up [-- <server args>]   start in the background, print the URLs
#   ./tool/dev.sh down                    stop it
#   ./tool/dev.sh hot-restart             restart the server process inside the
#                                         runner, about 1 s (after changing
#                                         main() or anything a reload keeps)
#   ./tool/dev.sh restart                 down, then up, about 20 s (to pick up
#                                         changed environment variables)
#   ./tool/dev.sh status                  running or not, ports, VM service
#   ./tool/dev.sh last                    what the most recent reload did:
#                                         "Server reloaded", or the compile
#                                         errors with file and line. Exits 1 on
#                                         a failed compile. Run it after an edit.
#   ./tool/dev.sh logs [N]                last N lines of the runner log (80)
#   ./tool/dev.sh logs -f                 follow it
#   ./tool/dev.sh requests [N]            the server's own log, one line per
#                                         request or message, with durations
#   ./tool/dev.sh migrate [tag]           create a migration and apply it
#   ./tool/dev.sh app                     run the Flutter app in Chrome on 8083,
#                                         hot-reloading with the server
#   ./tool/dev.sh app-logs [N]            its output
#   ./tool/dev.sh app-errors              its runtime errors, via Dart's MCP
#                                         server (tool/mcp.py has the rest:
#                                         widget tree, analysis, ...)
#   ./tool/dev.sh ui                      the terminal UI, which also runs the
#                                         Flutter app in Chrome on 8083 with
#                                         hot reload; joins a running server
#
# Environment is inherited by the server, so the usual switches work:
#   FLUMIP_PUBLIC_MODE=true ./tool/dev.sh up
#
# Three things that are not obvious:
#
# - The runner always starts the server with --apply-migrations. That suits the
#   disposable development database, and it is the opposite of the "Server"
#   launch configuration, which leaves the schema alone on purpose.
# - --no-docker is passed everywhere. Left to itself the runner brings up the
#   compose file without `--profile dev`. Start the database yourself:
#   docker compose --profile dev up -d postgres redis
# - A failed compile leaves the previous code running and says so only in the
#   log. `last` is how to find out.
#
set -euo pipefail

cd "$(dirname "$0")/.."

# Neither dart nor the serverpod CLI is on PATH in a default shell here.
# Appended, so an SDK or CLI that is already on PATH wins.
PATH="$PATH:$HOME/frameworks/flutter/bin:$HOME/.local/state/Dart/install/bin"
export PATH

LOG=.dart_tool/serverpod/runner.log
SP=(serverpod --no-analytics)

command -v serverpod >/dev/null || {
  echo "The serverpod CLI is not installed. Run: dart install serverpod_cli <version in pubspec.yaml>" >&2
  exit 127
}

# The runner's own lines for the most recent change cycle, or for startup if
# nothing has changed yet. The server's request log shares the file and is left
# out; `logs` shows it.
last_cycle() {
  [ -f "$LOG" ] || return 0
  awk '
    /--- serverpod runner [0-9]+ started ---/ { buf = ""; next }
    /\[SCOPE\] Analyzing changes started/      { buf = "" }
    /^[0-9-]+T[0-9:.]+ \[/                     { buf = buf $0 "\n" }
    END { printf "%s", buf }
  ' "$LOG"
}

# True while a source file is newer than the start of the last cycle, which
# means the watcher has not picked the edit up yet.
edit_pending() {
  local started
  started=$(last_cycle | head -n 1 | cut -d' ' -f1)
  [ -n "$started" ] || return 1
  [ -n "$(find lib bin -type f -newermt "$started" -print -quit 2>/dev/null)" ]
}

cmd="${1:-}"
[ $# -gt 0 ] && shift

case "$cmd" in
  up)
    [ "${1:-}" = "--" ] && shift
    if [ $# -gt 0 ]; then
      "${SP[@]}" runner start --no-docker --no-flutter -- "$@"
    else
      "${SP[@]}" runner start --no-docker --no-flutter
    fi
    ;;
  down)
    "${SP[@]}" runner stop
    ;;
  restart)
    "${SP[@]}" runner stop || true
    exec "$0" up "$@"
    ;;
  status)
    "${SP[@]}" runner status
    ;;
  last)
    # Called straight after an edit, so wait for the watcher to notice the
    # change, and then for that cycle to finish, before reporting on it.
    for _ in $(seq 1 40); do
      edit_pending || break
      sleep 0.25
    done
    for _ in $(seq 1 80); do
      if last_cycle | grep -qE 'Server reloaded|Server running|failed in|\[ERROR\]|Server stopped'; then
        break
      fi
      sleep 0.25
    done
    last_cycle
    if last_cycle | grep -qE 'failed in|\[ERROR\]'; then exit 1; fi
    ;;
  logs)
    [ -f "$LOG" ] || { echo "No runner log yet; start with: $0 up" >&2; exit 1; }
    if [ "${1:-}" = "-f" ]; then exec tail -n 40 -f "$LOG"; fi
    tail -n "${1:-80}" "$LOG"
    ;;
  hot-restart)
    exec tool/mcp.py serverpod call hot_restart
    ;;
  requests)
    exec tool/mcp.py serverpod call tail_server_logs "{\"limit\": ${1:-40}}"
    ;;
  migrate)
    if [ $# -gt 0 ]; then
      "${SP[@]}" create-migration --tag "$1"
    else
      "${SP[@]}" create-migration
    fi
    # Applied to the running server, which keeps its in-memory state.
    #
    # The tool also applies a repair migration if repair-migration/ holds one.
    # A stale one there (removed 2026-11-11) made every call fail, so if this
    # step reports a 500, look in that directory first.
    if "${SP[@]}" runner status 2>/dev/null | grep -q '^Running'; then
      exec tool/mcp.py serverpod call apply_migrations
    fi
    ;;
  app)
    exec tool/mcp.py serverpod call spawn_flutter_app
    ;;
  app-logs)
    exec tool/mcp.py serverpod call tail_flutter_logs "{\"limit\": ${1:-60}}"
    ;;
  app-errors)
    exec tool/mcp.py dart --app call get_runtime_errors
    ;;
  ui)
    exec "${SP[@]}" start --no-docker "$@"
    ;;
  *)
    sed -n '3,/^set -euo/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
    [ -z "$cmd" ] || [ "$cmd" = "help" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "--help" ] || exit 2
    ;;
esac
