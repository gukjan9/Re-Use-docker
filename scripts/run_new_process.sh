echo "Starting run_new_process.sh"

docker-compose down
docker-compose pull
docker-compose up -d

echo "run_new_process.sh Ended"
