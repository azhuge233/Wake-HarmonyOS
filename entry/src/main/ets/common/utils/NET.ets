import wifiManager from '@ohos.wifiManager';
import { socket } from '@kit.NetworkKit';
import { buffer } from '@kit.ArkTS';

import Logger from "./Logger";

export default class NET {
    private LOG_TAG = '[NET]';

    CURRENT_IP: string = '';
    CURRENT_NET_MASK: string = '';
    BROADCAST_IP: string = '';

    HAS_BROADCAST_IP: boolean = false;

    private NoNetworkString = '󰚑';

    private UDP: socket.UDPSocket = socket.constructUDPSocketInstance();

    async refresh(): Promise<void> {
        try {
            if (wifiManager.isWifiActive()) {
                const ipInfo = wifiManager.getIpInfo();

                const deviceIPNumber = ipInfo.ipAddress;
                const deviceNetmaskNumber = ipInfo.netmask;

                this.CURRENT_IP = this.getIpStringFromNum(deviceIPNumber);
                this.CURRENT_NET_MASK = this.getIpStringFromNum(deviceNetmaskNumber);
                this.BROADCAST_IP = this.calcBroadcastIP(deviceIPNumber, deviceNetmaskNumber);
                this.HAS_BROADCAST_IP = true;

                Logger.debug(this.LOG_TAG, `设备网络信息`);
                Logger.debug(this.LOG_TAG, `设备 IP 地址: ${this.CURRENT_IP}, 掩码: ${this.CURRENT_NET_MASK}`);
                Logger.debug(this.LOG_TAG, `广播地址: ${this.BROADCAST_IP}`);

                const state = await this.UDP.getState();
                Logger.debug(this.LOG_TAG, `UDP 状态: ${JSON.stringify(state)}`);

                if (!state.isBound) {
                    Logger.warn(this.LOG_TAG, 'UDP 端口未绑定，开始绑定');
                    this.udpInit();
                }

                const netAddr = await this.UDP.getLocalAddress();

                if (netAddr.address != this.CURRENT_IP) {
                    Logger.warn(this.LOG_TAG, '检测到网络更改，重新绑定 UDP');
                    this.udpInit();
                }
            } else {
                this.CURRENT_IP = this.NoNetworkString;
                this.CURRENT_NET_MASK = this.NoNetworkString;
                this.BROADCAST_IP = this.NoNetworkString;
                this.HAS_BROADCAST_IP = false;

                this.UDP = socket.constructUDPSocketInstance();

                Logger.debug(this.LOG_TAG, "设备网络已关闭");
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `refreshCurrentNetwork() 错误, ${err}`);
        }
    }

    async send(mac: string): Promise<boolean | string | Resource> {
        try {
            if(this.HAS_BROADCAST_IP) {
                const packet = this.buildMagicPacket(mac);

                await this.UDP.send(packet);

                return true;
            } else {
                Logger.debug(this.LOG_TAG, "无广播地址，终止发送");
                return $r("app.string.no_broadcast_ip");
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `魔法包发送失败, ${err}`);
            return `${err}`;
        }
    }

    private async udpInit() {
        const bindAddr: socket.NetAddress = {
            address: this.CURRENT_IP,
            family: 1
        };

        try {
            await this.UDP.bind(bindAddr);
            Logger.debug(this.LOG_TAG, 'UDP 端口绑定成功!');
        } catch (err) {
            Logger.error(this.LOG_TAG, `UDP 端口绑定失败, ${err}`);
        }

        const udpExtraOptions: socket.UDPExtraOptions = {
            sendBufferSize: 102,
            reuseAddress: true,
            broadcast: true
        };

        try {
            await this.UDP.setExtraOptions(udpExtraOptions);
            Logger.debug(this.LOG_TAG, `UDP 设置额外参数成功`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `UDP 设置额外参数失败, ${err}`);
        }
    }

    private calcBroadcastIP(ip: number, netmask: number): string {
        // Calculate the broadcast address by OR-ing IP with the inverted subnet mask
        const broadcastIPNumber = ip | ~netmask;
        return this.getIpStringFromNum(broadcastIPNumber);
    }

    private buildMagicPacket(mac: string): socket.UDPSendOptions {
        let sendAddr: socket.NetAddress = {
            address: this.BROADCAST_IP,
            family: 1,
            port: 7
        }

        let macAddrFinal: string =  mac.replaceAll(mac.includes(':') ? ':' : '-', '');
        let dataStr = 'ff'.repeat(6) + macAddrFinal.repeat(16);

        Logger.debug(this.LOG_TAG, `最终 MAC 字符串: ${macAddrFinal}`);

        let buff = buffer.from(dataStr, 'hex').buffer;

        Logger.debug(this.LOG_TAG, `数据: ${new Uint8Array(buffer.from(dataStr, 'hex').buffer).toString()}`);

        const sendOptions: socket.UDPSendOptions = {
            data: buff,
            address: sendAddr
        }

        return sendOptions;
    }

    private getIpStringFromNum(ipNum: number): string {
        return (ipNum >>> 24) + '.' + (ipNum >> 16 & 0xFF) + '.' + (ipNum >> 8 & 0xFF) + '.' + (ipNum & 0xFF);
    }
}