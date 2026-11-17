import { Device, NewDeviceRecord } from '../common/model/Device';
import { DeviceDao, OrderIndexPair } from '../data/DeviceDao';

import { Logger } from '../common/log/Logger';
import { AffectedForms } from '../common/model/CardBindingData';
import { Result } from '../common/util/Result';
import { CardBindingService } from './CardBindingService';

export interface DeviceMutation {
    ok: boolean;
    affected?: AffectedForms;
    reason?: string;
}

/**
 * 设备用例。变更用例返回"改了什么、影响了哪些卡片"，由调用方决定何时发布刷新——
 * 领域层不做 UI 刷新，"改数据"与"刷卡片"是两步。
 */
export class DeviceService {
    private LOG_TAG = '[DeviceService]';

    private static shared: DeviceService | null = null;

    private dao: DeviceDao;
    private cards: CardBindingService;

    constructor(dao: DeviceDao, cards: CardBindingService) {
        this.dao = dao;
        this.cards = cards;
    }

    static instance(): DeviceService {
        if (!DeviceService.shared) {
            DeviceService.shared = new DeviceService(DeviceDao.getInstance(), CardBindingService.instance());
        }
        return DeviceService.shared;
    }

    /** 失败与空列表是两件事：失败带 error，空列表是 ok + 空数组 */
    async load(): Promise<Result<Device[]>> {
        try {
            const devices = await this.dao.getAll();
            return Result.success(devices);
        } catch (err) {
            Logger.error(this.LOG_TAG, `加载设备失败, ${err}`);
            return Result.failure<Device[]>(`加载设备失败: ${err}`);
        }
    }

    /** OrderIndex = 当前最大值 + 1（空表取 0） */
    async add(draft: NewDeviceRecord): Promise<DeviceMutation> {
        try {
            const existing = await this.dao.getAll();
            let nextOrderIndex = 0;
            if (existing.length > 0) {
                const maxOrderIndex = Math.max(...existing.map((entry: Device) => entry.OrderIndex));
                nextOrderIndex = maxOrderIndex + 1;
            }

            const record: NewDeviceRecord = {
                mac: draft.mac,
                alias: draft.alias,
                address: draft.address,
                port: draft.port,
                orderIndex: nextOrderIndex
            };

            const id = await this.dao.insert(record);
            Logger.debug(this.LOG_TAG, `新设备已添加, ID: ${id}`);

            const affected = AffectedForms.empty();
            return { ok: true, affected: affected };
        } catch (err) {
            Logger.error(this.LOG_TAG, `添加设备失败, ${err}`);
            return { ok: false, reason: `添加设备失败: ${err}` };
        }
    }

    /** 同步绑定数据，不刷新卡片 */
    async update(device: Device): Promise<DeviceMutation> {
        try {
            const changed = await this.dao.update(device);
            if (!changed) return { ok: false, reason: '没有找到要更新的设备' };

            const affected = await this.cards.syncDeviceChange(device);
            return { ok: true, affected: affected };
        } catch (err) {
            Logger.error(this.LOG_TAG, `更新设备失败, ${err}`);
            return { ok: false, reason: `更新设备失败: ${err}` };
        }
    }

    /** 连带删除该设备的绑定，不刷新卡片 */
    async remove(device: Device): Promise<DeviceMutation> {
        try {
            const deleted = await this.dao.delete(device.ID);
            if (!deleted) return { ok: false, reason: '没有找到要删除的设备' };

            const affected = await this.cards.dropDeviceBindings(device.ID);
            return { ok: true, affected: affected };
        } catch (err) {
            Logger.error(this.LOG_TAG, `删除设备失败, ${err}`);
            return { ok: false, reason: `删除设备失败: ${err}` };
        }
    }

    /** 清空设备并清空全部绑定 */
    async clear(): Promise<DeviceMutation> {
        try {
            await this.dao.clear();
            const affected = await this.cards.clearAllBindings();
            return { ok: true, affected: affected };
        } catch (err) {
            Logger.error(this.LOG_TAG, `清空设备失败, ${err}`);
            return { ok: false, reason: `清空设备失败: ${err}` };
        }
    }

    /** 重排后整体回写 ORDERINDEX */
    async reorder(from: number, to: number): Promise<DeviceMutation> {
        try {
            const loaded = await this.dao.getAll();
            const devices = loaded.slice();

            if (from === to || from < 0 || to < 0 || from >= devices.length || to >= devices.length) {
                return { ok: false, reason: '重排下标无效' };
            }

            const moved = devices.splice(from, 1);
            devices.splice(to, 0, moved[0]);

            const pairs: OrderIndexPair[] = devices.map((entry: Device, index: number) => {
                const pair: OrderIndexPair = { id: entry.ID, orderIndex: index };
                return pair;
            });

            const written = await this.dao.updateOrderIndices(pairs);
            if (!written) return { ok: false, reason: '排序回写失败' };

            return { ok: true, affected: AffectedForms.empty() };
        } catch (err) {
            Logger.error(this.LOG_TAG, `重排设备失败, ${err}`);
            return { ok: false, reason: `重排设备失败: ${err}` };
        }
    }
}