#!/bin/bash

# .env 파일 로드
echo "Loading .env... [2/6]"
ENV_FILE="$HOME/.env"
if [ -f "$ENV_FILE" ]; then
    export $(cat "$ENV_FILE" | xargs)
    echo "$ENV_FILE exported"
else
    echo "Cannot find $ENV_FILE"
    exit 1
fi

# /etc/ssh/sshd_config 파일 수정
# '#'으로 시작하지 않으면서 'PORT $SSH_PORT'가 아닌 줄을 찾아 제거
sudo sed -i "/^#/!{/PORT[[:space:]]$SSH_PORT/!d}" /etc/ssh/sshd_config

# 원본 파일과 수정된 파일 비교
if ! cmp -s /etc/ssh/sshd_config.bak /etc/ssh/sshd_config; then
    echo "Previous port configuration has been deleted"
    # 해당 포트를 sshd_config에 추가
    echo "PORT $SSH_PORT" | sudo tee -a /etc/ssh/sshd_config > /dev/null
    echo "PORT $SSH_PORT has been added to /etc/ssh/sshd_config"
else
    echo "No changes were made to the port configuration"
    # /etc/ssh/sshd_config 파일에서 해당 포트가 선언되었는지 확인
    if grep -q "^PORT $SSH_PORT" /etc/ssh/sshd_config; then
        echo "PORT $SSH_PORT is already set in /etc/ssh/sshd_config"
    else
        # 해당 포트를 sshd_config에 추가
        echo "PORT $SSH_PORT" | sudo tee -a /etc/ssh/sshd_config > /dev/null
        echo "PORT $SSH_PORT has been added to /etc/ssh/sshd_config"
    fi
fi
