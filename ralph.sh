#!/usr/bin/env bash
# Ralph Loop - Simplified brute-force persistence loop for autonomous agentic coding
# Minimal version: only three arguments, no environment variables, no options.

set -euo pipefail

# Default configuration (edit these if needed)
AI_COMMAND="pi"
VERIFY_COMMAND='cat "$OUTPUT_FILE"'
MAX_LOOPS=20
STATE_TAIL_LINES=200

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

# Check whether the AI declared itself done AND the verification command exits 0.
# Always runs the verify command and writes its output to $OUTPUT_FILE.
check_success() {
    local ai_response="$1"
    local cmd="${VERIFY_COMMAND//\$OUTPUT_FILE/$OUTPUT_FILE}"
    local tmp="${OUTPUT_FILE}.tmp"
    local rc=0
    bash -c "$cmd" > "$tmp" 2>&1 || rc=$?
    mv "$tmp" "$OUTPUT_FILE"
    # Success only when the AI explicitly said DONE *and* verification passed.
    echo "$ai_response" | grep -qF "$_TOKEN_DONE" && [ $rc -eq 0 ]
}

# Main
show_usage() {
    echo "Usage: $0 <task> [ai-command] [verify-command]"
    echo ""
    echo "Arguments:"
    echo "  task           The task description for the AI (required)"
    echo "  ai-command     AI command to run (default: pi)"
    echo "  verify-command Command to capture state after each iteration (default: cat \"\$OUTPUT_FILE\")"
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
VERIFY_COMMAND="${3:-cat \"\$OUTPUT_FILE\"}"

OUTPUT_FILE="/tmp/ralph_output_$(date +%s)_$$.txt"

check_ai_command

log "Starting Ralph Loop"
log "Task: $TASK"
log "AI: $AI_COMMAND"
log "Max loops: $MAX_LOOPS"
log "Temp file: $OUTPUT_FILE"

trap 'rm -f "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp" 2>/dev/null' EXIT

for (( i=1; i<=MAX_LOOPS; i++ )); do
    log "=== Loop $i/$MAX_LOOPS ==="

    CURRENT_STATE=$(tail -n "$STATE_TAIL_LINES" "$OUTPUT_FILE" 2>/dev/null || true)
    log "Current state: ${#CURRENT_STATE} chars (last $STATE_TAIL_LINES lines)"

    PROMPT="You are running inside of a Ralph loop - getting called multiple times and working on the task below iteratively. Make meaningful progress each iteration. For example, one check box in a check list.

When you are finished with one iteration, your response MUST end with exactly one of these two tokens on its own line:

  $_TOKEN_CONTINUE  — you made progress this iteration but more work remains;
  $_TOKEN_DONE      — the entire task is fully complete and no further work is needed

---
The overall task:

$TASK

---
Previous iteration output (last $STATE_TAIL_LINES lines):
$CURRENT_STATE

---

Reminder: do not implement everything in one go. Exit after making a piece of progress."

    if ! AI_RESPONSE=$(run_ai "$PROMPT"); then
        log_error "AI command returned an error. Continuing anyway..."
    fi

    if check_success "$AI_RESPONSE"; then
        log "Task accomplished in iteration $i!"
        echo ""
        echo "$AI_RESPONSE" | grep -vF "$_TOKEN_DONE" | grep -vF "$_TOKEN_CONTINUE"
        echo ""
        exit 0
    else
        log "Goal not met. Updating state for next iteration..."
        # check_success already wrote verify output to $OUTPUT_FILE; prepend the AI response
        VERIFY_OUTPUT=$(cat "$OUTPUT_FILE")
        {
            echo "--- AI RESPONSE ---"
            echo "$AI_RESPONSE" | sed "s/^'//;s/'$//"
            echo "-------------------"
            echo ""
            echo "--- VERIFICATION OUTPUT ---"
            echo "$VERIFY_OUTPUT"
        } > "$OUTPUT_FILE"
    fi
done

log_error "Max loops ($MAX_LOOPS) reached without success."
echo ""
cat "$OUTPUT_FILE"
echo ""
exit 1
