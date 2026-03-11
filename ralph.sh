#!/usr/bin/env bash
# Ralph Loop - Simplified brute-force persistence loop for autonomous agentic coding
# Minimal version: only two arguments, no environment variables, no options.

set -euo pipefail

# Default configuration (edit these if needed)
AI_COMMAND="pi"
MAX_LOOPS=20

# Internal tokens — the AI is instructed to end every response with exactly one of these.
# RALPH_CONTINUE means "I did work this iteration but more remains — run me again."
# RALPH_DONE means "Everything in the task is fully complete."
_TOKEN_CONTINUE="RALPH_CONTINUE"
_TOKEN_DONE="RALPH_DONE"

BOLD='\033[1m'
RED='\033[1;31m'
NC='\033[0m'

log() {
    echo -e "${BOLD}[INFO]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Check AI command exists
check_ai_command() {
    local cmd="${AI_COMMAND%% *}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "AI command '$cmd' not found in PATH."
        exit 1
    fi
}

# Run AI with prompt
run_ai() {
    local prompt="$1"
    log "Executing AI command..."
    local response rc=0

    # Handle gemini specially - it requires -y -p for non-interactive mode
    if [[ "$AI_COMMAND" == gemini* ]]; then
        response=$(gemini -y -p "$prompt" 2>&1) || rc=$?
    else
        response=$(echo "$prompt" | $AI_COMMAND 2>&1) || rc=$?
    fi

    echo "$response"
    if [ $rc -ne 0 ]; then
        log_error "AI command failed with exit code $rc"
        return 1
    fi
}

# Main
show_usage() {
    echo "Usage: $0 <task> [ai-command]"
    echo ""
    echo "Arguments:"
    echo "  task       The task description for the AI (required)"
    echo "  ai-command AI command to run (default: pi)"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    show_usage
    exit 0
fi

if [ $# -lt 1 ]; then
    show_usage
    exit 1
fi

TASK="$1"
AI_COMMAND="${2:-pi}"

check_ai_command

log "Starting Ralph Loop"
log "Task: $TASK"
log "AI: $AI_COMMAND"
log "Max loops: $MAX_LOOPS"

for (( i=1; i<=MAX_LOOPS; i++ )); do
    log "=== Loop $i/$MAX_LOOPS ==="

    PROMPT="Pick the next one or the single most important piece of work in the following task and implement that:

---
$TASK
---

When done with this piece of work, end your response with exactly one of:
  $_TOKEN_CONTINUE  — more work remains in the overall task
  $_TOKEN_DONE      — the entire task is now fully complete"

    if ! AI_RESPONSE=$(run_ai "$PROMPT"); then
        log_error "AI command returned an error. Continuing anyway..."
    fi

    log "AI response:"
    log "$AI_RESPONSE"

    if echo "$AI_RESPONSE" | grep -qF "$_TOKEN_DONE"; then
        log "Task accomplished in iteration $i!"
        echo ""
        echo "$AI_RESPONSE" | grep -vF "$_TOKEN_DONE" | grep -vF "$_TOKEN_CONTINUE"
        echo ""
        exit 0
    else
        log "Goal not met. Running next iteration..."
    fi
done

log_error "Max loops ($MAX_LOOPS) reached without success."
exit 1
