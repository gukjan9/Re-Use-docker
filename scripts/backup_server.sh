echo "***** Executing backup_server.sh *****"

# .env 파일 로드
echo "Loading .env... [0/3]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 이미지 업로드
source ./scripts/upload_latest_images.sh

# MySQL 백업
docker exec $MYSQL_CONTAINER_NAME /usr/bin/mysqldump -u $MYSQL_DATABASE_USERNAME --password=$MYSQL_DATABASE_PASSWORD $MYSQL_DATABASE > backup.sql

# 생성하고자 하는 폴더 경로
folder_path="/home/ubuntu/backup"

mkdir -p "$folder_path"
echo "Directory created: $folder_path"

docker cp $MYSQL_CONTAINER_NAME:/usr/bin/mysqldump/backup.sql /home/ubuntu/backup

ssh -p $SECOND_SERVER_PORT $SECOND_SERVER_USERNAME@$SECOND_SERVER_IP "mkdir -p /home/$SECOND_SERVER_USERNAME/backup"
scp -P $SECOND_SERVER_PORT /home/ubuntu/backup/backup.sql $SECOND_SERVER_USERNAME@$SECOND_SERVER_IP:/home/$SECOND_SERVER_USERNAME/

echo "***** backup_server.sh Ended *****"
