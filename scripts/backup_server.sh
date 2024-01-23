echo "***** Executing backup_server.sh *****"

# .env 파일 로드
echo "Loading .env... [1/6]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 이미지 업로드
echo "Uploading latest images... [2/6]"
source ./scripts/upload_latest_images.sh

# backup 폴더 생성
folder_path="/home/ubuntu/backup"
mkdir -p "$folder_path" && echo "Directory created: $folder_path"

# MySQL 백업
echo "Backing up MySQL data... [3/6]"
docker exec $MYSQL_CONTAINER_NAME mysqldump -u root -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE > /tmp/backup.sql
docker cp $MYSQL_CONTAINER_NAME:/tmp/backup.sql /home/ubuntu/backup/backup.sql

# sshpass 설치
sudo apt-get install sshpass

# 이전하려는 서버에 연결 및 파일 전송
echo "Creating backup directory on the target server for migration... [4/6]"
sshpass -p $TARGET_SERVER_PASSWORD ssh $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP -p $TARGET_SERVER_PORT -o StrictHostKeyChecking=no "mkdir -p /home/$TARGET_SERVER_USERNAME/backup" && echo "Backup directory created successfully on the target server"

echo "Transferring MySQL backup data... [5/6]"
sshpass -p $TARGET_SERVER_PASSWORD scp -P $TARGET_SERVER_PORT /home/ubuntu/backup/backup.sql $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/backup && echo "Transfer successful!" || echo "Transfer failed"

echo "Transferring env files... [6/6]"
sshpass -p $TARGET_SERVER_PASSWORD scp -P $TARGET_SERVER_PORT /home/ubuntu/.env $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"
sshpass -p $TARGET_SERVER_PASSWORD scp -P $TARGET_SERVER_PORT /home/ubuntu/scripts/set_env.sh $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"

echo "***** backup_server.sh Ended *****"
