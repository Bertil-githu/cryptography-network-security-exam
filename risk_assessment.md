# Risk Assessment

## a. Assets, vulnerabilities and consequences

| # | Asset | Vulnerability | Possible consequence |
|---|-------|---------------|----------------------|
| R1 | Staff accounts | Weak staff passwords | Attacker guesses a password, logs in and reads or changes student records |
| R2 | Student records server | Guest network can reach the server | A guest user or infected guest device steals data or attacks the server |
| R3 | Student files sent between campuses | Unencrypted file transfers | Someone intercepts the files, reads private data or changes it |

## b. Ranking by likelihood and impact

| Rank | Risk | Likelihood | Impact | Reason |
|------|------|-----------|--------|--------|
| 1 | R2: Guest access to server | High | High | Guests are already inside the network, and repeated attempts from an unfamiliar external address were observed. The server holds all student records. |
| 2 | R1: Weak passwords | High | High | Weak passwords are easy to guess, and a stolen account looks like a normal user. |
| 3 | R3: Unencrypted transfers | Medium | High | The attacker must be on the network path, but if they are, all the data is readable. |

## c. Recommended controls

| Risk | Control |
|------|---------|
| R2 | Firewall rules that block the guest network and allow only authorised staff (see the firewall folder) |
| R1 | Strong password policy (minimum length, no common passwords) with multi-factor authentication and account lockout |
| R3 | Encrypt files before transfer and check their integrity with a SHA-256 hash (see the src folder) |
