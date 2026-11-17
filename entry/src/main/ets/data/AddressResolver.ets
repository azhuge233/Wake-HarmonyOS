import { connection } from '@kit.NetworkKit';

/** 解析结果的家族号：1 = IPv4，2 = IPv6 */
export interface ResolvedAddress {
    address: string;
    family: 1 | 2;
}

/**
 * 域名/IP 解析。解析成功但结果为空时返回 null，由调用方判失败（不再把空结果当成本地地址发出去）。
 * 解析本身抛错时沿用既有行为：把目标当字面地址继续发送。
 */
export class AddressResolver {
    constructor() {
    }

    async resolve(target: string): Promise<ResolvedAddress | null> {
        try {
            const netHandle = connection.getDefaultNetSync();
            const netAddrList = await netHandle.getAddressesByName(target);

            if (!netAddrList || netAddrList.length === 0) return null;

            const family: 1 | 2 = netAddrList[0].family === 2 ? 2 : 1;
            return { address: netAddrList[0].address, family: family };
        } catch (err) {
            const fallbackFamily: 1 | 2 = target.includes(':') ? 2 : 1;
            return { address: target, family: fallbackFamily };
        }
    }
}