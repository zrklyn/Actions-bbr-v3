#!/bin/bash

# 检查并安装必要的依赖
REQUIRED_CMDS=("curl" "wget" "dpkg" "awk" "tar" "sed" "sysctl" "update-grub")
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "\033[31m缺少依赖：$cmd，正在安装...\033[0m"
        sudo apt-get update && sudo apt-get install -y $cmd
    fi
done

# 检测系统架构
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "x86_64" ]]; then
    echo -e "\033[31m(￣\u25A1￣)哇！这个脚本只支持 ARM 和 x86_64 架构哦~ 您的系统架构是：$ARCH\033[0m"
    exit 1
fi

# 获取当前 BBR 状态
CURRENT_ALGO=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
CURRENT_QDISC=$(sysctl net.core.default_qdisc | awk '{print $3}')

# sysctl 配置文件路径
SYSCTL_CONF="/etc/sysctl.d/99-joeyblog.conf"

# 函数：清理 sysctl.d 中的旧配置
clean_sysctl_conf() {
    if [[ ! -f "$SYSCTL_CONF" ]]; then
        sudo touch "$SYSCTL_CONF"
    fi
    sudo sed -i '/net.core.default_qdisc/d' "$SYSCTL_CONF"
    sudo sed -i '/net.ipv4.tcp_congestion_control/d' "$SYSCTL_CONF"
}

# 函数：询问是否永久保存更改
ask_to_save() {
    echo -n -e "\033[36m(｡♥‿♥｡) 要将这些配置永久保存到 $SYSCTL_CONF 吗？(y/n): \033[0m"
    read -r SAVE
    
    if [[ "$SAVE" == "y" || "$SAVE" == "Y" ]]; then
        clean_sysctl_conf

        echo "net.core.default_qdisc=$QDISC" | sudo tee -a "$SYSCTL_CONF" > /dev/null
        echo "net.ipv4.tcp_congestion_control=$ALGO" | sudo tee -a "$SYSCTL_CONF" > /dev/null
        sudo sysctl --system > /dev/null
        echo -e "\033[1;32m(☆^ー^☆) 更改已永久保存啦~\033[0m"
    else
        echo -e "\033[33m(⌒_⌒;) 好吧，没有永久保存呢~\033[0m"
    fi
}

# 美化输出的分隔线
print_separator() {
    echo -e "\033[34m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
}

# 欢迎信息
print_separator
echo -e "\033[1;35m(☆ω☆)✧*｡ 欢迎来到 BBR 管理脚本世界哒！ ✧*｡(☆ω☆)\033[0m"
print_separator
echo -e "\033[36m当前 TCP 拥塞控制算法：\033[0m\033[1;32m$CURRENT_ALGO\033[0m"
echo -e "\033[36m当前队列管理算法：\033[0m\033[1;32m$CURRENT_QDISC\033[0m"
print_separator

# 选项部分美化
echo -e "\033[1;33m╭( ･ㅂ･)و ✧ 你可以选择以下操作哦：\033[0m"
echo -e "\033[33m 1. 🛠️  安装 BBR v3\033[0m"
echo -e "\033[33m 2. 🔍 检查是否为 BBR v3\033[0m"
echo -e "\033[33m 3. ⚡ 使用 BBR + FQ 加速\033[0m"
echo -e "\033[33m 4. ⚡ 使用 BBR + FQ_PIE 加速\033[0m"
echo -e "\033[33m 5. ⚡ 使用 BBR + CAKE 加速\033[0m"
echo -e "\033[33m 6. 🔧 开启或关闭 BBR\033[0m"
echo -e "\033[33m 7. 🗑️  卸载\033[0m"
print_separator
echo -e "\033[34m作者：Joey ✧٩(◕‿◕｡)۶✧\033[0m"
echo -e "\033[34m博客：https://joeyblog.net\033[0m"
echo -e "\033[34m反馈群组：https://t.me/+ft-zI76oovgwNmRh\033[0m"
print_separator

# 提示用户选择操作
echo -n -e "\033[36m请选择一个操作 (1-7) (｡･ω･｡): \033[0m"
read -r ACTION

case "$ACTION" in
    1)
        echo -e "\033[1;32m٩(｡•́‿•̀｡)۶ 您选择了安装 BBR v3！\033[0m"
        
        # 检查是否已经安装了旧版本并卸载
        echo -e "\033[36m正在检查旧版内核...( •̀ᴗ•́ )\033[0m"
        if dpkg -l | grep -q "joeyblog"; then
            echo -e "\033[36m发现旧版本内核，正在卸载~\033[0m"
            sudo apt remove --purge $(dpkg -l | grep "joeyblog" | awk '{print $2}') -y
        fi

        # 获取最新版本下载链接
        BASE_URL="https://api.github.com/repos/byJoey/Actions-bbr-v3/releases/latest"
        LATEST_RELEASE=$(curl -s $BASE_URL | grep "tag_name" | awk -F '"' '{print $4}')

        if [[ "$ARCH" == "aarch64" ]]; then
            FILE="kernel_release_arm64_${LATEST_RELEASE#v}.tar.gz"
        elif [[ "$ARCH" == "x86_64" ]]; then
            FILE="kernel_release_x86_64_${LATEST_RELEASE#v}.tar.gz"
        fi

        DOWNLOAD_URL="https://github.com/byJoey/Actions-bbr-v3/releases/download/$LATEST_RELEASE/$FILE"

        echo -e "\033[36m(☆ω☆) 从 GitHub 下载 $FILE 中...\033[0m"
        wget "$DOWNLOAD_URL" -O "/tmp/kernel_release.tar.gz"
        if [[ $? -ne 0 ]]; then
            echo -e "\033[31m(T_T) 下载失败了哦~\033[0m" >&2
            exit 1
        fi

        echo -e "\033[36m( •̀ ω •́ )✧ 解压和安装文件中...\033[0m"
        tar -xzvf /tmp/kernel_release.tar.gz -C /tmp/
        sudo dpkg -i /tmp/linux-*.deb

        echo -e "\033[36m清理下载的临时文件... ( ˘･з･)\033[0m"
        rm /tmp/linux-*.deb /tmp/kernel_release.tar.gz

        echo -e "\033[36m正在更新 GRUB 配置...\033[0m"
        sudo update-grub

        echo -e "\033[1;32m(●'◡'●) 安装完成啦，请重启系统加载新内核吧！\033[0m"
        ;;

    2)
        echo -e "\033[1;32m(｡･ω･｡) 检查是否为 BBR v3...\033[0m"
        BBR_INFO=$(sudo modinfo tcp_bbr)
        BBR_VERSION=$(echo "$BBR_INFO" | grep -i "version:" | awk '{print $2}')

        if [[ "$BBR_VERSION" == *"3"* ]]; then
            echo -e "\033[1;32mヽ(✿ﾟ▽ﾟ)ノ BBR v3 已安装~\033[0m"
        else
            echo -e "\033[31m(￣﹃￣) 哎呀，BBR v3 没有找到，当前版本是：$BBR_VERSION\033[0m"
        fi
        ;;

    3)
        echo -e "\033[1;32m(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧ 使用 BBR + FQ 加速！\033[0m"
        ALGO="bbr"
        QDISC="fq"
        ask_to_save
        echo -e "\033[1;32m(＾▽＾) BBR + FQ 已经设置好啦！\033[0m"
        ;;

    4)
        echo -e "\033[1;32m٩(•‿•)۶ 使用 BBR + FQ_PIE 加速！\033[0m"
        ALGO="
