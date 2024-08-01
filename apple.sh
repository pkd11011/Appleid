#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
PLAIN='\033[0m'
BLUE='\033[36m'

echo "Vui lòng chọn ngôn ngữ | Please select a language"
echo -e "${YELLOW}Lưu ý rằng ngôn ngữ bạn chọn sẽ ảnh hưởng đến đầu ra của chương trình backend${PLAIN}"
echo -e "注意，你选择的语言将影响后端程序的输出${PLAIN}"
echo -e "${BLUE}Tuy nhiên, script cài đặt này chỉ hỗ trợ tiếng Trung và tiếng Anh${PLAIN}"
echo -e "${BLUE}However no support for language other than Chinese and English is provided in this installation script${PLAIN}"
echo "1. Tiếng Trung giản thể (zh_cn)"
echo "2. English (en_us)"
echo "3. Tiếng Việt (vi_vn)"
read -e -p "Nhập lựa chọn của bạn (1/2/3): " language

if [ "$language" != "1" ] && [ "$language" != "2" ] && [ "$language" != "3" ]; then
    echo "Nhập không hợp lệ, thoát | Input error, exit"
    exit 1
fi

if [ "$language" == '1' ]; then
    echo "Quản lý Apple ID của bạn theo cách mới, chương trình tự động kiểm tra & mở khóa Apple ID dựa trên câu hỏi bảo mật"
    echo "Địa chỉ dự án: github.com/pplulee/appleid_auto"
    echo "Nhóm thảo luận trên TG: @appleunblocker"
    echo "==============================================================="
else
    echo "Manage your Apple ID in a new way, an automated Apple ID detection & unlocking program based on security questions"
    echo "Project address: github.com/pplulee/appleid_auto"
    echo "Project discussion Telegram group: @appleunblocker"
    echo "==============================================================="
fi

if command -v docker >/dev/null 2>&1; then
    echo "Docker đã được cài đặt | Docker is installed"
else
    echo "Docker chưa được cài đặt, bắt đầu cài đặt... | Docker is not installed, start installing..."
    curl -fsSL get.docker.com | sh
    systemctl enable docker && systemctl restart docker
    echo "Docker đã được cài đặt | Docker installed"
fi

if [ "$language" == '1' ]; then
    echo "Bắt đầu cài đặt backend Apple_Auto"
    read -e -p "Nhập URL API (tên miền front-end, định dạng http[s]://xxx.xxx): " api_url
    read -e -p "Nhập API Key: " api_key
    read -e -p "Có muốn bật cập nhật tự động không? (y/n): " auto_update
    read -e -p "Nhập khoảng thời gian đồng bộ nhiệm vụ (đơn vị: phút, mặc định 15): " sync_time
else
    echo "Start installing Apple_Auto backend"
    read -e -p "Please enter API URL (http://xxx.xxx): " api_url
    read -e -p "Please enter API Key: " api_key
    read -e -p "Do you want to enable auto update? (y/n): " auto_update
    read -e -p "Please enter the task synchronization period (unit: minute, default 15): " sync_time
fi

if [ -z "$sync_time" ]; then
    sync_time=15
fi

read -e -p "Có muốn triển khai container Selenium Docker không? (y/n): " run_webdriver

if [ "$run_webdriver" == "y" ]; then
    echo "Bắt đầu triển khai container Selenium Docker | Start deploying Selenium Docker container"
    read -e -p "Nhập cổng chạy Selenium (mặc định 4444): " webdriver_port
    if [ -z "$webdriver_port" ]; then
        webdriver_port=4444
    fi
    read -e -p "Nhập số phiên tối đa của Selenium (mặc định 10): " webdriver_max_session
    if [ -z "$webdriver_max_session" ]; then
        webdriver_max_session=10
    fi
    if docker ps -a --format '{{.Names}}' | grep -q '^webdriver$'; then
        docker rm -f webdriver
    fi
    docker pull selenium/standalone-chrome
    docker run -d --name=webdriver --log-opt max-size=1m --log-opt max-file=1 --shm-size="1g" --restart=always \
        -e SE_NODE_MAX_SESSIONS=$webdriver_max_session \
        -e SE_NODE_OVERRIDE_MAX_SESSIONS=true \
        -e SE_SESSION_RETRY_INTERVAL=1 \
        -e SE_START_VNC=false \
        -p $webdriver_port:4444 selenium/standalone-chrome
    echo "Triển khai container Webdriver Docker hoàn tất | Webdriver Docker container deployed"
fi

enable_auto_update=$([ "$auto_update" == "y" ] && echo True || echo False)

if docker ps -a --format '{{.Names}}' | grep -q '^appleauto$'; then
    docker rm -f appleauto
fi

docker pull sahuidhsu/appleauto_backend
docker run -d --name=appleauto --log-opt max-size=1m --log-opt max-file=2 --restart=always --network=host \
    -e API_URL=$api_url \
    -e API_KEY=$api_key \
    -e SYNC_TIME=$sync_time \
    -e AUTO_UPDATE=$enable_auto_update \
    -e LANG=$language \
    -v /var/run/docker.sock:/var/run/docker.sock \
    sahuidhsu/appleauto_backend

if [ "$language" == "1" ]; then
    echo "Cài đặt hoàn tất, container đã được khởi động"
    echo "Tên container mặc định: appleauto"
    echo "Phương pháp thao tác:"
    echo "Dừng container: docker stop appleauto"
    echo "Khởi động lại container: docker restart appleauto"
    echo "Xem log container: docker logs appleauto"
else
    echo "Installation completed, container started"
    echo "Default container name: appleauto"
    echo "Operation method:"
    echo "Stop: docker stop appleauto"
    echo "Restart: docker restart appleauto"
    echo "Check status: docker logs appleauto"
fi

exit 0
