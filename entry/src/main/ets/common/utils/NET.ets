import wifiManager from '@ohos.wifiManager';
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { buffer } from '@kit.ArkTS';

import Logger from "./Logger";

class NET {
    private LOG_TAG = '[NET]';

    private CURRENT_IP_NUM: number = -1;
    private CURRENT_NET_MASK_NUM: number = -1;
    private BROADCAST_IP_NUM: number = -1;

    UDP: socket.UDPSocket = socket.constructUDPSocketInstance();

    CURRENT_IP: string = '';
    CURRENT_NET_MASK: string = '';
    BROADCAST_IP: string = '';

    HAS_BROADCAST_IP: boolean = false;

    init(): void {
        this.refreshCurrentNetwork();
    }

    refreshCurrentNetwork(): void {
        if(wifiManager.isWifiActive()) {
            let ipInfo = wifiManager.getIpInfo();

            this.CURRENT_IP_NUM = ipInfo.ipAddress;
            this.CURRENT_NET_MASK_NUM = ipInfo.netmask;

            this.CURRENT_IP = this.getIpAddrFromNum(this.CURRENT_IP_NUM);
            this.CURRENT_NET_MASK = this.getIpAddrFromNum(this.CURRENT_NET_MASK_NUM);

            Logger.debug(this.LOG_TAG, `Get device network - IP: ${this.CURRENT_IP}, MASK: ${this.CURRENT_NET_MASK}`);

            this.calcBroadcastIP();

            Logger.debug(this.LOG_TAG, `Broadcast IP: ${this.BROADCAST_IP}`)

            this.HAS_BROADCAST_IP = true;

            this.UDP.getState().then((state: socket.SocketStateBase) => {
                Logger.debug(this.LOG_TAG, `UDP state: ${JSON.stringify(state)}}`);
                if(!state.isBound) {
                    Logger.debug(this.LOG_TAG, 'UDP not bound previously, start binding.')
                    this.udpInit();
                }

                this.UDP.getLocalAddress().then((netAddr: socket.NetAddress) => {
                    Logger.debug(this.LOG_TAG, `Current UDP net address: ${JSON.stringify(netAddr)}}`);
                    let udp_bind_addr: string = netAddr.address;

                    if(udp_bind_addr != this.CURRENT_IP) {
                        this.udpInit();
                        Logger.debug(this.LOG_TAG, 'Network change detected, UDP rebound!');
                    }
                }).catch((err: BusinessError) => {
                    Logger.error(this.LOG_TAG, `Get UDP local adress Error. Code: ${err.code}, message: ${err.message}`);
                })
            }).catch((err: BusinessError) => {
                Logger.error(this.LOG_TAG, `Get UDP state error. Code: ${err.code}, message: ${err.message}`);
            })
        } else {
            this.CURRENT_IP_NUM = -1;
            this.CURRENT_NET_MASK_NUM = -1;
            this.BROADCAST_IP_NUM = -1;
            this.CURRENT_IP = '󰚑';
            this.CURRENT_NET_MASK = '󰚑';
            this.BROADCAST_IP = '󰚑';
            this.HAS_BROADCAST_IP = false;

            this.UDP = socket.constructUDPSocketInstance();

            Logger.debug(this.LOG_TAG, "Wifi is disabled");
        }
    }

    buildMagicPacket(mac: string): socket.UDPSendOptions {
        let sendAddr: socket.NetAddress = {
            address: this.BROADCAST_IP,
            family: 1,
            port: 7
        }

        let macAddrFinal: string =  mac.replaceAll(mac.includes(':') ? ':' : '-', '');
        let dataStr = 'ff'.repeat(6) + macAddrFinal.repeat(16);

        Logger.debug(this.LOG_TAG, `Final MAC Address string: ${macAddrFinal}`);

        let buff = buffer.from(dataStr, 'hex').buffer;

        Logger.debug(this.LOG_TAG, `Data array content: ${new Uint8Array(buffer.from(dataStr, 'hex').buffer).toString()}`);

        const sendOptions: socket.UDPSendOptions = {
            data: buff,
            address: sendAddr
        }

        return sendOptions;
    }

    private udpInit() {
        let bindAddr: socket.NetAddress = {
            address: this.CURRENT_IP,
            family: 1
        }

        this.UDP.bind(bindAddr).then(() => {
            Logger.debug(this.LOG_TAG, 'UDP Bind OK!');
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Bind Error. Code: ${err.code}, message: ${err.message}`);
        })

        let udpExtraOptions: socket.UDPExtraOptions = {
            sendBufferSize: 102,
            reuseAddress: true,
            broadcast: true
        }

        this.UDP.setExtraOptions(udpExtraOptions).then(() => {
            Logger.debug(this.LOG_TAG, "Set extra options OK");
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Set extra options Error. Code: ${err.code}, message: ${err.message}`);
        })
    }

    private calcBroadcastIP(): void {
        // Calculate the broadcast address by OR-ing IP with the inverted subnet mask
        this.BROADCAST_IP_NUM = this.CURRENT_IP_NUM | ~this.CURRENT_NET_MASK_NUM;
        this.BROADCAST_IP = this.getIpAddrFromNum(this.BROADCAST_IP_NUM);
    }

    private getIpAddrFromNum(ipNum: number): string {
        return (ipNum >>> 24) + '.' + (ipNum >> 16 & 0xFF) + '.' + (ipNum >> 8 & 0xFF) + '.' + (ipNum & 0xFF);
    }
}

export default new NET() as NET;