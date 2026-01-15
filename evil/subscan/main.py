#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0
#
# Based on: https://github.com/yitong2333/proxy-minging
# Description: The script harvests, validates, and classifies proxy subscription links from Telegram channels.
# Copyright (c) 2026 honeok <i@honeok.com>

import base64
import re
import threading
from datetime import datetime
from urllib.parse import unquote

import requests
import yaml
from loguru import logger
from retry import retry
from tqdm import tqdm

valid_subscriptions = []
valid_clash_list = []
valid_v2_list = []

thread_semaphore = threading.Semaphore(64)


@logger.catch
def load_channel_config():
    with open("./channel.yaml", encoding="UTF-8") as f:
        data = yaml.load(f, Loader=yaml.FullLoader)

    channel_urls = data["tgchannel"]
    formatted_urls = []
    for url in channel_urls:
        url_suffix = url.split("/")[-1]
        url = "https://t.me/s/" + url_suffix
        formatted_urls.append(url)
    return formatted_urls


@logger.catch
def fetch_channel_links(channel_url):
    try:
        with requests.post(channel_url) as resp:
            page_content = resp.text

        found_urls = re.findall(
            "https?://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]", page_content
        )
        found_proxies = re.findall(
            r"vmess://[^\s<]+|vless://[^\s<]+|ss://[^\s<]+|ssr://[^\s<]+|trojan://[^\s<]+|hy2://[^\s<]+|hysteria2://[^\s<]+",
            page_content,
        )
        logger.info(channel_url + "\t获取成功")
    except Exception as e:
        logger.warning(channel_url + "\t获取失败")
        logger.error(channel_url + str(e))
        found_urls = []
        found_proxies = []
    finally:
        return found_urls, found_proxies


def is_valid_protocol(text):
    protocols = ["ss://", "ssr://", "vmess://", "trojan://", "vless://"]
    for protocol in protocols:
        if protocol in text:
            return True
    return False


def is_future_time(timestamp):
    if len(str(timestamp)) >= 13:
        # 毫秒时间戳转换为秒
        timestamp = timestamp / 1000

    now_timestamp = datetime.now().timestamp()

    if timestamp > now_timestamp:
        return True
    else:
        return False


@logger.catch
def check_subscription(url, progress_bar):
    headers = {"User-Agent": "clash-verge/v2.0.2"}

    with thread_semaphore:

        @retry(tries=2)
        def start_check(target_url):
            res = requests.get(target_url, headers=headers, timeout=5)
            if res.status_code == 200:
                try:  # 有流量信息
                    info = res.headers["subscription-userinfo"]
                    if info:
                        expire_match = re.search(r"expire=(\d+)", info)
                        traffic_match = re.search(
                            r"upload=(\d+); download=(\d+); total=(\d+)", info
                        )
                        if traffic_match:
                            upload = int(traffic_match.group(1))
                            download = int(traffic_match.group(2))
                            total = int(traffic_match.group(3))
                        if expire_match:  # 如果有过期时间
                            expire_time = int(expire_match.group(1))
                            if is_future_time(expire_time):  # 没过期
                                if (
                                    total - (upload + download) > 1073741824
                                ):  # 剩余流量大于1GB
                                    valid_subscriptions.append(target_url)
                                else:
                                    print(f"\n订阅-{target_url} 剩余流量小于1G,跳过")
                                    pass
                        else:
                            if (
                                total - (upload + download) > 1073741824
                            ):  # 剩余流量大于1GB
                                valid_subscriptions.append(target_url)
                            else:
                                pass
                    else:
                        raise Exception
                except:
                    # 判断是否为clash
                    try:
                        u = re.findall("proxies:", res.text)[0]
                        if u == "proxies:":
                            valid_clash_list.append(target_url)
                    except:
                        # 判断是否为v2
                        try:
                            # 解密base64
                            text_content = res.text[:64]
                            decoded_text = base64.b64decode(text_content)
                            decoded_text = str(decoded_text)
                            if is_valid_protocol(decoded_text):
                                valid_v2_list.append(target_url)
                        # 均不是则非订阅链接
                        except:
                            pass
            else:
                pass

        try:
            start_check(url)
        except:
            pass
        progress_bar.update(1)


if __name__ == "__main__":
    collected_data = {"机场订阅": [], "clash订阅": [], "v2订阅": []}

    channel_config_list = load_channel_config()
    logger.info("读取channel成功")

    all_urls = []
    all_proxies = []
    allow_keywords = [
        "sub",
        "clash",
        "paste",
        "tt.vg",
        "shz.al",
        "proxies",
        "raw.githubusercontent.com",
    ]
    deny_keywords = ["https://t.me/"]

    for channel_url in channel_config_list:
        temp_urls, temp_proxies = fetch_channel_links(channel_url)
        for url in temp_urls:
            if any(item in url for item in allow_keywords) and all(
                item not in url for item in deny_keywords
            ):
                all_urls.append(url)
        all_proxies.extend(temp_proxies)

    logger.info("开始订阅筛选")
    all_urls = list(set(all_urls))

    progress_bar = tqdm(total=len(all_urls), desc="订阅筛选：")
    thread_pool = []

    for url in all_urls:
        t = threading.Thread(target=check_subscription, args=(url, progress_bar))
        thread_pool.append(t)
        t.setDaemon(True)
        t.start()
    for t in thread_pool:
        t.join()
    progress_bar.close()

    logger.info("筛选完成")

    old_sub_list = collected_data["机场订阅"]
    old_clash_list = collected_data["clash订阅"]
    old_v2_list = collected_data["v2订阅"]

    valid_subscriptions.extend(old_sub_list)
    valid_clash_list.extend(old_clash_list)
    valid_v2_list.extend(old_v2_list)

    valid_subscriptions = sorted(set(valid_subscriptions))
    valid_clash_list = sorted(set(valid_clash_list))
    valid_v2_list = sorted(set(valid_v2_list))
    sorted_proxies = sorted(set(all_proxies))

    collected_data.update({"机场订阅": valid_subscriptions})
    collected_data.update({"clash订阅": valid_clash_list})
    collected_data.update({"v2订阅": valid_v2_list})

    # 链接分组
    with open("latest.yaml", "w", encoding="utf-8") as f:
        yaml.dump(collected_data, f, allow_unicode=True)

    # 链接列表
    with open("url.txt", "w", encoding="utf-8") as f:
        for line in all_urls:
            f.write(line)
            f.write("\n")

    # 直接提供的代理列表
    with open("v2ray.txt", "w", encoding="utf-8") as f:
        for line in sorted_proxies:
            f.write(unquote(line))
            f.write("\n")
