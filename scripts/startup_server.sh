#!/bin/bash

echo "***** Executing startup_server.sh *****"

# 포트포워딩
echo "Setting port forwarding... [1/3]"
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# (pi)
# /etc/resolv.conf 파일을 확인하고, nameserver가 없으면 추가
if ! grep -q "nameserver 8.8.8.8" /etc/resolv.conf; then
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
fi

if ! grep -q "nameserver 8.8.4.4" /etc/resolv.conf; then
    echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf
fi

# Docker 재시작
echo "Restarting docker... [2/3]"
source ~/scripts/restart_docker.sh

# Process 실행
echo "Running server... [3/3]"
source ~/scripts/run_new_process.sh

echo "***** startup_server.sh Ended *****"
