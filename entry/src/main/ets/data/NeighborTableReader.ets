import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { isStringNullOrEmpty } from '../common/util/Strings';

export interface NeighborEntry {
    ip: string;
    mac: string;
    iface: string;
}

export interface NeighborReadResult {
    entries: NeighborEntry[];
    permissionDenied: boolean;
}

/** 邻居表（ARP/IP-MAC 表）读取。权限被拒是一次可判定的结果，不是空表 */
export class NeighborTableReader {
    constructor() {
    }

    async read(): Promise<NeighborReadResult> {
        try {
            const table: connection.NetIpMacInfo[] = await connection.getIpNeighTable();
            const entries: NeighborEntry[] = [];

            for (const item of table) {
                if (isStringNullOrEmpty(item.macAddress)) continue;

                const entry: NeighborEntry = {
                    ip: item.ipAddress.address,
                    mac: item.macAddress,
                    iface: item.iface
                };
                entries.push(entry);
            }

            return { entries: entries, permissionDenied: false };
        } catch (err) {
            const businessErr = err as BusinessError;
            return { entries: [], permissionDenied: businessErr.code === 201 };
        }
    }
}