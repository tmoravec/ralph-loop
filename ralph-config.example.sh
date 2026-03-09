#!/bin/bash
# Example configuration for Ralph Loop
# Copy this to ralph-config.sh and customize, or set environment variables.

# AI command (reads prompt from stdin, outputs to stdout)
export AI_COMMAND="claude-code"

# Maximum number of iterations
export MAX_LOOPS=20

# Success string the AI must output
export PROMISE_STRING="TASK_SUCCESS"

# Default task if none provided as argument
export DEFAULT_TASK="Write a bash script that prints 'Hello, World!'"

# Verification command - captures current state for next iteration
# Can reference $OUTPUT_FILE (the temporary output file)
export RALPH_VERIFICATION_COMMAND="cat \"\$OUTPUT_FILE\" 2>/dev/null || echo 'No previous output'"

# Verbosity level (0=quiet, 1=normal, 2=verbose)
export VERBOSE=1

# Optional: Additional arguments to pass to the AI command
# export AI_ARGS="--temperature 0.2 --max-tokens 1000"

# Optional: Custom prompt template
# export PROMPT_TEMPLATE="Task: {TASK}\n\nCurrent state:\n{STATE}\n\nPlease fix any errors. If successful, output: {PROMISE}"