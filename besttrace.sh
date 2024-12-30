#!/usr/bin/env bash
#
# Description: The most convenient route tracing.
#
# Copyright (C) 2024 honeok <honeok@duck.com>
# Blog: https://www.honeok.com
# https://github.com/honeok/cross

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
white='\033[0m'
_yellow() { echo -e "${yellow}$@${white}"; }
_red() { echo -e "${red}$@${white}"; }
_green() { echo -e ${green}$@${white}; }

separator() { printf "%-70s\n" "-" | sed 's/\s/-/g'; }

ip_address() {
    local ipv4_services=("ipv4.ip.sb" "ipv4.icanhazip.com" "v4.ident.me")
    local ipv6_services=("ipv6.ip.sb" "ipv6.icanhazip.com" "v6.ident.me")
    ipv4_address=""
    ipv6_address=""
    for service in "${ipv4_services[@]}"; do
        ipv4_address=$(curl -fskL4 -m 3 "$service")
        if [[ "$ipv4_address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        fi
    done
    for service in "${ipv6_services[@]}"; do
        ipv6_address=$(curl -fskL6 -m 3 "$service")
        if [[ "$ipv6_address" =~ ^[0-9a-fA-F:]+$ ]]; then
            break
        fi
    done
}

ip_address

if ! command -v nexttrace >/dev/null 2>&1 && [ ! -f "/usr/local/bin/nexttrace" ] && [ ! -f "/usr/bin/nexttrace" ]; then
    # bash <(curl -fskL raw.githubusercontent.com/nxtrace/NTrace-core/main/nt_install.sh) || { _red "Nexttrace安装失败"; exit 1; }
    bash <(curl -sL nxtrace.org/nt) || { _red "Nexttrace安装失败"; exit 1; }
fi

supported_params=$(cat <<EOF
默认执行广东、上海、北京、四川三网回程:
bash BestTrace.sh

可选参数：
  -nmg  # 内蒙古
  -hlj  # 黑龙江
  -xj   # 新疆
  -tj   # 天津
  -bj   # 北京
  -ln   # 辽宁
  -hb   # 河北
  -sd   # 山东
  -js   # 江苏
  -zj   # 浙江
  -fj   # 福建
  -ah   # 安徽
  -jx   # 江西
  -xz   # 西藏
  -sc   # 四川
  -sh   # 上海
  -gd   # 广东

指定参数示例:
  bash BestTrace.sh -h         # 帮助命令
  bash BestTrace.sh -d         # 单独删除 nexttrace
  bash BestTrace.sh -nmg       # 测试内蒙古
  bash BestTrace.sh -nmg -d    # 测试后删除 nexttrace
EOF
)

# 卸载逻辑
uninstall_nexttrace(){
    separator
    for file in "/usr/local/bin/nexttrace" "/usr/bin/nexttrace"; do
        [[ -f $file ]] && rm -f "$file" && _green "nexttrace已成功删除"
    done
}

# https://www.nodeseek.com/post-68572-1 https://www.nodeseek.com/post-129987-1
trace_area_nmg=("内蒙古电信" "内蒙古联通" "内蒙古移动")
trace_ip_nmg_v4=("nm-ct-v4.ip.zstaticcdn.com" "nm-cu-v4.ip.zstaticcdn.com" "nm-cm-v4.ip.zstaticcdn.com")
trace_ip_nmg_v6=("nm-ct-v6.ip.zstaticcdn.com" "nm-cu-v6.ip.zstaticcdn.com" "nm-cm-v6.ip.zstaticcdn.com")
trace_area_hlj=("黑龙江电信" "黑龙江联通" "黑龙江移动")
trace_ip_hlj_v4=("hl-ct-v4.ip.zstaticcdn.com" "hl-cu-v4.ip.zstaticcdn.com" "hl-cm-v4.ip.zstaticcdn.com")
trace_ip_hlj_v6=("hl-ct-v6.ip.zstaticcdn.com" "hl-cu-v6.ip.zstaticcdn.com" "hl-cm-v6.ip.zstaticcdn.com")
trace_area_xj=("新疆电信" "新疆联通" "新疆移动")
trace_ip_xj_v4=("xj-ct-v4.ip.zstaticcdn.com" "xj-cu-v4.ip.zstaticcdn.com" "xj-cm-v4.ip.zstaticcdn.com")
trace_ip_xj_v6=("xj-ct-v6.ip.zstaticcdn.com" "xj-cu-v6.ip.zstaticcdn.com" "xj-cm-v6.ip.zstaticcdn.com")
trace_area_tj=("天津电信" "天津联通" "天津移动")
trace_ip_tj_v4=("tj-ct-v4.ip.zstaticcdn.com" "tj-cu-v4.ip.zstaticcdn.com" "tj-cm-v4.ip.zstaticcdn.com")
trace_ip_tj_v6=("tj-ct-v6.ip.zstaticcdn.com" "tj-cu-v6.ip.zstaticcdn.com" "tj-cm-v6.ip.zstaticcdn.com")
trace_area_bj=("北京电信" "北京联通" "北京移动")
trace_ip_bj_v4=("bj-ct-v4.ip.zstaticcdn.com" "bj-cu-v4.ip.zstaticcdn.com" "bj-cm-v4.ip.zstaticcdn.com")
trace_ip_bj_v6=("bj-ct-v6.ip.zstaticcdn.com" "bj-cu-v6.ip.zstaticcdn.com" "bj-cm-v6.ip.zstaticcdn.com")
trace_area_ln=("辽宁电信" "辽宁联通" "辽宁移动")
trace_ip_ln_v4=("ln-ct-v4.ip.zstaticcdn.com" "ln-cu-v4.ip.zstaticcdn.com" "ln-cm-v4.ip.zstaticcdn.com")
trace_ip_ln_v6=("ln-ct-v6.ip.zstaticcdn.com" "ln-cu-v6.ip.zstaticcdn.com" "ln-cm-v6.ip.zstaticcdn.com")
trace_area_hb=("河北电信" "河北联通" "河北移动")
trace_ip_hb_v4=("he-ct-v4.ip.zstaticcdn.com" "he-cu-v4.ip.zstaticcdn.com" "he-cm-v4.ip.zstaticcdn.com")
trace_ip_hb_v6=("he-ct-v6.ip.zstaticcdn.com" "he-cu-v6.ip.zstaticcdn.com" "he-cm-v6.ip.zstaticcdn.com")
trace_area_sd=("山东电信" "山东联通" "山东移动")
trace_ip_sd_v4=("sd-ct-v4.ip.zstaticcdn.com" "sd-cu-v4.ip.zstaticcdn.com" "sd-cm-v4.ip.zstaticcdn.com")
trace_ip_sd_v6=("sd-ct-v6.ip.zstaticcdn.com" "sd-cu-v6.ip.zstaticcdn.com" "sd-cm-v6.ip.zstaticcdn.com")
trace_area_js=("江苏电信" "江苏联通" "江苏移动")
trace_ip_js_v4=("js-ct-v4.ip.zstaticcdn.com" "js-cu-v4.ip.zstaticcdn.com" "js-cm-v4.ip.zstaticcdn.com")
trace_ip_js_v6=("js-ct-v6.ip.zstaticcdn.com" "js-cu-v6.ip.zstaticcdn.com" "js-cm-v6.ip.zstaticcdn.com")
trace_area_zj=("浙江电信" "浙江联通" "浙江移动")
trace_ip_zj_v4=("zj-ct-v4.ip.zstaticcdn.com" "zj-cu-v4.ip.zstaticcdn.com" "zj-cm-v4.ip.zstaticcdn.com")
trace_ip_zj_v6=("zj-ct-v6.ip.zstaticcdn.com" "zj-cu-v6.ip.zstaticcdn.com" "zj-cm-v6.ip.zstaticcdn.com")
trace_area_fj=("福建电信" "福建联通" "福建移动")
trace_ip_fj_v4=("fj-ct-v4.ip.zstaticcdn.com" "fj-cu-v4.ip.zstaticcdn.com" "fj-cm-v4.ip.zstaticcdn.com")
trace_ip_fj_v6=("fj-ct-v6.ip.zstaticcdn.com" "fj-cu-v6.ip.zstaticcdn.com" "fj-cm-v6.ip.zstaticcdn.com")
trace_area_ah=("安徽电信" "安徽联通" "安徽移动")
trace_ip_ah_v4=("ah-ct-v4.ip.zstaticcdn.com" "ah-cu-v4.ip.zstaticcdn.com" "ah-cm-v4.ip.zstaticcdn.com")
trace_ip_ah_v6=("ah-ct-v6.ip.zstaticcdn.com" "ah-cu-v6.ip.zstaticcdn.com" "ah-cm-v6.ip.zstaticcdn.com")
trace_area_jx=("江西电信" "江西联通" "江西移动")
trace_ip_jx_v4=("jx-ct-v4.ip.zstaticcdn.com" "jx-cu-v4.ip.zstaticcdn.com" "jx-cm-v4.ip.zstaticcdn.com")
trace_ip_jx_v6=("jx-ct-v6.ip.zstaticcdn.com" "jx-cu-v6.ip.zstaticcdn.com" "jx-cm-v6.ip.zstaticcdn.com")
trace_area_xz=("西藏电信" "西藏联通" "西藏移动")
trace_ip_xz_v4=("xz-ct-v4.ip.zstaticcdn.com" "xz-cu-v4.ip.zstaticcdn.com" "xz-cm-v4.ip.zstaticcdn.com")
trace_ip_xz_v6=("xz-ct-v6.ip.zstaticcdn.com" "xz-cu-v6.ip.zstaticcdn.com" "xz-cm-v6.ip.zstaticcdn.com")
trace_area_sc=("四川电信" "四川联通" "四川移动")
trace_ip_sc_v4=("sc-ct-v4.ip.zstaticcdn.com" "sc-cu-v4.ip.zstaticcdn.com" "sc-cm-v4.ip.zstaticcdn.com")
trace_ip_sc_v6=("sc-ct-v6.ip.zstaticcdn.com" "sc-cu-v6.ip.zstaticcdn.com" "sc-cm-v6.ip.zstaticcdn.com")
trace_area_sh=("上海电信" "上海联通" "上海移动")
trace_ip_sh_v4=("sh-ct-v4.ip.zstaticcdn.com" "sh-cu-v4.ip.zstaticcdn.com" "sh-cm-v4.ip.zstaticcdn.com")
trace_ip_sh_v6=("sh-ct-v6.ip.zstaticcdn.com" "sh-cu-v6.ip.zstaticcdn.com" "sh-cm-v6.ip.zstaticcdn.com")
trace_area_gd=("广东电信" "广东联通" "广东移动")
trace_ip_gd_v4=("gd-ct-v4.ip.zstaticcdn.com" "gd-cu-v4.ip.zstaticcdn.com" "gd-cm-v4.ip.zstaticcdn.com")
trace_ip_gd_v6=("gd-ct-v6.ip.zstaticcdn.com" "gd-cu-v6.ip.zstaticcdn.com" "gd-cm-v6.ip.zstaticcdn.com")

clear

# 遍历IP解析并trace
perform_trace() {
    local -n areas=$1
    local -n ips=$2
        
    for i in "${!areas[@]}"; do
        separator
        analysis=$(getent hosts "${ips[i]}" | awk '{ print $1 }')
        
        if [[ -n "$analysis" ]]; then
            _yellow "${areas[i]} ${analysis}"
        else
            _red "${areas[i]} 未能解析域名${ips[i]}"
        fi
    
        # 使用域名执行追踪（确保原始域名仍被使用）
        nexttrace -M "${ips[i]}"
    done
}

# 根据网络栈决定追踪类型
trace_type_v4=false
trace_type_v6=false
if [[ -n "$ipv4_address" && -n "$ipv6_address" ]]; then
    trace_type_v4=true
    trace_type_v6=true
elif [[ -n "$ipv4_address" ]]; then
    trace_type_v4=true
elif [[ -n "$ipv6_address" ]]; then
    trace_type_v6=true
else
    _red "错误：无法检测到有效的网络栈，请检查网络配置！"
    exit 1
fi

case "$1" in
    -nmg)
        $trace_type_v4 && perform_trace trace_area_nmg trace_ip_nmg_v4
        $trace_type_v6 && perform_trace trace_area_nmg trace_ip_nmg_v6
        ;;
    -hlj)
        $trace_type_v4 && perform_trace trace_area_hlj trace_ip_hlj_v4
        $trace_type_v6 && perform_trace trace_area_hlj trace_ip_hlj_v6
        ;;
    -xj)
        $trace_type_v4 && perform_trace trace_area_xj trace_ip_xj_v4
        $trace_type_v6 && perform_trace trace_area_xj trace_ip_xj_v6
        ;;
    -tj)
        $trace_type_v4 && perform_trace trace_area_tj trace_ip_tj_v4
        $trace_type_v6 && perform_trace trace_area_tj trace_ip_tj_v6
        ;;
    -bj)
        $trace_type_v4 && perform_trace trace_area_bj trace_ip_bj_v4
        $trace_type_v6 && perform_trace trace_area_bj trace_ip_bj_v6
        ;;
    -ln)
        $trace_type_v4 && perform_trace trace_area_ln trace_ip_ln_v4
        $trace_type_v6 && perform_trace trace_area_ln trace_ip_ln_v6
        ;;
    -hb)
        $trace_type_v4 && perform_trace trace_area_hb trace_ip_hb_v4
        $trace_type_v6 && perform_trace trace_area_hb trace_ip_hb_v6
        ;;
    -sd)
        $trace_type_v4 && perform_trace trace_area_sd trace_ip_sd_v4
        $trace_type_v6 && perform_trace trace_area_sd trace_ip_sd_v6
        ;;
    -js)
        $trace_type_v4 && perform_trace trace_area_js trace_ip_js_v4
        $trace_type_v6 && perform_trace trace_area_js trace_ip_js_v6
        ;;
    -zj)
        $trace_type_v4 && perform_trace trace_area_zj trace_ip_zj_v4
        $trace_type_v6 && perform_trace trace_area_zj trace_ip_zj_v6
        ;;
    -fj)
        $trace_type_v4 && perform_trace trace_area_fj trace_ip_fj_v4
        $trace_type_v6 && perform_trace trace_area_fj trace_ip_fj_v6
        ;;
    -ah)
        $trace_type_v4 && perform_trace trace_area_ah trace_ip_ah_v4
        $trace_type_v6 && perform_trace trace_area_ah trace_ip_ah_v6
        ;;
    -jx)
        $trace_type_v4 && perform_trace trace_area_jx trace_ip_jx_v4
        $trace_type_v6 && perform_trace trace_area_jx trace_ip_jx_v6
        ;;
    -xz)
        $trace_type_v4 && perform_trace trace_area_xz trace_ip_xz_v4
        $trace_type_v6 && perform_trace trace_area_xz trace_ip_xz_v6
        ;;
    -sc)
        $trace_type_v4 && perform_trace trace_area_sc trace_ip_sc_v4
        $trace_type_v6 && perform_trace trace_area_sc trace_ip_sc_v6
        ;;
    -sh)
        $trace_type_v4 && perform_trace trace_area_sh trace_ip_sh_v4
        $trace_type_v6 && perform_trace trace_area_sh trace_ip_sh_v6
        ;;
    -gd)
        $trace_type_v4 && perform_trace trace_area_gd trace_ip_gd_v4
        $trace_type_v6 && perform_trace trace_area_gd trace_ip_gd_v6
        ;;
    -h)
        echo -e "$supported_params"
        ;;
    -d)
        uninstall_nexttrace
        ;;
    *)
        if [ -z "$1" ]; then
            $trace_type_v4 && perform_trace trace_area_gd trace_ip_gd_v4
            $trace_type_v4 && perform_trace trace_area_sh trace_ip_sh_v4
            $trace_type_v4 && perform_trace trace_area_bj trace_ip_bj_v4
            $trace_type_v4 && perform_trace trace_area_sc trace_ip_sc_v4
            $trace_type_v6 && perform_trace trace_area_gd trace_ip_gd_v6
            $trace_type_v6 && perform_trace trace_area_sh trace_ip_sh_v6
            $trace_type_v6 && perform_trace trace_area_bj trace_ip_bj_v6
            $trace_type_v6 && perform_trace trace_area_sc trace_ip_sc_v6
        else
            _red "错误：无效的参数，参数${1}不被支持！"
            echo -e "$supported_params"
        fi
        ;;
esac

if [ "$2" == "-d" ]; then
    uninstall_nexttrace
fi
