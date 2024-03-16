#!/bin/bash

echo "***** Executing backup_server.sh *****"

# .env 파일 로드
echo "Loading .env... [1/7]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# 이미지 업로드
echo "Uploading latest images... [2/7]"
#source ./scripts/upload_latest_images.sh

# backup 폴더 생성
folder_path="/home/$SSH_USERNAME/backup"
mkdir -p "$folder_path" && echo "Backup directory created"

# MySQL 백업
echo "Backing up MySQL data... [3/7]"
docker exec -i $MYSQL_CONTAINER_NAME bash -c "mysqldump -u $MYSQL_DATABASE_USERNAME -p$MYSQL_DATABASE_PASSWORD $MYSQL_DATABASE > /home/backup.sql"
docker cp $MYSQL_CONTAINER_NAME:/home/backup.sql /home/$SSH_USERNAME/backup/backup.sql

# OS 버전을 확인
os_version=$(uname -a)

if [[ $os_version == *"armv7l"* ]] || [[ $os_version == *"raspi"* ]]; then
  echo "$os_version"

  # sshpass 설치
  sudo apt-get install sshpass

  # 이전하려는 서버에 연결 및 파일 전송
  echo "Creating backup directory on the target server for migration... [4/7]"
  sshpass -p $TARGET_SERVER_PASSWORD ssh $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP -p $TARGET_SERVER_PORT -o StrictHostKeyChecking=no "mkdir -p /home/$TARGET_SERVER_USERNAME/backup" && echo "Backup directory created successfully on the target server"

  echo "Transferring MySQL backup data... [5/7]"
  sshpass -p $TARGET_SERVER_PASSWORD scp -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/backup/backup.sql $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/backup && echo "Transfer successful!" || echo "Transfer failed"

  echo "Transferring Nginx data... [6/7]"
  sshpass -p $TARGET_SERVER_PASSWORD scp -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/nginx/ $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"

  echo "Transferring env files... [7/7]"
  sshpass -p $TARGET_SERVER_PASSWORD scp -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/.env $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"
  sshpass -p $TARGET_SERVER_PASSWORD scp -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/scripts/set_env.sh $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"

else
  echo "$os_version"

  chmod 400 $TARGET_SERVER_KEYFILE_DIR

  # 이전하려는 서버에 연결 및 파일 전송
  echo "Creating backup directory on the target server for migration... [4/7]"
  ssh -i $TARGET_SERVER_KEYFILE_DIR $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP -p $TARGET_SERVER_PORT -o StrictHostKeyChecking=no "mkdir -p /home/$TARGET_SERVER_USERNAME/backup" && echo "Backup directory created successfully on the target server"

  echo "Transferring MySQL backup data... [5/7]"
  scp -i $TARGET_SERVER_KEYFILE_DIR -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/backup/backup.sql $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/backup && echo "Transfer successful!" || echo "Transfer failed"

  echo "Transferring Nginx data... [6/7]"
  scp -i $TARGET_SERVER_KEYFILE_DIR -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/nginx/ $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"

  echo "Transferring env files... [7/7]"
  scp -i $TARGET_SERVER_KEYFILE_DIR -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/.env $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"
  scp -i $TARGET_SERVER_KEYFILE_DIR -P $TARGET_SERVER_PORT /home/$SSH_USERNAME/scripts/set_env.sh $TARGET_SERVER_USERNAME@$TARGET_SERVER_IP:/home/$TARGET_SERVER_USERNAME/ && echo "Transfer successful!" || echo "Transfer failed"
fi

echo "***** backup_server.sh Ended *****"
