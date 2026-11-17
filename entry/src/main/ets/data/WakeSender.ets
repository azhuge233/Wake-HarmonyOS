import { socket, connection } from '@kit.NetworkKit';
import { wifiManager } from '@kit.ConnectivityKit';
import { buffer } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

import { Logger } from '../common/log/Logger';
import { broadcastAddressFrom, ipStringFromNumber } from '../common/util/IpAddress';
import { ResolvedAddress } from './AddressResolver';

export interface BroadcastState {
    address: string;
    available: boolean;
}

/** 无网络时广播地址位置显示的占位符（沿用改造前的可见行为） */
const NO_NETWORK_PLACEHOLDER = '󰚑';

/**
 * 魔法包发送与网络监听。监听是平台能力，从页面收进这里：
 * watch 覆盖 netAvailable / netCapabilitiesChange / netLost 三个事件，unwatch 与之对称。
 */
export class WakeSender {
    private LOG_TAG = '[WakeSender]';

    private static instance: WakeSender | null = null;

    private ipv4Broadcast: string = '';
    private hasBroadcast: boolean = false;

    private UDPv4: socket.UDPSocket | null = null;
    private UDPv6: socket.UDPSocket | null = null;

    private netConnection: connection.NetConnection | null = null;

    constructor() {
    }

    static getInstance(): WakeSender {
        if (!WakeSender.instance) WakeSender.instance = new WakeSender();
        return WakeSender.instance;
    }

    async refreshBroadcast(): Promise<BroadcastState> {
        try {
            if (wifiManager.isWifiActive() && wifiManager.isConnected()) {
                const ipInfo = wifiManager.getIpInfo();

                this.ipv4Broadcast = broadcastAddressFrom(ipInfo.ipAddress, ipInfo.netmask);
                this.hasBroadcast = true;

                Logger.debug(this.LOG_TAG,
                    `设备 IPv4 地址: ${ipStringFromNumber(ipInfo.ipAddress)}, 广播地址: ${this.ipv4Broadcast}`);

                await this.udpBind();
            } else {
                this.ipv4Broadcast = NO_NETWORK_PLACEHOLDER;
                this.hasBroadcast = false;

                await this.udpReset();
                Logger.debug(this.LOG_TAG, '设备网络已关闭');
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `refreshBroadcast() 错误, ${err}`);
            this.ipv4Broadcast = NO_NETWORK_PLACEHOLDER;
            this.hasBroadcast = false;
        }

        return { address: this.ipv4Broadcast, available: this.hasBroadcast };
    }

    /** 默认网络可用/能力变化/丢失时回调 */
    watch(onNetChange: () => void): void {
        if (this.netConnection) return;

        try {
            this.netConnection = connection.createNetConnection({
                netCapabilities: {
                    bearerTypes: [connection.NetBearType.BEARER_WIFI]
                }
            });
        } catch (err) {
            Logger.error(this.LOG_TAG, `创建网络监听失败: ${err}`);
            this.netConnection = null;
            return;
        }

        this.netConnection.on('netAvailable', (data: connection.NetHandle) => {
            Logger.info(this.LOG_TAG, `网络连接成功: ${JSON.stringify(data)}`);
            onNetChange();
        });

        this.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
            Logger.info(this.LOG_TAG, `网络能力变化: ${JSON.stringify(data)}`);
            onNetChange();
        });

        this.netConnection.on('netLost', (data: connection.NetHandle) => {
            Logger.info(this.LOG_TAG, `网络连接断开: ${JSON.stringify(data)}`);
            onNetChange();
        });

        this.netConnection.register((err: BusinessError) => {
            if (err) Logger.error(this.LOG_TAG, `注册网络监听失败, ${err}`);
        });
    }

    unwatch(): void {
        if (!this.netConnection) return;

        this.netConnection.unregister((err: BusinessError) => {
            if (err) Logger.error(this.LOG_TAG, `取消注册网络监听失败, ${err}`);
        });
        this.netConnection = null;
    }

    /**
     * target 为 null 表示走广播地址（目标端口固定 7）；否则按解析结果发送。
     * 返回 false 表示这一次没有发出去，失败类别由调用方判定。
     */
    async send(mac: string, target: ResolvedAddress | null, port: number): Promise<boolean> {
        let finalAddress: string = '';
        let finalPort: number = 9;
        let family: number = 1;

        if (target === null) {
            if (!this.hasBroadcast) return false;
            finalAddress = this.ipv4Broadcast;
            finalPort = 7;
            family = 1;
        } else {
            finalAddress = target.address;
            finalPort = port;
            family = target.family;
        }

        const sendOptions: socket.UDPSendOptions = {
            data: this.buildMagicPacketPayload(mac),
            address: {
                address: finalAddress,
                port: finalPort,
                family: family
            }
        };

        await this.udpBind();

        const socketInstance = family === 2 ? this.UDPv6 : this.UDPv4;
        if (!socketInstance) throw new Error('UDP socket 未初始化');

        await socketInstance.send(sendOptions);
        Logger.debug(this.LOG_TAG, `已向 ${finalAddress}:${finalPort} 发送魔法包，协议: ${family}`);
        return true;
    }

    async close(): Promise<void> {
        await this.udpReset();
    }

    private async udpBind(): Promise<void> {
        let udpV4 = this.UDPv4;
        if (!udpV4) {
            udpV4 = socket.constructUDPSocketInstance();
            this.UDPv4 = udpV4;
        }

        try {
            const stateV4 = await udpV4.getState();
            if (!stateV4.isBound) {
                const bindV4: socket.NetAddress = { address: '0.0.0.0', family: 1 };
                await udpV4.bind(bindV4);
                await udpV4.setExtraOptions({ broadcast: true });
                Logger.debug(this.LOG_TAG, '成功绑定 UDPv4 端口并开启广播');
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `UDPv4 绑定失败, ${JSON.stringify(err)}`);
        }

        let udpV6 = this.UDPv6;
        if (!udpV6) {
            udpV6 = socket.constructUDPSocketInstance();
            this.UDPv6 = udpV6;
        }

        try {
            const stateV6 = await udpV6.getState();
            if (!stateV6.isBound) {
                const bindV6: socket.NetAddress = { address: '::', family: 2 };
                await udpV6.bind(bindV6);
                Logger.debug(this.LOG_TAG, '成功绑定 UDPv6 端口');
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `UDPv6 绑定失败, ${JSON.stringify(err)}`);
        }
    }

    private async udpReset(): Promise<void> {
        const udpV4 = this.UDPv4;
        const udpV6 = this.UDPv6;
        this.UDPv4 = null;
        this.UDPv6 = null;

        if (udpV4) {
            try {
                await udpV4.close();
            } catch (err) {
                Logger.error(this.LOG_TAG, `UDPv4 关闭失败, ${err}`);
            }
        }

        if (udpV6) {
            try {
                await udpV6.close();
            } catch (err) {
                Logger.error(this.LOG_TAG, `UDPv6 关闭失败, ${err}`);
            }
        }

        Logger.debug(this.LOG_TAG, '已重置 UDP');
    }

    private buildMagicPacketPayload(mac: string): ArrayBuffer {
        const macAddrFinal: string = mac.replaceAll(mac.includes(':') ? ':' : '-', '');
        const dataStr = 'ff'.repeat(6) + macAddrFinal.repeat(16);
        return buffer.from(dataStr, 'hex').buffer;
    }
}