#!/bin/bash

# 检测系统架构
ARCH=$(uname -m)
if [[ "$ARCH" != "aarch64" && "$ARCH" != "x86_64" ]]; then
    echo -e "\033[31m(￣▁￣) 哇！这个脚本只支持 ARM 和 x86_64 架构哦~ 您的系统架构是：$ARCH\033[0m"
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

case $ACTION in
    1)
        echo -e "\033[1;32m٩(｡•́‿•̀｡)۶ 您选择了安装 BBR v3！\033[0m"
        echo -e "\033[36m从 GitHub 获取最新版本中...\033[0m"
        RELEASES_URL="https://github.com/byJoey/Actions-bbr-v3/releases/latest"
        LATEST_RELEASE_PAGE=$(curl -sL "$RELEASES_URL")

        if [[ -z "$LATEST_RELEASE_PAGE" ]]; then
            echo -e "\033[31m(T_T) 无法获取最新版本信息，请检查网络连接。\033[0m"
            exit 1
        fi

        # 根据架构获取下载链接
        if [[ "$ARCH" == "aarch64" ]]; then
            FILE_URL=$(echo "$LATEST_RELEASE_PAGE" | grep -oP '(?<=href=").*kernel_release_arm64_.*?\.tar\.gz(?=")' | head -n 1)
        elif [[ "$ARCH" == "x86_64" ]]; then
            FILE_URL=$(echo "$LATEST_RELEASE_PAGE" | grep -oP '(?<=href=").*kernel_release_x86_64_.*?\.tar\.gz(?=")' | head -n 1)
        fi

        if [[ -z "$FILE_URL" ]]; then
            echo -e "\033[31m(T_T) 找不到适合您架构的内核文件。\033[0m"
            exit 1
        fi

        # 完整下载链接
        FILE_URL="https://github.com$FILE_URL"
        FILE_NAME=$(basename "$FILE_URL")

        echo -e "\033[36m下载内核文件：$FILE_NAME...\033[0m"
        wget "$FILE_URL" -O "/tmp/$FILE_NAME"
        if [[ $? -ne 0 ]]; then
            echo -e "\033[31m(T_T) 下载失败，请检查网络。\033[0m"
            exit 1
        fi

        echo -e "\033[36m解压安装包...\033[0m"
        tar -xf "/tmp/$FILE_NAME" -C /tmp/
        sudo dpkg -i /tmp/linux-*.deb
        rm -rf /tmp/linux-*.deb /tmp/"$FILE_NAME"

        echo -e "\033[36m更新 GRUB 配置...\033[0m"
        sudo update-grub

        echo -e "\033[1;32m(＾▽＾) 安装完成，请重启系统加载新内核！\033[0m"
        ;;

    2)
        echo -e "\033[1;32m检查是否为 BBR v3...\033[0m"
        BBR_INFO=$(modinfo tcp_bbr 2>/dev/null)
        if [[ "$BBR_INFO" == *"BBR v3"* ]]; then
            echo -e "\033[1;32mBBR v3 已安装~\033[0m"
        else
            echo -e "\033[31m没有找到 BBR v3，当前内核模块信息：\033[0m"
            echo "$BBR_INFO"
        fi
        ;;

    3)
        echo -e "\033[1;32m选择 BBR + FQ 加速...\033[0m"
        ALGO="bbr"
        QDISC="fq"
        ask_to_save
        ;;

    4)
        echo -e "\033[1;32m选择 BBR + FQ_PIE 加速...\033[0m"
        ALGO="bbr"
        QDISC="fq_pie"
        modprobe pie || echo -e "\033[31m未找到 pie 模块，可能无法使用 fq_pie。\033[0m"
        ask_to_save
        ;;

    5)
        echo -e "\033[1;32m选择 BBR + CAKE 加速...\033[0m"
        ALGO="bbr"
        QDISC="cake"
        ask_to_save
        ;;

    6)
        echo -e "\033[1;32m开启或关闭 BBR...\033[0m"
        if [[ "$CURRENT_ALGO" == "bbr" ]]; then
            echo -e "\033[1;32m当前已启用 BBR，切换为 cubic...\033[0m"
            sudo sysctl -w net.ipv4.tcp_congestion_control=cubic
        else
            echo -e "\033[1;32m当前未启用 BBR，切换为 BBR...\033[0m"
            sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
        fi
        ;;

    7)
        echo -e "\033[1;32m卸载包含 joeyblog 的内核...\033[0m"
        dpkg -l | grep joeyblog | awk '{print $2}' | xargs sudo apt remove --purge -y
        ;;

    *)
        echo -e "\033[31m无效选项，请重新运行脚本选择正确操作。\033[0m"
        ;;
esac
