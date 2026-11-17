/**
 * 网络信息读取端口。wifiManager（ConnectivityKit）与 connection（NetworkKit）
 * 都属平台能力，在 data/ 封装，领域层只认本端口与下面的中立快照类型。
 * kit 枚举到文案之间隔一层中立键：kit 枚举留在 data/，字符串资源留在 ui/，两侧都不认识对方的类型。
 */

export interface Ipv4Snapshot {
    address: string;
    gateway: string;
    netmask: string;
    primaryDns: string;
    secondaryDns: string;
    dhcpServer: string;
    leaseSeconds: number;
}

export interface Ipv6Snapshot {
    link: string;
    global: string;
    randomGlobal: string;
    unique: string;
    randomUnique: string;
    gateway: string;
    netmask: string;
    primaryDns: string;
    secondaryDns: string;
}

export type NetworkCapabilityKey =
    'mms' | 'not-metered' | 'internet' | 'not-vpn' | 'validated' | 'portal' | 'checking-connectivity' | 'unknown';

export type NetworkBearerKey =
    'cellular' | 'wifi' | 'bluetooth' | 'ethernet' | 'vpn' | 'unknown';

export interface DefaultNetSnapshot {
    netId: number;
    upKbps: number;
    downKbps: number;
    capabilities: NetworkCapabilityKey[];
    bearers: NetworkBearerKey[];
}

export interface NetworkSnapshot {
    wifiActive: boolean;
    wifiConnected: boolean;
    hotspot: boolean;
    ipv4: Ipv4Snapshot | null;
    ipv6: Ipv6Snapshot | null;
    defaultNet: DefaultNetSnapshot | null;
}

export interface NetworkInfoPort {
    readSnapshot(): Promise<NetworkSnapshot>;
}