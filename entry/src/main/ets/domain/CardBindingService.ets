import { CardBindingStore } from '../data/CardBindingStore';
import { CardPublisher, PublishReport } from '../data/CardPublisher';

import { Logger } from '../common/log/Logger';
import {
    AffectedForms,
    MultipleCardBindingData,
    SingleCardBindingData,
    WidgetDevice
} from '../common/model/CardBindingData';
import { Device } from '../common/model/Device';

export interface BindOutcome {
    ok: boolean;
    published: PublishReport | null;
    reason?: string;
}

/**
 * 卡片绑定用例。写持久化与刷卡片 UI 是两步：
 * 写成功而发布失败时 ok 为真、published.failed 非空，调用方据此提示，不把"写进去了"报成失败。
 */
export class CardBindingService {
    private LOG_TAG = '[CardBindingService]';

    private static shared: CardBindingService | null = null;

    private store: CardBindingStore;
    private publisher: CardPublisher;

    constructor(store: CardBindingStore, publisher: CardPublisher) {
        this.store = store;
        this.publisher = publisher;
    }

    static instance(): CardBindingService {
        if (!CardBindingService.shared) {
            CardBindingService.shared = new CardBindingService(
                CardBindingStore.getInstance(),
                CardPublisher.getInstance()
            );
        }
        return CardBindingService.shared;
    }

    async bindSingle(formID: string, device: Device): Promise<BindOutcome> {
        const data = new SingleCardBindingData(formID, true);
        data.deviceID = device.ID;
        data.alias = device.Alias;
        data.mac = device.MAC;
        data.address = device.Address;
        data.port = device.Port;

        const raw = JSON.stringify(data);
        const written = await this.store.put(formID, raw);
        if (!written) return { ok: false, published: null, reason: '写入卡片绑定失败' };

        const published = await this.publisher.publishSingle(formID, raw);
        return { ok: true, published: published };
    }

    async bindMultiple(formID: string, devices: Device[]): Promise<BindOutcome> {
        // 设备列表为空时解绑整张卡片（沿用既有行为）
        if (devices.length === 0) return this.unbind(formID);

        const data = new MultipleCardBindingData(formID, true);
        data.deviceList = devices.map((device: Device) => new WidgetDevice(
            device.ID, device.Alias, device.MAC, device.Address, device.Port));

        const raw = JSON.stringify(data);
        const written = await this.store.put(formID, raw);
        if (!written) return { ok: false, published: null, reason: '写入卡片绑定失败' };

        const published = await this.publisher.publishMultiple(formID, raw);
        return { ok: true, published: published };
    }

    async unbind(formID: string): Promise<BindOutcome> {
        const removed = await this.store.remove(formID);
        if (!removed) return { ok: false, published: null, reason: '删除卡片绑定失败' };

        const published = await this.publisher.emptySingle(formID);
        return { ok: true, published: published };
    }

    /** 只改持久化数据，不刷卡片 UI */
    async syncDeviceChange(device: Device): Promise<AffectedForms> {
        const affected = AffectedForms.empty();
        const all = await this.store.getAllRaw();

        for (const formID of all.keys()) {
            const raw = all.get(formID);
            if (raw === undefined) continue;

            if (this.isMultipleRaw(raw)) {
                const data = JSON.parse(raw) as MultipleCardBindingData;
                let changed = false;

                for (const item of data.deviceList) {
                    if (item.id === device.ID) {
                        item.alias = device.Alias;
                        item.mac = device.MAC;
                        item.address = device.Address;
                        item.port = device.Port;
                        changed = true;
                        break;
                    }
                }

                if (changed) {
                    affected.multiple.push(formID);
                    await this.store.put(formID, JSON.stringify(data));
                }
            } else {
                const data = JSON.parse(raw) as SingleCardBindingData;
                if (data.deviceID === device.ID) {
                    data.alias = device.Alias;
                    data.mac = device.MAC;
                    data.address = device.Address;
                    data.port = device.Port;
                    affected.single.push(formID);
                    await this.store.put(formID, JSON.stringify(data));
                }
            }
        }

        return affected;
    }

    /** 只改持久化数据，不刷卡片 UI */
    async dropDeviceBindings(deviceID: number): Promise<AffectedForms> {
        const affected = AffectedForms.empty();
        const all = await this.store.getAllRaw();

        for (const formID of all.keys()) {
            const raw = all.get(formID);
            if (raw === undefined) continue;

            if (this.isMultipleRaw(raw)) {
                const data = JSON.parse(raw) as MultipleCardBindingData;
                const originalLength = data.deviceList.length;
                data.deviceList = data.deviceList.filter((item: WidgetDevice) => item.id !== deviceID);

                if (data.deviceList.length !== originalLength) {
                    affected.multiple.push(formID);
                    if (data.deviceList.length === 0) await this.store.remove(formID);
                    else await this.store.put(formID, JSON.stringify(data));
                }
            } else {
                const data = JSON.parse(raw) as SingleCardBindingData;
                if (data.deviceID === deviceID) {
                    affected.single.push(formID);
                    await this.store.remove(formID);
                }
            }
        }

        return affected;
    }

    async clearAllBindings(): Promise<AffectedForms> {
        const affected = AffectedForms.empty();
        const all = await this.store.getAllRaw();

        for (const formID of all.keys()) {
            const raw = all.get(formID);
            if (raw === undefined) continue;
            if (this.isMultipleRaw(raw)) affected.multiple.push(formID);
            else affected.single.push(formID);
        }

        await this.store.clear();
        return affected;
    }

    /** 只刷 UI：按受影响卡片集合逐张发布，某一张失败不影响其余卡片 */
    async publish(affected: AffectedForms): Promise<PublishReport> {
        const report: PublishReport = { updated: [], failed: [] };

        for (const formID of affected.single) {
            const raw = await this.store.getRaw(formID);
            const single = await this.publisher.publishSingle(formID, raw);
            report.updated.push(...single.updated);
            report.failed.push(...single.failed);
        }

        for (const formID of affected.multiple) {
            const raw = await this.store.getRaw(formID);
            const multiple = await this.publisher.publishMultiple(formID, raw);
            report.updated.push(...multiple.updated);
            report.failed.push(...multiple.failed);
        }

        if (report.failed.length > 0) {
            Logger.warn(this.LOG_TAG, `刷新卡片失败 ${report.failed.length} 张: ${report.failed.join(',')}`);
        }
        return report;
    }

    /** deviceList 属性只存在于多设备卡片数据中；解析后判断，避免 MAC/别名里出现该词时误判 */
    private isMultipleRaw(raw: string): boolean {
        try {
            const parsed = JSON.parse(raw) as Record<string, Object>;
            return Array.isArray(parsed['deviceList']);
        } catch (err) {
            return false;
        }
    }
}