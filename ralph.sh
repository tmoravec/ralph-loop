#!/usr/bin/env bash
# Ralph Loop - Simplified brute-force persistence loop for autonomous agentic coding
# Minimal version: only three arguments, no environment variables, no options.

set -euo pipefail

# Default configuration (edit these if needed)
AI_COMMAND="pi"
VERIFY_COMMAND='cat "$OUTPUT_FILE"'
MAX_LOOPS=20
PROMISE_STRING="TASK_SUCCESS"

# Colors for logging
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;36m'
BLUE='\033[1;35m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $@" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $@" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $@" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $@" >&2
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

# Check for promise string
check_success() {
    echo "$1" | grep -q "$PROMISE_STRING"
}

# Run verification command and write result to dest
capture_state() {
    local dest="$1"
    local cmd="${VERIFY_COMMAND//\$OUTPUT_FILE/$OUTPUT_FILE}"
    local tmp="${dest}.tmp"
    if bash -c "$cmd" > "$tmp" 2>&1; then
        mv "$tmp" "$dest"
    else
        log_warning "Verification command exited with non-zero status ($?)"
        mv "$tmp" "$dest"
    fi
}

# Main
if [ $# -lt 1 ]; then
    echo "Usage: $0 <task> [ai-command] [verify-command]"
    echo "  task: the task description for the AI"
    echo "  ai-command: command to run AI (default: pi)"
    echo "  verify-command: command to capture state (default: cat \"\$OUTPUT_FILE\")"
    exit 1
fi

TASK="$1"
AI_COMMAND="${2:-pi}"
VERIFY_COMMAND="${3:-cat \"\$OUTPUT_FILE\"}"

OUTPUT_FILE="/tmp/ralph_output_$(date +%s)_$$.txt"
echo "Initializing..." > "$OUTPUT_FILE"

check_ai_command

log "Starting Ralph Loop"
log "Task: $TASK"
log "AI: $AI_COMMAND"
log "Promise: '$PROMISE_STRING'"
log "Max loops: $MAX_LOOPS"
log "Temp file: $OUTPUT_FILE"

# Initial state capture
log "Performing initial state capture..."
capture_state "$OUTPUT_FILE"

trap 'rm -f "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp" "${OUTPUT_FILE}.verify" 2>/dev/null' EXIT

for (( i=1; i<=MAX_LOOPS; i++ )); do
    log "=== Loop $i/$MAX_LOOPS ==="
    
    CURRENT_STATE=$(cat "$OUTPUT_FILE")
    log "Current state size: ${#CURRENT_STATE} chars"
    
    # Construct prompt
    PROMPT="$TASK

Current state/output from previous iteration:
---
$CURRENT_STATE
---

Please fix any errors and ensure the task is completed. If successful, output the exact string: $PROMISE_STRING"
    
    if ! AI_RESPONSE=$(run_ai "$PROMPT"); then
        log_warning "AI command returned an error. Continuing anyway..."
    fi
    
    if check_success "$AI_RESPONSE"; then
        log_success "Promise string '$PROMISE_STRING' found!"
        log "Task completed in iteration $i."
        exit 0
    else
        log "Goal not met. Updating state for next iteration..."
        
        # Build next state
        verify_out="${OUTPUT_FILE}.verify"
        capture_state "$verify_out"

        {
            echo "--- AI RESPONSE ---"
            echo "$AI_RESPONSE"
            echo "-------------------"
            echo ""
            echo "--- VERIFICATION OUTPUT ---"
            cat "$verify_out"
        } > "$OUTPUT_FILE"

        rm -f "$verify_out"
    fi
done

log_error "Max loops ($MAX_LOOPS) reached without success."
exit 1