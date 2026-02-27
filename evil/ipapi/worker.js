const EMOJI_FLAG_UNICODE_STARTING_POSITION = 127397;

// 国旗转换
function getEmoji(countryCode) {
  const regex = new RegExp("^[A-Z]{2}$").test(countryCode);
  if (!countryCode || !regex) return undefined;
  try {
    return String.fromCodePoint(
      ...countryCode.split("").map((char) => EMOJI_FLAG_UNICODE_STARTING_POSITION + char.charCodeAt(0)),
    );
  } catch (error) {
    return undefined;
  }
}

// 获取 Emoji 的 Unicode 字符串
function getEmojiUnicode(countryCode) {
  const regex = new RegExp("^[A-Z]{2}$").test(countryCode);
  if (!countryCode || !regex) return undefined;
  try {
    return countryCode
      .split("")
      .map((char) => "U+" + (EMOJI_FLAG_UNICODE_STARTING_POSITION + char.charCodeAt(0)).toString(16).toUpperCase())
      .join(" ");
  } catch (error) {
    return undefined;
  }
}

// 获取 WARP 状态
function getWarp(asn) {
  if (!asn) return "off";
  const warpASNs = [13335, 209242];
  return warpASNs.includes(Number(asn)) ? "on" : "off";
}

// 获取时区偏移量
function getOffset(timeZone) {
  if (!timeZone) return undefined;
  try {
    const now = new Date();
    const utcDate = new Date(now.toLocaleString("en-US", { timeZone: "UTC", hour12: false }));
    const tzDate = new Date(now.toLocaleString("en-US", { timeZone: timeZone, hour12: false }));
    return Math.round((tzDate.getTime() - utcDate.getTime()) / 1000);
  } catch (error) {
    return undefined;
  }
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    // 根路径仅返回IP
    if (path === "/") {
      const clientIP = request.headers.get("CF-Connecting-IP");
      return new Response(clientIP, {
        headers: {
          "Content-Type": "text/plain;charset=utf-8",
        },
      });
    }

    // JSON 返回详细信息
    if (path === "/json") {
      const data = {
        ip: request.headers.get("CF-Connecting-IP"),
        asn: request.cf.asn,
        org: request.cf.asOrganization,
        colo: request.cf.colo,
        continent: request.cf.continent,
        country: request.cf.country,
        emoji: getEmoji(request.cf.country),
        emoji_unicode: getEmojiUnicode(request.cf.country),
        region: request.cf.region,
        regionCode: request.cf.regionCode,
        city: request.cf.city,
        postalCode: request.cf.postalCode,
        metroCode: request.cf.metroCode,
        latitude: request.cf.latitude,
        longitude: request.cf.longitude,
        warp: getWarp(request.cf.asn),
        offset: getOffset(request.cf.timezone),
        timezone: request.cf.timezone,
      };

      var dataJson = JSON.stringify(data, null, 2);
      return new Response(dataJson, {
        headers: {
          "Content-Type": "application/json;charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
      });
    }

    // 避免异常路径穿透
    return new Response("Not Found", { status: 404 });
  },
};
