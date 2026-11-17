import { wifiManager } from '@kit.ConnectivityKit';
import { connection } from '@kit.NetworkKit';

import { Logger } from '../common/log/Logger';
import {
    DefaultNetSnapshot,
    Ipv4Snapshot,
    Ipv6Snapshot,
    NetworkBearerKey,
    NetworkCapabilityKey,
    NetworkInfoPort,
    NetworkSnapshot
} from '../common/ports/NetworkInfoPort';
import { ipStringFromNumber } from '../common/util/IpAddress';

/**
 * 网络信息读取：wifiManager（@kit.ConnectivityKit）与 connection（@kit.NetworkKit）都在这里封装，
 * 领域只拿到中立快照；kit 枚举转成中立键，未识别的值给 'unknown'。
 */
export class NetworkInfoReader implements NetworkInfoPort {
    private LOG_TAG = '[NetworkInfoReader]';

    async readSnapshot(): Promise<NetworkSnapshot> {
        const wifiActive: boolean = this.isWifiActive();
        const wifiConnected: boolean = wifiActive && this.isWifiConnected();
        const hotspot: boolean = wifiConnected && this.isMeteredHotspot();

        const snapshot: NetworkSnapshot = {
            wifiActive: wifiActive,
            wifiConnected: wifiConnected,
            hotspot: hotspot,
            ipv4: this.readIpv4(),
            ipv6: this.readIpv6(),
            defaultNet: this.readDefaultNet()
        };

        return snapshot;
    }

    private isWifiActive(): boolean {
        try {
            return wifiManager.isWifiActive();
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取 WiFi 开关状态失败, ${JSON.stringify(err)}`);
            return false;
        }
    }

    private isWifiConnected(): boolean {
        try {
            return wifiManager.isConnected();
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取 WiFi 连接状态失败, ${JSON.stringify(err)}`);
            return false;
        }
    }

    private isMeteredHotspot(): boolean {
        try {
            return wifiManager.isMeteredHotspot();
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取热点状态失败, ${JSON.stringify(err)}`);
            return false;
        }
    }

    private readIpv4(): Ipv4Snapshot | null {
        try {
            const info = wifiManager.getIpInfo();

            const snapshot: Ipv4Snapshot = {
                address: ipStringFromNumber(info.ipAddress),
                gateway: ipStringFromNumber(info.gateway),
                netmask: ipStringFromNumber(info.netmask),
                primaryDns: ipStringFromNumber(info.primaryDns),
                secondaryDns: ipStringFromNumber(info.secondDns),
                dhcpServer: ipStringFromNumber(info.serverIp),
                leaseSeconds: info.leaseDuration
            };

            return snapshot;
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取 IPv4 信息失败, ${JSON.stringify(err)}`);
            return null;
        }
    }

    private readIpv6(): Ipv6Snapshot | null {
        try {
            const info = wifiManager.getIpv6Info();

            const snapshot: Ipv6Snapshot = {
                link: info.linkIpv6Address,
                global: info.globalIpv6Address,
                randomGlobal: info.randomGlobalIpv6Address,
                unique: info.uniqueIpv6Address ?? '-',
                randomUnique: info.randomUniqueIpv6Address ?? '-',
                gateway: info.gateway,
                netmask: info.netmask,
                primaryDns: info.primaryDNS,
                secondaryDns: info.secondDNS
            };

            return snapshot;
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取 IPv6 信息失败, ${JSON.stringify(err)}`);
            return null;
        }
    }

    private readDefaultNet(): DefaultNetSnapshot | null {
        try {
            const defaultNet = connection.getDefaultNetSync();
            if (defaultNet.netId === 0) return null;

            const capabilities = connection.getNetCapabilitiesSync(defaultNet);
            const caps: NetworkCapabilityKey[] = [];
            for (const cap of capabilities.networkCap ?? []) {
                caps.push(this.toCapabilityKey(cap));
            }

            const bearers: NetworkBearerKey[] = [];
            for (const bearer of capabilities.bearerTypes) {
                bearers.push(this.toBearerKey(bearer));
            }

            const snapshot: DefaultNetSnapshot = {
                netId: defaultNet.netId ?? 0,
                upKbps: capabilities.linkUpBandwidthKbps ?? 0,
                downKbps: capabilities.linkDownBandwidthKbps ?? 0,
                capabilities: caps,
                bearers: bearers
            };

            return snapshot;
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取默认网络信息失败, ${JSON.stringify(err)}`);
            return null;
        }
    }

    private toCapabilityKey(cap: connection.NetCap): NetworkCapabilityKey {
        if (cap === connection.NetCap.NET_CAPABILITY_MMS) return 'mms';
        if (cap === connection.NetCap.NET_CAPABILITY_NOT_METERED) return 'not-metered';
        if (cap === connection.NetCap.NET_CAPABILITY_INTERNET) return 'internet';
        if (cap === connection.NetCap.NET_CAPABILITY_NOT_VPN) return 'not-vpn';
        if (cap === connection.NetCap.NET_CAPABILITY_VALIDATED) return 'validated';
        if (cap === connection.NetCap.NET_CAPABILITY_PORTAL) return 'portal';
        if (cap === connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY) return 'checking-connectivity';
        return 'unknown';
    }

    private toBearerKey(bearer: connection.NetBearType): NetworkBearerKey {
        if (bearer === connection.NetBearType.BEARER_CELLULAR) return 'cellular';
        if (bearer === connection.NetBearType.BEARER_WIFI) return 'wifi';
        if (bearer === connection.NetBearType.BEARER_BLUETOOTH) return 'bluetooth';
        if (bearer === connection.NetBearType.BEARER_ETHERNET) return 'ethernet';
        if (bearer === connection.NetBearType.BEARER_VPN) return 'vpn';
        return 'unknown';
    }
}