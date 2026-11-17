import { NeighborTableReader } from '../data/NeighborTableReader';

export interface NeighborCandidate {
    ip: string;
    mac: string;
    iface: string;
}

export interface NeighborQuery {
    available: boolean;
    permissionDenied: boolean;
    items: NeighborCandidate[];
}

/**
 * 邻居设备发现。权限被拒（错误码 201）是业务结果而非空表：
 * permissionDenied 为真，页面据此给权限提示，而不是显示"暂无设备"。
 */
export class NeighborService {
    private static shared: NeighborService | null = null;

    private reader: NeighborTableReader;

    constructor(reader: NeighborTableReader) {
        this.reader = reader;
    }

    static instance(): NeighborService {
        if (!NeighborService.shared) {
            NeighborService.shared = new NeighborService(new NeighborTableReader());
        }
        return NeighborService.shared;
    }

    async query(): Promise<NeighborQuery> {
        const result = await this.reader.read();

        const items: NeighborCandidate[] = result.entries.map((entry) => {
            const candidate: NeighborCandidate = {
                ip: entry.ip,
                mac: entry.mac,
                iface: entry.iface
            };
            return candidate;
        });

        return {
            available: !result.permissionDenied,
            permissionDenied: result.permissionDenied,
            items: items
        };
    }
}