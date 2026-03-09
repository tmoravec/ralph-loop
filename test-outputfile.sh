#!/usr/bin/env bash
# Test verification command using $OUTPUT_FILE variable

set -e

MOCK_AI="/tmp/mock_output.sh"
cat > "$MOCK_AI" << 'EOF'
#!/bin/bash
echo "AI attempt"
echo "Current output file contents:"
cat /tmp/test_output 2>/dev/null || echo "No output"
echo "TASK_SUCCESS"
EOF
chmod +x "$MOCK_AI"

echo "=== Testing verification command with \$OUTPUT_FILE ==="
# Use a verification command that writes to a file and also uses $OUTPUT_FILE
./ralph-loop.sh "Test" "$MOCK_AI" "echo 'Verification step' > /tmp/test_output && cat \"\$OUTPUT_FILE\""

rm -f "$MOCK_AI" /tmp/test_output
echo "=== Done ==="