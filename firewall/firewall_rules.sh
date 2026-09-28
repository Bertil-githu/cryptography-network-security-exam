#!/bin/bash
# Traffic filtering for the student records server.
# Run as root, ONLY in the authorised laboratory.

# ---- EDIT THESE VALUES WITH THE ONES GIVEN IN THE LAB ----
SERVER_IP="CHANGE_ME"     # student records server
GUEST_NET="CHANGE_ME"     # guest network, e.g. 192.168.20.0/24
STAFF_NET="CHANGE_ME"     # authorised staff network, e.g. 192.168.10.0/24
PORT="CHANGE_ME"          # service port given by the assessor
PROTO="tcp"
ADMIN_IP=""               # optional: your own host, keeps SSH open so you are not locked out
MODE="server"             # server = run on the records server; gateway = run on the router
# -----------------------------------------------------------

if [ "$EUID" -ne 0 ]; then echo "Run as root (sudo)."; exit 1; fi
for v in "$GUEST_NET" "$STAFF_NET" "$PORT"; do
  if [ "$v" = "CHANGE_ME" ]; then echo "Edit the values at the top of this script first."; exit 1; fi
done

iptables-save > /tmp/iptables.backup      # backup so you can undo

if [ "$MODE" = "gateway" ]; then
  CHAIN="FORWARD"; DEST="-d $SERVER_IP"
else
  CHAIN="INPUT"; DEST=""
fi

iptables -F $CHAIN
[ "$CHAIN" = "INPUT" ] && iptables -A INPUT -i lo -j ACCEPT
iptables -A $CHAIN -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
[ -n "$ADMIN_IP" ] && iptables -A $CHAIN -p tcp -s "$ADMIN_IP" $DEST --dport 22 -j ACCEPT

# (a) block guest network to the records server
iptables -A $CHAIN -s "$GUEST_NET" $DEST -j DROP
# (b) allow authorised staff network to the service
iptables -A $CHAIN -p $PROTO -s "$STAFF_NET" $DEST --dport "$PORT" -j ACCEPT
# (c) block all other inbound access to that service
iptables -A $CHAIN -p $PROTO $DEST --dport "$PORT" -j DROP

iptables -L $CHAIN -n -v --line-numbers
