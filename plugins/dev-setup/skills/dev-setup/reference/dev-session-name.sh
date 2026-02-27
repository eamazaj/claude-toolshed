#!/usr/bin/env bash
# dev-session-name.sh — Resolve tmux session name for the current git branch.
#
# Usage (sourced):
#   source tools/dev/dev-session-name.sh
#   SESSION="$(dev_session_name)"
#
# Session format:
#   b-<branch-name>
#
# Examples:
#   b-main
#   b-feat-calendar-admin
#
# Notes:
# - Branch is resolved via `git rev-parse --abbrev-ref HEAD`.
# - If branch cannot be resolved (or detached HEAD), falls back to the
#   current directory basename.
#
# shellcheck shell=bash

dev_session_name() {
  local branch normalized

  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  if [[ -z "$branch" || "$branch" == "HEAD" ]]; then
    branch="$(basename "$PWD")"
  fi

  normalized="$(printf '%s' "$branch" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]_-' '-' | sed 's/^-*//; s/-*$//')"
  if [[ -z "$normalized" ]]; then
    normalized="session"
  fi

  printf 'b-%s\n' "$normalized"
}
