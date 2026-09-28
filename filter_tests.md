# Firewall Filter Tests

## Lab details
- Service and port: TCP port 8080 (fake student records web service)
- Server IP: 10.0.10.1 (staff side), 10.0.20.1 (guest side), 10.0.30.1 (other side)
- Guest network: 10.0.20.0/24
- Staff network: 10.0.10.0/24
- Machine where rules were applied: virtual lab on the laptop (Linux network namespaces), rules applied inside the server namespace

## Rules applied
See `firewall/firewall_rules.sh` and the saved rules in `firewall/rules.v4`.
Rule order: (a) DROP guest network, (b) ACCEPT staff network to the port, (c) DROP everything else to the port.

## Test results (recorded automatically by firewall/test_connection.sh)

### Test 1: staff host (permitted)
- Run from: bertil-HP-EliteBook-840-G8-Notebook-PC, Mon Sep 28 01:56:55 PM CAT 2026
- Command: nc -zv -w 3 10.0.10.1 8080
- Expected: Connection succeeds
- Actual output: Connection to 10.0.10.1 8080 port [tcp/http-alt] succeeded!
- Actual result: PERMITTED (connection succeeded)

### Test 2: guest host (blocked)
- Run from: bertil-HP-EliteBook-840-G8-Notebook-PC, Mon Sep 28 01:56:58 PM CAT 2026
- Command: nc -zv -w 3 10.0.20.1 8080
- Expected: Connection times out
- Actual output: nc: connect to 10.0.20.1 port 8080 (tcp) timed out: Operation now in progress
- Actual result: BLOCKED (connection failed or timed out)

### Test 3: other host (blocked)
- Run from: bertil-HP-EliteBook-840-G8-Notebook-PC, Mon Sep 28 01:57:01 PM CAT 2026
- Command: nc -zv -w 3 10.0.30.1 8080
- Expected: Connection times out
- Actual output: nc: connect to 10.0.30.1 port 8080 (tcp) timed out: Operation now in progress
- Actual result: BLOCKED (connection failed or timed out)

## Firewall rule counters after the tests

Command: sudo ip netns exec server iptables -L INPUT -n -v

    Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
     pkts bytes target     prot opt in     out     source               destination         
        0     0 ACCEPT     0    --  lo     *       0.0.0.0/0            0.0.0.0/0           
        3   156 ACCEPT     0    --  *      *       0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
        3   180 DROP       0    --  *      *       10.0.20.0/24         0.0.0.0/0           
        1    60 ACCEPT     6    --  *      *       10.0.10.0/24         0.0.0.0/0            tcp dpt:8080
        3   180 DROP       6    --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080

