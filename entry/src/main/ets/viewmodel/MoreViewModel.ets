import { common } from '@kit.AbilityKit';
import bundleManager from '@ohos.bundle.bundleManager';

import { Logger } from '../common/log/Logger';
import { ImportSummary, BackupService, ExportOutcome } from '../domain/BackupService';
import { DeviceService } from '../domain/DeviceService';
import { AffectedForms } from '../common/model/CardBindingData';
import { CardBindingService } from '../domain/CardBindingService';
import { Result } from '../common/util/Result';

/** 哪一种忙：遮罩文案与返回拦截都按它分支；'exporting' 既无遮罩也无文案 */
export type BusyKind = 'idle' | 'exporting' | 'importing' | 'clearing';

/** 更多页的视图模型：导出、选文件、导入、清除全部、版本号 */
@ObservedV2
export class MoreViewModel {
    private LOG_TAG = '[MoreViewModel]';

    @Trace busy: BusyKind = 'idle';
    @Trace versionName: string = '';
    @Trace versionCode: string = '';
    @Trace lastImport: string = '';
    @Trace cardRefreshError: string = '';

    private backupService: BackupService;
    private deviceService: DeviceService;
    private cards: CardBindingService;

    constructor(backupService: BackupService, deviceService: DeviceService, cards: CardBindingService) {
        this.backupService = backupService;
        this.deviceService = deviceService;
        this.cards = cards;
    }

    loadVersion(): void {
        try {
            const bundleInfo = bundleManager.getBundleInfoForSelfSync(
                bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
            this.versionName = bundleInfo.versionName;
            this.versionCode = bundleInfo.versionCode.toString();
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取版本号失败: ${err}`);
        }
    }

    async exportDevices(): Promise<ExportOutcome> {
        this.busy = 'exporting';
        try {
            return await this.backupService.exportDevices();
        } finally {
            this.busy = 'idle';
        }
    }

    /** 只让用户选文件，不置忙：选文件期间无遮罩、可返回 */
    async pickBackupFile(): Promise<string | null> {
        return this.backupService.pickBackupFile();
    }

    /** 入库阶段：置 `importing`，遮罩与返回拦截都落在这一段 */
    async importFromFile(uri: string): Promise<Result<ImportSummary>> {
        this.busy = 'importing';
        try {
            const result = await this.backupService.importFromFile(uri);
            if (result.ok && result.value !== null) {
                this.lastImport = `restored:${result.value.restored}, failed:${result.value.failed}`;
            }
            return result;
        } finally {
            this.busy = 'idle';
        }
    }

    async clearAll(): Promise<boolean> {
        this.busy = 'clearing';
        try {
            const mutation = await this.deviceService.clear();
            if (!mutation.ok) {
                Logger.error(this.LOG_TAG, `清除全部失败: ${mutation.reason}`);
                return false;
            }

            const affected = mutation.affected ?? AffectedForms.empty();
            if (!affected.isEmpty()) {
                const report = await this.cards.publish(affected);
                if (report.failed.length > 0) this.cardRefreshError = report.failed.join(',');
            }

            return true;
        } finally {
            this.busy = 'idle';
        }
    }

    consumeCardRefreshError(): string {
        const message = this.cardRefreshError;
        this.cardRefreshError = '';
        return message;
    }
}