import { BackupFileGateway } from '../data/BackupFileGateway';
import { NewDeviceRecord } from '../common/model/Device';

import { Logger } from '../common/log/Logger';
import { AffectedForms } from '../common/model/CardBindingData';
import { Device } from '../common/model/Device';
import { DeviceJsonObject } from '../common/model/DeviceJsonObject';
import { BackupFilePort } from '../common/ports/BackupFilePort';
import { PortInput } from '../common/util/PortInput';
import { Result } from '../common/util/Result';
import { CardBindingService } from './CardBindingService';
import { DeviceService } from './DeviceService';

export interface ImportSummary {
    cleared: boolean;
    restored: number;
    failed: number;
    /** 入库成功后刷新失败的用户卡片数：导入本身成功，卡片刷新是另一次失败 */
    cardsFailed: number;
    affected: AffectedForms;
}

export type ExportFailReason = 'none' | 'cancelled' | 'write-failed';

/**
 * 导出结果。用类而不是对象字面量联合类型：ArkTS 不接受对象字面量做类型声明。
 * reason 只在失败时有意义，成功时为 'none'。
 */
export class ExportOutcome {
    readonly ok: boolean;
    readonly uri: string;
    readonly reason: ExportFailReason;

    constructor(ok: boolean, uri: string, reason: ExportFailReason) {
        this.ok = ok;
        this.uri = uri;
        this.reason = reason;
    }

    static success(uri: string): ExportOutcome {
        return new ExportOutcome(true, uri, 'none');
    }

    static failure(reason: ExportFailReason): ExportOutcome {
        return new ExportOutcome(false, '', reason);
    }
}

/**
 * 导入导出用例。文件访问走 common/ports/BackupFilePort，顺序与判定在这里：
 * 导出字段与旧版逐字段一致；导入是"清空后逐条重建"。
 * 选文件与入库分成两步（pickBackupFile + importFromFile）：合成一步时，选文件期间页面
 * 要么静默锁死、要么在系统选择器前盖一层灰；分开后遮罩与返回拦截只落在入库这一段。
 * 设备表为空时照常写出一份空数组文件——空列表是一次成功的导出，不是失败。
 */
export class BackupService {
    private LOG_TAG = '[BackupService]';

    private static shared: BackupService | null = null;

    private gateway: BackupFilePort;
    private devices: DeviceService;
    private cards: CardBindingService;

    constructor(gateway: BackupFilePort, devices: DeviceService, cards: CardBindingService) {
        this.gateway = gateway;
        this.devices = devices;
        this.cards = cards;
    }

    static instance(): BackupService {
        if (!BackupService.shared) {
            BackupService.shared = new BackupService(
                BackupFileGateway.getInstance(),
                DeviceService.instance(),
                CardBindingService.instance()
            );
        }
        return BackupService.shared;
    }

    async exportDevices(): Promise<ExportOutcome> {
        const loaded = await this.devices.load();
        if (!loaded.ok) return ExportOutcome.failure('write-failed');

        const devices: Device[] = loaded.value ?? [];
        const rows: DeviceJsonObject[] = devices.map((device: Device) => new DeviceJsonObject(
            device.MAC, device.Alias, device.Address, device.Port, device.OrderIndex));

        const json = JSON.stringify(rows, null, 4);

        try {
            const uri = await this.gateway.saveJson(`${new Date().getTime()}`, json);
            if (uri === null) return ExportOutcome.failure('cancelled');
            return ExportOutcome.success(uri);
        } catch (err) {
            Logger.error(this.LOG_TAG, `导出失败, ${err}`);
            return ExportOutcome.failure('write-failed');
        }
    }

    /** 只让用户选文件：取消返回 null；选择器自身失败向上抛，由页面报导入失败 */
    async pickBackupFile(): Promise<string | null> {
        return this.gateway.pickJson();
    }

    /** 读文件、清空、逐条重建、发布卡片 */
    async importFromFile(uri: string): Promise<Result<ImportSummary>> {
        const text = await this.gateway.readText(uri);
        if (text === null) return Result.failure<ImportSummary>('读取备份文件失败');

        let rows: DeviceJsonObject[] = [];
        try {
            const parsed = JSON.parse(text) as DeviceJsonObject[];
            if (!Array.isArray(parsed)) return Result.failure<ImportSummary>('备份文件不是设备数组');
            rows = parsed;
        } catch (err) {
            return Result.failure<ImportSummary>(`解析备份文件失败: ${err}`);
        }

        const cleared = await this.devices.clear();
        if (!cleared.ok) return Result.failure<ImportSummary>(cleared.reason ?? '清空设备失败');

        const affected = cleared.affected ?? AffectedForms.empty();
        let restored = 0;
        let failed = 0;

        for (const row of rows) {
            const draft: NewDeviceRecord = {
                mac: row.MAC,
                alias: row.Alias,
                address: row.Address ?? '',
                // 2.8.0 导出的备份里，端口留空的记录存的是 0；与读侧共用 PortInput 的存量归一口径，
                // 不让非法端口重新入库
                port: PortInput.normalizeStored(row.Port),
                orderIndex: 0
            };

            const added = await this.devices.add(draft);
            if (added.ok) restored++;
            else failed++;
        }

        // 卡片发布失败是导入之后另一次失败：数出来交给调用方，不静默丢弃
        const report = await this.cards.publish(affected);
        const cardsFailed = report.failed.length;
        if (cardsFailed > 0) {
            Logger.warn(this.LOG_TAG, `导入后刷新卡片失败 ${cardsFailed} 张: ${report.failed.join(',')}`);
        }

        const summary: ImportSummary = {
            cleared: true,
            restored: restored,
            failed: failed,
            cardsFailed: cardsFailed,
            affected: affected
        };
        Logger.debug(this.LOG_TAG,
            `导入完成: 恢复 ${restored} 条, 失败 ${failed} 条, 卡片刷新失败 ${cardsFailed} 张`);
        return Result.success(summary);
    }
}