#!/usr/bin/env bash
# Test script for Ralph Loop using a mock AI command

set -e

# Create a mock AI command that succeeds after 3 attempts
MOCK_AI_SCRIPT="/tmp/mock_ai_$$.sh"
cat > "$MOCK_AI_SCRIPT" << 'EOF'
#!/bin/bash
# Mock AI that reads stdin and outputs something
prompt=$(cat)
echo "Mock AI received prompt of length: ${#prompt} characters"

# Simulate state: count attempts
if [ -f /tmp/attempt_count.txt ]; then
    attempts=$(cat /tmp/attempt_count.txt)
else
    attempts=0
fi
attempts=$((attempts + 1))
echo $attempts > /tmp/attempt_count.txt

# Succeed on 3rd attempt
if [ $attempts -ge 3 ]; then
    echo "TASK_SUCCESS"
    echo "The task has been completed successfully after $attempts attempts."
else
    echo "Still working on it... attempt $attempts"
fi
EOF
chmod +x "$MOCK_AI_SCRIPT"

# Create a simple verification command that just echoes current output
export RALPH_VERIFICATION_COMMAND="echo 'Verification step: attempt count is \$(cat /tmp/attempt_count.txt 2>/dev/null || echo 0)'"

# Run Ralph Loop with mock AI
echo "=== Testing Ralph Loop with mock AI ==="
AI_COMMAND="$MOCK_AI_SCRIPT" \
MAX_LOOPS=5 \
PROMISE_STRING="TASK_SUCCESS" \
./ralph-loop.sh "Complete a simple task"

# Cleanup
rm -f "$MOCK_AI_SCRIPT" /tmp/attempt_count.txt
echo "=== Test complete ==="