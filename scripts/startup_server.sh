echo "***** Executing startup_server.sh *****"

# 포트포워딩
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Docker 재시작
source restart_docker.sh

# Process 실행
source run_new_process.sh

echo "***** startup_server.sh Ended *****"
