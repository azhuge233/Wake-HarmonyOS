import wifiManager from '@ohos.wifiManager';
import { socket, connection } from '@kit.NetworkKit';
import { buffer } from '@kit.ArkTS';

import Logger from "./Logger";
import CommonUtils from './CommonUtils';

export default class NET {
    private LOG_TAG = '[NET]';


    ipv4Broadcast: string = '';
    hasBroadcastIP: boolean = false;

    private ipv4: string = '';
    private ipv4NetMask: string = '';

    private UDPv4: socket.UDPSocket = socket.constructUDPSocketInstance();
    private UDPv6: socket.UDPSocket = socket.constructUDPSocketInstance();

    private NoNetworkString = '󰚑';

    async refresh(): Promise<void> {
        try {
            if (wifiManager.isWifiActive() && wifiManager.isConnected()) {
                const ipInfo = wifiManager.getIpInfo();

                const deviceIPNumber = ipInfo.ipAddress;
                const deviceNetmaskNumber = ipInfo.netmask;

                // IPv4 广播地址计算
                this.ipv4 = this.getIpStringFromNum(deviceIPNumber);
                this.ipv4NetMask = this.getIpStringFromNum(deviceNetmaskNumber);
                this.ipv4Broadcast = this.calcBroadcastIP(deviceIPNumber, deviceNetmaskNumber);
                this.hasBroadcastIP = true;

                Logger.debug(this.LOG_TAG, `设备 IPv4 地址: ${this.ipv4}, IPv4 掩码: ${this.ipv4NetMask}`);
                Logger.debug(this.LOG_TAG, `广播地址: ${this.ipv4Broadcast}`);

                this.udpBind();
            } else {
                this.ipv4 = '';
                this.ipv4NetMask = '';
                this.ipv4Broadcast = this.NoNetworkString;
                this.hasBroadcastIP = false;

                await this.udpReset();

                Logger.debug(this.LOG_TAG, "设备网络已关闭");
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `refresh() 错误, ${err}`);
        }
    }

    async send(mac: string, targetAddress: string, targetPort: number): Promise<boolean | string | Resource> {
        try {
            let finalAddress: string = '';
            let finalPort: number = 9;
            let family = 1;

            if(CommonUtils.isStringNullOrEmpty(targetAddress)) {
                if (!this.hasBroadcastIP) return $r("app.string.no_broadcast_ip");
                finalAddress = this.ipv4Broadcast;
                finalPort = 7;
            } else {
                finalPort = targetPort;

                try {
                    // 解析域名
                    let netHandle = connection.getDefaultNetSync();
                    const netAddrList = await netHandle.getAddressesByName(targetAddress);

                    finalAddress = netAddrList[0].address; // 解析到的 IP
                    family = netAddrList[0].family as number; // IPv4 or IPv6
                } catch (err) {
                    finalAddress = targetAddress;
                    family = targetAddress.includes(':') ? 2 : 1;
                }
            }

            const packetData = this.buildMagicPacketPayload(mac);

            const sendOptions: socket.UDPSendOptions = {
                data: packetData,
                address: {
                    address: finalAddress,
                    port: finalPort,
                    family: family
                }
            };

            await this.udpBind();

            const socketInstance = family === 2 ? this.UDPv6 : this.UDPv4;

            await socketInstance.send(sendOptions);
            Logger.debug(this.LOG_TAG, `已向 ${finalAddress}:${finalPort} 发送魔法包，协议: ${family}`);

            return true;
        } catch (err) {
            let businessErr = err as BusinessError;
            Logger.error(this.LOG_TAG, `发送失败: ${businessErr.code}, ${businessErr.message}`);
            return businessErr.message;
        }
    }

    private async udpBind() {
        try {
            const stateV4 = await this.UDPv4.getState();

            Logger.debug(this.LOG_TAG, `UDPv4 状态: ${JSON.stringify(stateV4)}`);

            if (!stateV4.isBound) {
                const bindV4: socket.NetAddress = {
                    address: "0.0.0.0",
                    family: 1
                };

                try {
                    await this.UDPv4.bind(bindV4);
                    Logger.debug(this.LOG_TAG, '成功绑定 UDPv4 端口!');

                    await this.UDPv4.setExtraOptions({ broadcast: true });
                    Logger.debug(this.LOG_TAG, `成功设置 UDPv4 广播参数`);
                } catch (err) {
                    Logger.error(this.LOG_TAG, `UDPv4 端口绑定失败, ${JSON.stringify(err)}`);
                }
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `无法获取 UDPv4 状态`);
        }

        try {
            const stateV6 = await this.UDPv6.getState();

            Logger.debug(this.LOG_TAG, `UDPv6 状态: ${JSON.stringify(stateV6)}`);

            if (!stateV6.isBound) {
                const bindV6: socket.NetAddress = {
                    address: "::",
                    family: 2
                };

                try {
                    await this.UDPv6.bind(bindV6)
                    Logger.debug(this.LOG_TAG, '成功绑定 UDPv6 端口');
                } catch (err) {
                    Logger.error(this.LOG_TAG, `UDPv6 端口绑定失败, ${JSON.stringify(err)}`);
                }
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `无法获取 UDPv6 状态`);
        }
    }

    private async udpReset() {
        try {
            await this.UDPv4.close();
            await this.UDPv6.close();

            this.UDPv4 = socket.constructUDPSocketInstance();
            this.UDPv6 = socket.constructUDPSocketInstance();
            Logger.debug(this.LOG_TAG, `已重置 UDP`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `UDP 重置失败, ${err}`);
        }
    }

    private calcBroadcastIP(ip: number, netmask: number): string {
        // Calculate the broadcast address by OR-ing IP with the inverted subnet mask
        const broadcastIPNumber = ip | ~netmask;
        return this.getIpStringFromNum(broadcastIPNumber);
    }

    private buildMagicPacketPayload(mac: string): ArrayBuffer {
        let macAddrFinal: string = mac.replaceAll(mac.includes(':') ? ':' : '-', '');
        let dataStr = 'ff'.repeat(6) + macAddrFinal.repeat(16);
        return buffer.from(dataStr, 'hex').buffer;
    }

    private getIpStringFromNum(ipNum: number): string {
        return (ipNum >>> 24) + '.' + (ipNum >> 16 & 0xFF) + '.' + (ipNum >> 8 & 0xFF) + '.' + (ipNum & 0xFF);
    }
}