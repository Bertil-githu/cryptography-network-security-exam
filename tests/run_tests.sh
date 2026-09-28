#!/bin/bash
# Runs all encryption and integrity tests. Run from anywhere.
cd "$(dirname "$0")/.."
P="python3 src/secure_records.py"

echo "=== 1. Encrypt the sample file ==="
$P encrypt sample_data/students_sample.csv sample_data/students_sample.enc

echo
echo "=== 2. Decrypt and verify it matches the original ==="
$P decrypt sample_data/students_sample.enc sample_data/students_decrypted.csv --original sample_data/students_sample.csv

echo
echo "=== 3. Integrity check on the unchanged file (expect OK) ==="
$P check sample_data/students_sample.csv

echo
echo "=== 4. Change a copy of the file, then check (expect FAIL) ==="
cp sample_data/students_sample.csv sample_data/tamper_test.csv
$P hash sample_data/tamper_test.csv
echo "S004,Mallory Edit,Networking,4.0" >> sample_data/tamper_test.csv
$P check sample_data/tamper_test.csv
rm -f sample_data/tamper_test.csv

echo
echo "=== 5. Missing file (expect clean error) ==="
$P encrypt missing.csv out.enc

echo
echo "=== 6. Decrypt a file that is not encrypted (expect clean error) ==="
$P decrypt sample_data/students_sample.csv /tmp/x.csv

echo
echo "=== 7. Empty file (expect clean error) ==="
touch tests/empty.txt
$P encrypt tests/empty.txt tests/out.enc
rm -f tests/empty.txt
