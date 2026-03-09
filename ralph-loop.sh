#!/usr/bin/env bash
# ============================================================================
# Ralph Loop - A brute-force persistence loop for autonomous agentic coding
# This script feeds an AI its own previous errors until it achieves success.
# ============================================================================

set -euo pipefail

# ----------------------------------------------------------------------------
# CONFIGURATION (can be overridden by environment variables)
# ----------------------------------------------------------------------------

# AI command (reads prompt from stdin, outputs to stdout)
AI_COMMAND="${AI_COMMAND:-pi}"

# Maximum number of iterations before giving up
MAX_LOOPS="${MAX_LOOPS:-20}"

# The specific text the AI must output to break the loop (case-sensitive)
PROMISE_STRING="${PROMISE_STRING:-TASK_SUCCESS}"

# Default task if no command line argument is provided
DEFAULT_TASK="${DEFAULT_TASK:-Write a bash script that prints 'Hello, World!'}"

# Verification command: what to run to capture the state/errors after each attempt
VERIFICATION_COMMAND="${RALPH_VERIFICATION_COMMAND:-cat \"\$OUTPUT_FILE\" 2>/dev/null || echo 'No previous output'}"

# Enable verbose logging (0 = quiet, 1 = normal, 2 = verbose)
VERBOSE="${VERBOSE:-1}"

# Default prompt template
DEFAULT_PROMPT_TEMPLATE='{TASK}

Current state/output from previous iteration:
---
{STATE}
---

Please fix any errors and ensure the task is completed. If successful, output the exact string: {PROMISE}'

# Custom prompt template (overridden by environment variable)
PROMPT_TEMPLATE="${RALPH_PROMPT_TEMPLATE:-$DEFAULT_PROMPT_TEMPLATE}"

# ----------------------------------------------------------------------------
# INPUT HANDLING
# ----------------------------------------------------------------------------

usage() {
    cat <<EOF
Usage: $0 [options] [task]

Options:
  -a, --ai-command <cmd>      AI command to run (default: $AI_COMMAND)
  -m, --max-loops <num>       Maximum iterations (default: $MAX_LOOPS)
  -p, --promise <string>      String to signal success (default: $PROMISE_STRING)
  -v, --verbose <level>       Verbosity level 0-2 (default: $VERBOSE)
  -c, --verify <cmd>          Verification command (default: $VERIFICATION_COMMAND)
  -h, --help                  Show this help

Environment variables:
  AI_COMMAND, MAX_LOOPS, PROMISE_STRING, RALPH_VERIFICATION_COMMAND,
  RALPH_PROMPT_TEMPLATE, VERBOSE

Example:
  $0 "Fix the build" -m 10 -p "FIXED"
EOF
    exit 0
}

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--ai-command) AI_COMMAND="$2"; shift 2 ;;
        -m|--max-loops) MAX_LOOPS="$2"; shift 2 ;;
        -p|--promise) PROMISE_STRING="$2"; shift 2 ;;
        -v|--verbose) VERBOSE="$2"; shift 2 ;;
        -c|--verify) VERIFICATION_COMMAND="$2"; shift 2 ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) TASK="$1"; shift ;;
    esac
done

TASK="${TASK:-$DEFAULT_TASK}"

# ----------------------------------------------------------------------------
# STATE MANAGEMENT
# ----------------------------------------------------------------------------

# Temporary file to store the results of command/build execution
# Use a unique filename to avoid collisions if multiple loops run simultaneously
OUTPUT_FILE="/tmp/ralph_output_$(date +%s)_$$.txt"

# Initialize the output file with a placeholder
echo "Initializing Ralph Loop..." > "$OUTPUT_FILE"

# ----------------------------------------------------------------------------
# HELPER FUNCTIONS
# ----------------------------------------------------------------------------

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    if [ "$VERBOSE" -ge 1 ]; then
        echo -e "${BLUE}[INFO]${NC} $@" >&2
    fi
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

log_verbose() {
    if [ "$VERBOSE" -ge 2 ]; then
        echo -e "[VERBOSE] $@" >&2
    fi
}

# Check if AI command exists (only the first word, ignoring flags)
check_ai_command() {
    local cmd=$(echo "$AI_COMMAND" | awk '{print $1}')
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log_error "AI command '$cmd' not found in PATH."
        echo "Please install it or adjust AI_COMMAND variable."
        exit 1
    fi
    log_verbose "AI command resolved to: $AI_COMMAND"
}

