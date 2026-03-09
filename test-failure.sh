#!/usr/bin/env bash
# Test failure case: AI never outputs promise string

set -e

MOCK_AI_SCRIPT="/tmp/mock_ai_fail_$$.sh"
cat > "$MOCK_AI_SCRIPT" << 'EOF'
#!/bin/bash
echo "I will never output the success string"
EOF
chmod +x "$MOCK_AI_SCRIPT"

echo "=== Testing failure case (max loops reached) ==="
AI_COMMAND="$MOCK_AI_SCRIPT" \
MAX_LOOPS=3 \
PROMISE_STRING="SUCCESS" \
VERBOSE=1 \
./ralph-loop.sh "Some task" 2>&1 | tail -10

rm -f "$MOCK_AI_SCRIPT"
echo "=== Test complete ==="