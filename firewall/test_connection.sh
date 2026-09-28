#!/bin/bash
# Usage (from the repository folder):
#   bash firewall/test_connection.sh "Test name" "Expected result" HOST PORT
NAME="$1"; EXPECTED="$2"; HOST="$3"; PORT="$4"
OUT=$(nc -zv -w 3 "$HOST" "$PORT" 2>&1); RC=$?
if [ $RC -eq 0 ]; then RESULT="PERMITTED (connection succeeded)"; else RESULT="BLOCKED (connection failed or timed out)"; fi
{
echo "### $NAME"
echo "- Run from: $(hostname), $(date)"
echo "- Command: nc -zv -w 3 $HOST $PORT"
echo "- Expected: $EXPECTED"
echo "- Actual output: $OUT"
echo "- Actual result: $RESULT"
echo
} | tee -a filter_tests.md