# Run the AI command with the current prompt
run_ai() {
    local prompt="$1"
    log_verbose "Executing: echo \"<prompt>\" | $AI_COMMAND"
    
    # Run AI and capture both stdout and stderr
    local response
    if response=$(echo "$prompt" | $AI_COMMAND 2>&1); then
        echo "$response"
    else
        log_error "AI command failed with exit code $?"
        echo "$response"
        return 1
    fi
}

# Check if the AI response contains the promise string
check_success() {
    local response="$1"
    if echo "$response" | grep -q "$PROMISE_STRING"; then
        return 0
    else
        return 1
    fi
}

# Run verification command and update the output file
update_state() {
    log "Running verification command"
    
    # Substitute $OUTPUT_FILE variable with actual path in the command string
    local cmd="${VERIFICATION_COMMAND//\$OUTPUT_FILE/$OUTPUT_FILE}"
    
    # Use a temporary file to avoid truncation issues (cat $FILE > $FILE)
    local tmp_output="${OUTPUT_FILE}.tmp"
    
    if bash -c "$cmd" > "$tmp_output" 2>&1; then
        mv "$tmp_output" "$OUTPUT_FILE"
        log_verbose "Verification command succeeded"
    else
        log_warning "Verification command exited with non-zero status ($?)"
        mv "$tmp_output" "$OUTPUT_FILE"
    fi
}

# ----------------------------------------------------------------------------
# MAIN LOOP
# ----------------------------------------------------------------------------

check_ai_command

log "Starting Ralph Loop"
log "  Task: $TASK"
log "  AI: $AI_COMMAND"
log "  Promise: '$PROMISE_STRING'"
log "  Max loops: $MAX_LOOPS"
log ""

# Pre-loop verification to capture initial state
log "Performing initial state capture..."
update_state

# Cleanup on exit (optional, but good practice)
trap 'rm -f "$OUTPUT_FILE" "${OUTPUT_FILE}.tmp" 2>/dev/null' EXIT

for (( i=1; i<=MAX_LOOPS; i++ )); do
    log "=== Loop iteration $i/$MAX_LOOPS ==="
    
    # Read the current state from the output file
    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "No previous state" > "$OUTPUT_FILE"
    fi
    CURRENT_STATE=$(cat "$OUTPUT_FILE")
    log_verbose "Current state size: ${#CURRENT_STATE} characters"
    if [ "$VERBOSE" -ge 2 ]; then
        echo -e "${YELLOW}--- CURRENT STATE ---${NC}" >&2
        cat "$OUTPUT_FILE" >&2
        echo -e "${YELLOW}----------------------${NC}" >&2
    fi
    
    # Construct the prompt
    PROMPT="$PROMPT_TEMPLATE"
    PROMPT="${PROMPT//\{TASK\}/$TASK}"
    PROMPT="${PROMPT//\{STATE\}/$CURRENT_STATE}"
    PROMPT="${PROMPT//\{PROMISE\}/$PROMISE_STRING}"
    
    # Run AI with the prompt
    log "Asking AI..."
    if ! AI_RESPONSE=$(run_ai "$PROMPT"); then
        log_warning "AI command returned an error. Continuing anyway..."
    fi
    log_verbose "AI response size: ${#AI_RESPONSE} characters"
    if [ "$VERBOSE" -ge 2 ]; then
        echo -e "${BLUE}--- AI RESPONSE ---${NC}" >&2
        echo "$AI_RESPONSE" >&2
        echo -e "${BLUE}-------------------${NC}" >&2
    fi
    
    # Check for success
    if check_success "$AI_RESPONSE"; then
        log_success "Promise string '$PROMISE_STRING' found!"
        log "Task completed in iteration $i."
        exit 0
    else
        log "Goal not met. Updating state for next iteration..."
        
        # We use a temporary file to construct the next state
        {
            echo "--- AI RESPONSE ---"
            echo "$AI_RESPONSE"
            echo "-------------------"
            echo ""
            echo "--- VERIFICATION OUTPUT ---"
        } > "${OUTPUT_FILE}.next"
        
        # Temporarily swap for verification command (it might use $OUTPUT_FILE)
        mv "$OUTPUT_FILE" "${OUTPUT_FILE}.prev"
        
        # Run verification command
        update_state
        
        # Combine everything
        cat "$OUTPUT_FILE" >> "${OUTPUT_FILE}.next"
        mv "${OUTPUT_FILE}.next" "$OUTPUT_FILE"
        rm -f "${OUTPUT_FILE}.prev"
    fi
done

log_error "Max loops ($MAX_LOOPS) reached without success."
exit 1