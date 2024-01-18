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
echo "Uploading latest images... [1/4]"
source ./scripts/upload_latest_images.sh

# MySQL 백업
echo "Backing up MySQL data... [2/4]"
docker exec $MYSQL_CONTAINER_NAME /usr/bin/mysqldump -u $MYSQL_DATABASE_USERNAME --password=$MYSQL_DATABASE_PASSWORD $MYSQL_DATABASE > backup.sql

# backup 폴더 생성
folder_path="/home/ubuntu/backup"
mkdir -p "$folder_path" && echo "Directory created: $folder_path"

# backup 폴더에 데이터 백업
docker cp $MYSQL_CONTAINER_NAME:/usr/bin/mysqldump/backup.sql /home/ubuntu/backup

# 이전하려는 서버에 연결 및 파일 전송
echo "Creating backup directory on the target server for migration... [3/4]"
ssh -p $TARGET_SERVER_PORT $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP "mkdir -p /home/$TARGET_SERVER_USERNAME/backup" && echo "Backup directory created successfully on the target server"

echo "Transferring MySQL backup data... [4/4]"
scp -P $TARGET_SERVER_PORT /home/ubuntu/backup/backup.sql $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"

echo "***** backup_server.sh Ended *****"
