    2)
        echo -e "\033[1;32m(｡･ω･｡) 检查是否为 BBR v3...\033[0m"

        # 检查 tcp_bbr 模块
        if modinfo tcp_bbr &> /dev/null; then
            # 提取 version 字段并确保值为 3
            BBR_VERSION=$(modinfo tcp_bbr | awk '/^version:/ {print $2}')
            if [[ "$BBR_VERSION" == "3" ]]; then
                echo -e "\033[36m检测到 BBR 模块版本：\033[0m\033[1;32m$BBR_VERSION\033[0m"
            else
                echo -e "\033[33m(￣﹃￣) 检测到 BBR 模块，但版本是：$BBR_VERSION，不是 v3！\033[0m"
                exit 1
            fi
        else
            echo -e "\033[31m(T_T) 没有检测到 tcp_bbr 模块，请检查内核！\033[0m"
            exit 1
        fi

        # 检查当前 TCP 拥塞控制算法
        CURRENT_ALGO=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
        if [[ "$CURRENT_ALGO" == "bbr" ]]; then
            echo -e "\033[36m当前 TCP 拥塞控制算法：\033[0m\033[1;32m$CURRENT_ALGO\033[0m"
        else
            echo -e "\033[31m(⊙﹏⊙) 当前算法不是 bbr，而是：$CURRENT_ALGO\033[0m"
            exit 1
        fi

        # 检查 BBR 模块是否加载
        if lsmod | grep -q tcp_bbr; then
            echo -e "\033[36mBBR 模块已加载：\033[0m\033[1;32m$(lsmod | grep tcp_bbr)\033[0m"
        else
            echo -e "\033[31m(T_T) BBR 模块未加载，请检查内核配置和 GRUB 参数！\033[0m"
            exit 1
        fi

        echo -e "\033[1;32mヽ(✿ﾟ▽ﾟ)ノ 检测完成，BBR v3 已正确安装并生效！\033[0m"
        ;;
