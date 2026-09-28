# Cryptography and Network Security - Integrated Situation

Module ETTCS801, ULK Polytechnic Institute. This project contains a risk assessment,
a Python toolkit that encrypts student records and checks file integrity (SHA-256),
firewall rules for the student records server, test evidence and a LaTeX report.
Only fake sample data is used. No keys or real student records are in this repository.

## Project structure

    README.md                  this file
    risk_assessment.md         assets, vulnerabilities, ranking, controls
    filter_tests.md            firewall test commands, expected and actual results
    requirements.txt           Python dependency (cryptography)
    src/secure_records.py      encryption, decryption, hashing, integrity check
    sample_data/               fake student records for testing
    tests/run_tests.sh         runs all encryption/integrity tests
    tests/encryption_tests.txt saved output of those tests
    firewall/firewall_rules.sh iptables rules
    firewall/test_connection.sh records one connection test into filter_tests.md
    firewall/rules.v4          saved rules from the lab
    report/report.tex, report.pdf  technical report

## Installation

    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt

## Running the programme

Create the key. It is saved OUTSIDE the repository at ~/.exam_keys/records.key
(change the path with the EXAM_KEY_FILE environment variable):

    python3 src/secure_records.py keygen

Encrypt, decrypt and verify:

    python3 src/secure_records.py encrypt sample_data/students_sample.csv sample_data/students_sample.enc
    python3 src/secure_records.py decrypt sample_data/students_sample.enc sample_data/students_decrypted.csv --original sample_data/students_sample.csv

Integrity check (hash stores a baseline, check compares against it):

    python3 src/secure_records.py hash sample_data/students_sample.csv
    python3 src/secure_records.py check sample_data/students_sample.csv

Missing files, empty files and wrong input give a clear ERROR message and do not crash.

## Reproducing the encryption tests

    bash tests/run_tests.sh 2>&1 | tee tests/encryption_tests.txt

## Reproducing the firewall tests (authorised laboratory only)

1. Edit the values at the top of firewall/firewall_rules.sh (server, guest network, staff network, port).
2. Apply the rules on the records server or gateway: sudo bash firewall/firewall_rules.sh
3. Save them: sudo iptables-save > firewall/rules.v4
4. Run one permitted test from a staff host and two blocked tests (guest host, other host):

        bash firewall/test_connection.sh "Test 1: staff (permitted)" "Connection succeeds" SERVER_IP PORT
        bash firewall/test_connection.sh "Test 2: guest (blocked)" "Connection times out" SERVER_IP PORT
        bash firewall/test_connection.sh "Test 3: other host (blocked)" "Connection times out" SERVER_IP PORT

Results are appended to filter_tests.md.
