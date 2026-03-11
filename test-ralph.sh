#!/usr/bin/env bash
# Test script for Ralph Loop using a mock AI command

set -e

# Create unique temporary files
MOCK_AI_SCRIPT=$(mktemp /tmp/mock_ai_XXXXXX.sh)
ATTEMPT_COUNT_FILE=$(mktemp /tmp/attempt_count_XXXXXX.txt)
echo 0 > "$ATTEMPT_COUNT_FILE"

# Ensure cleanup on exit
trap 'rm -f "$MOCK_AI_SCRIPT" "$ATTEMPT_COUNT_FILE"' EXIT

cat > "$MOCK_AI_SCRIPT" << EOF
#!/bin/bash
# Mock AI that reads stdin and outputs something
prompt=\$(cat)

# Simulate state: count attempts
attempts=\$(cat "$ATTEMPT_COUNT_FILE")
attempts=\$((attempts + 1))
echo \$attempts > "$ATTEMPT_COUNT_FILE"

# Succeed on 3rd attempt
if [ \$attempts -ge 3 ]; then
    echo "TASK_SUCCESS"
    echo "The task has been completed successfully after \$attempts attempts."
    echo "RALPH_DONE"
else
    echo "Still working on it... attempt \$attempts"
    echo "RALPH_CONTINUE"
fi
EOF
chmod +x "$MOCK_AI_SCRIPT"

# Run Ralph Loop with mock AI and capture output
echo "=== Testing Ralph Loop with mock AI ==="
OUTPUT=$(./ralph.sh "Complete a simple task" "$MOCK_AI_SCRIPT" 2>&1)

# Check for success indicators
if echo "$OUTPUT" | grep -q "Task accomplished in iteration 3"; then
    echo "[PASS] Success message found."
else
    echo "[FAIL] Success message not found in output:"
    echo "$OUTPUT"
    exit 1
fi

echo "=== Test complete ==="
