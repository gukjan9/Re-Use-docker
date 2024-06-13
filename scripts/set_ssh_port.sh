#!/bin/bash

echo "***** Executing set_ssh_port.sh *****"

# .env 파일 로드
ENV_FILE="$HOME/.env_v1"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

TARGET_FILE="/etc/ssh/sshd_config"

# 원본 파일의 복사본 생성
sudo cp "$TARGET_FILE" "${TARGET_FILE}.bak"

# /etc/ssh/sshd_config 파일 수정
# '#'으로 시작하지 않으면서 'PORT $SSH_PORT'가 아닌 줄을 찾아 제거
sudo sed -i "/^#/!{/PORT[[:space:]]\+[0-9]\+/{/\b$SSH_PORT\b/!d}}" "$TARGET_FILE"

# 원본 파일과 수정된 파일 비교
if ! cmp -s "${TARGET_FILE}.bak" "$TARGET_FILE"; then
    echo "Previous port configuration has been deleted"
    # 해당 포트를 sshd_config에 추가
    echo "PORT $SSH_PORT" | sudo tee -a $TARGET_FILE > /dev/null
    echo "Custom PORT has been added to target file"
else
    echo "No changes were made to the port configuration"
    # /etc/ssh/sshd_config 파일에서 해당 포트가 선언되었는지 확인
    if grep -q "^PORT $SSH_PORT" $TARGET_FILE; then
        echo "Custom PORT is already set in target file"
    else
        # 해당 포트를 sshd_config에 추가
        echo "PORT $SSH_PORT" | sudo tee -a $TARGET_FILE > /dev/null
        echo "Custom PORT has been added to target file"
    fi
fi

echo "***** set_ssh_port.sh Ended *****"
