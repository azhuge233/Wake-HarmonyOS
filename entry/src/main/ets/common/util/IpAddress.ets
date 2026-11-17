/** IPv4 数字转点分十进制字符串 */
export function ipStringFromNumber(ipNum: number): string {
    return (ipNum >>> 24) + '.' + (ipNum >> 16 & 0xFF) + '.' + (ipNum >> 8 & 0xFF) + '.' + (ipNum & 0xFF);
}

/** 由 IP 与掩码算出 IPv4 广播地址 */
export function broadcastAddressFrom(ip: number, netmask: number): string {
    const broadcastNumber = ip | ~netmask;
    return ipStringFromNumber(broadcastNumber);
}