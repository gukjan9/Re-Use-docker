echo "***** Executing startup_server.sh *****"

# 재부팅 될 때마다 실행되게끔
# 포트포워딩
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

echo "***** startup_server.sh Ended *****"
