#!/usr/bin/env bash
# Ralph Loop - Simplified brute-force persistence loop for autonomous agentic coding
# Minimal version: only three arguments, no environment variables, no options.

set -euo pipefail

# Default configuration (edit these if needed)
AI_COMMAND="pi"
VERIFY_COMMAND='cat "$OUTPUT_FILE"'
MAX_LOOPS=20
PROMISE_STRING="TASK_SUCCESS"
STATE_TAIL_LINES=200

# Colors for logging
RED='\033[0;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

log() {
    echo -e "${MAGENTA}[INFO]${NC} $@" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $@" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $@" >&2
}

log_warning() {
    echo -e "${CYAN}[WARNING]${NC} $@" >&2
}

# Check AI command exists
check_ai_command() {
    local cmd=$(echo "$AI_COMMAND" | awk '{print $1}')
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "AI command '$cmd' not found in PATH."
        exit 1
    fi
}

# Run AI with prompt
run_ai() {
    local prompt="$1"
    log "Executing AI command..."
    local response
    
    # Handle gemini specially - it requires -y -p for non-interactive mode
    if [[ "$AI_COMMAND" == gemini* ]]; then
        if response=$(gemini -y -p "$prompt" 2>&1); then
            echo "$response"
        else
            log_error "AI command failed with exit code $?"
            echo "$response"
            return 1
        fi
    else
        if response=$(echo "$prompt" | $AI_COMMAND 2>&1); then
            echo "$response"
        else
            log_error "AI command failed with exit code $?"
            echo "$response"
            return 1
        fi
    fi
}

# Check for promise string AND verification command exit code.
# On either path, writes verify output to $OUTPUT_FILE and returns verify's exit code.
check_success() {
    local ai_response="$1"
    local cmd="${VERIFY_COMMAND//\$OUTPUT_FILE/$OUTPUT_FILE}"
    local tmp="${OUTPUT_FILE}.tmp"
    local rc=0
    bash -c "$cmd" > "$tmp" 2>&1 || rc=$?
    mv "$tmp" "$OUTPUT_FILE"
    echo "$ai_response" | grep -q "$PROMISE_STRING" && [ $rc -eq 0 ]
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

if [ $# -lt 1 ] || [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    show_usage
    # Exit with 0 if help requested, 1 if no arguments
    [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && exit 0 || exit 1
fi

TASK="$1"
AI_COMMAND="${2:-pi}"
VERIFY_COMMAND="${3:-cat \"\$OUTPUT_FILE\"}"

OUTPUT_FILE="/tmp/ralph_output_$(date +%s)_$$.txt"

check_ai_command

log "Starting Ralph Loop"
log "Task: $TASK"
log "AI: $AI_COMMAND"
log "Promise: '$PROMISE_STRING'"
log "Max loops: $MAX_LOOPS"
log "Temp file: $OUTPUT_FILE"

trap 'rm -f "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp" 2>/dev/null' EXIT

for (( i=1; i<=MAX_LOOPS; i++ )); do
    log "=== Loop $i/$MAX_LOOPS ==="
    
    CURRENT_STATE=$(tail -n "$STATE_TAIL_LINES" "$OUTPUT_FILE")
    log "Current state: ${#CURRENT_STATE} chars (last $STATE_TAIL_LINES lines)"
    
    # Construct prompt
    PROMPT="$TASK

Current state/output from previous iteration (last $STATE_TAIL_LINES lines):
---
$CURRENT_STATE
---

Please fix any errors and ensure the task is completed. If successful, output the exact string: $PROMISE_STRING"
    
    if ! AI_RESPONSE=$(run_ai "$PROMPT"); then
        log_warning "AI command returned an error. Continuing anyway..."
    fi
    
    if check_success "$AI_RESPONSE"; then
        log_success "Task accomplished!"
        echo -e "\n${CYAN}=== SUMMARY OF ACCOMPLISHMENT ===${NC}"
        # Print AI response (stripping the promise string and surrounding quotes for cleaner summary)
        echo "$AI_RESPONSE" | sed "s/$PROMISE_STRING//g" | sed "s/^'//;s/'$//" | sed '/^[[:space:]]*$/d'
        echo -e "${CYAN}=================================${NC}\n"
        log "Terminated successfully in iteration $i."
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
echo -e "\n${RED}=== FINAL ATTEMPT STATE ===${NC}"
cat "$OUTPUT_FILE"
echo -e "${RED}===========================${NC}\n"
exit 1