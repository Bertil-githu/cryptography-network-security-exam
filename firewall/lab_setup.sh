#!/bin/bash
# Rebuilds the virtual laboratory (Linux network namespaces) and applies the firewall rules.
# Run: sudo bash firewall/lab_setup.sh
cd "$(dirname "$0")/.." || exit 1
pkill -f "http.server 8080" 2>/dev/null
for n in staff guest other server; do ip netns del $n 2>/dev/null; done
for n in server staff guest other; do ip netns add $n; done
for n in staff guest other; do
  case $n in staff) N=10;; guest) N=20;; other) N=30;; esac
  ip link add v-$n type veth peer name v-$n-srv
  ip link set v-$n netns $n
  ip link set v-$n-srv netns server
  ip netns exec $n ip addr add 10.0.$N.2/24 dev v-$n
  ip netns exec $n ip link set v-$n up
  ip netns exec $n ip link set lo up
  ip netns exec server ip addr add 10.0.$N.1/24 dev v-$n-srv
  ip netns exec server ip link set v-$n-srv up
done
ip netns exec server ip link set lo up
mkdir -p /tmp/records_demo
echo "fake student records service" > /tmp/records_demo/index.html
ip netns exec server nohup python3 -m http.server 8080 --directory /tmp/records_demo > /tmp/records_server.log 2>&1 &
sleep 1
ip netns exec server bash firewall/firewall_rules.sh
