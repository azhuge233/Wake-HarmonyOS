import { NetworkInfoReader } from '../data/NetworkInfoReader';

import { NetworkInfoPort, NetworkSnapshot } from '../common/ports/NetworkInfoPort';

/**
 * 网络信息只读。四类信息由领域一次取齐，页面只渲染；
 * 取不到的那一组为 null，页面按"该组无内容"呈现，不伪造占位值。
 */
export class NetworkInfoService {
    private static shared: NetworkInfoService | null = null;

    private port: NetworkInfoPort;

    constructor(port: NetworkInfoPort) {
        this.port = port;
    }

    static instance(): NetworkInfoService {
        if (!NetworkInfoService.shared) {
            NetworkInfoService.shared = new NetworkInfoService(new NetworkInfoReader());
        }
        return NetworkInfoService.shared;
    }

    async snapshot(): Promise<NetworkSnapshot> {
        return this.port.readSnapshot();
    }
}