#!/usr/bin/env bash

# shellcheck disable=all

yellow='\033[93m'
red='\033[31m'
green='\033[92m'
blue='\033[36m'
white='\033[0m'
_yellow() { echo -e "${yellow}$*${white}"; }
_red() { echo -e "${red}$*${white}"; }
_green() { echo -e "${green}$*${white}"; }
_blue() { echo -e "${blue}$*${white}"; }

userAgent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.74 Safari/537.36'

# 流媒体解锁
# https://github.com/1-stream/RegionRestrictionCheck

MediaUnlockTest_Netflix() {
    local httpStatus_1 httpStatus_2 temp_request

    httpStatus_1=$(curl -fsLI -X GET -A "$userAgent" -m 10 -w "%{http_code}" -o /dev/null --tlsv1.3 "https://www.netflix.com/title/81280792" 2>&1)
    httpStatus_2=$(curl -fsLI -X GET -A "$userAgent" -m 10 -w "%{http_code}" -o /dev/null --tlsv1.3 "https://www.netflix.com/title/70143836" 2>&1)
    temp_request=$(curl -fSsI -X GET -m 10 -w '%{redirect_url}' -o /dev/null --tlsv1.3 "https://www.netflix.com/login" 2>&1)

    Netflix_region=$(echo "$temp_request" | cut -d'/' -f4 | cut -d'-' -f1 | tr '[:lower:]' '[:upper:]')

    if grep -q '^curl' <<< "$temp_request"; then
        echo " Netflix            : $(_red 'Failed (Network Connection)')"
        return
    fi

    [ -z "$Netflix_region" ] && Netflix_region="US"

    case "$httpStatus_1:$httpStatus_2" in
        "404:404") echo " Netflix            : $(_yellow "Originals Only (Region: $Netflix_region)")" ;;
        "403:403") echo " Netflix            : $(_red 'No')" ;;
        "200:"* | *":200") echo " Netflix            : $(_green "Yes (Region: $Netflix_region)")" ;;
        "000:"*) echo " Netflix            : $(_red 'Failed (Network Connection)')" ;;
        *) echo " Netflix            : $(_red 'Failed')" ;;
    esac
}

UnlockYouTubePremiumTest() {
    local tmpresult region result
    tmpresult=$(curl -sS -H "Accept-Language: en" "https://www.youtube.com/premium" 2>&1)
    region=$(curl -fsL -A "$userAgent" -m 10 "https://www.youtube.com/premium" | grep "countryCode" | sed 's/.*"countryCode"//' | cut -f2 -d'"')

    [ -z "$region" ] && {
        echo "$tmpresult" | grep -q 'www.google.cn' && region="CN" || region="US"
    }  

    if echo "$tmpresult" | grep -q '^curl'; then
        echo " YouTube Premium    : $(_red 'Network connection failed')"
        return
    fi
    if grep -q 'Premium is not available in your country' <<< "$tmpresult"; then
        echo " YouTube Premium    : ${yellow}No${white} ${white}${green} (Region: $region)${white}"
        return
    fi
    if grep -q 'YouTube and YouTube Music ad-free' <<< "$tmpresult"; then
        echo " YouTube Premium    : $(_green "Yes (Region: $region)")"
        return
    fi
    echo " YouTube Premium    : $(_red 'Failed')"
}

StreamingMediaUnlockTest() {
    echo " Stream Media Unlock:"
    MediaUnlockTest_Netflix
    # UnlockYouTubePremiumTest
    # YouTubeCDNTest
    # UnlockBilibiliTest
    # UnlockTiktokTest
    # UnlockiQiyiIntlTest
    # UnlockChatGPTTest
}

StreamingMediaUnlockTest