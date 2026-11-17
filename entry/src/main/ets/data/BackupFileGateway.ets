import { fileIo as fs, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

import { Logger } from '../common/log/Logger';
import { BackupFilePort } from '../common/ports/BackupFilePort';

/**
 * 文件系统的导入导出实现。UIAbilityContext 由 AbilitySetup 注入一次。
 * 文件名形状与后缀过滤与旧版一致。
 */
export class BackupFileGateway implements BackupFilePort {
    private LOG_TAG = '[BackupFileGateway]';

    private static instance: BackupFileGateway | null = null;

    private context: common.UIAbilityContext | null = null;

    constructor() {
    }

    static getInstance(): BackupFileGateway {
        if (!BackupFileGateway.instance) BackupFileGateway.instance = new BackupFileGateway();
        return BackupFileGateway.instance;
    }

    init(context: common.UIAbilityContext): void {
        this.context = context;
    }

    /** 让用户选保存位置并写出 JSON；用户取消返回 null */
    async saveJson(suffix: string, json: string): Promise<string | null> {
        const context = this.requireContext();
        if (!context) return null;

        const documentSaveOptions = new picker.DocumentSaveOptions();
        documentSaveOptions.newFileNames = [`Wake-backup-${suffix}.json`];
        documentSaveOptions.fileSuffixChoices = ['.json'];

        try {
            const documentViewPicker = new picker.DocumentViewPicker(context);
            const uris = await documentViewPicker.save(documentSaveOptions);

            if (uris.length === 0) {
                Logger.warn(this.LOG_TAG, '没有选取保存路径');
                return null;
            }

            const savePath: string = uris[0];
            const jsonFile = fs.openSync(savePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

            try {
                const writeLen = fs.writeSync(jsonFile.fd, json);
                Logger.debug(this.LOG_TAG, `备份已保存, 路径: ${jsonFile.path}, 写入长度: ${writeLen}`);
            } finally {
                fs.closeSync(jsonFile);
            }

            return savePath;
        } catch (err) {
            const businessErr = err as BusinessError;
            if (businessErr.code === 100006) {
                Logger.warn(this.LOG_TAG, '用户取消保存');
                return null;
            }
            Logger.error(this.LOG_TAG, `保存备份失败, ${businessErr.code}, ${businessErr.message}`);
            throw new Error('备份导出失败');
        }
    }

    /** 让用户选一个 JSON 文件；用户取消返回 null */
    async pickJson(): Promise<string | null> {
        const context = this.requireContext();
        if (!context) return null;

        const documentSelectOptions = new picker.DocumentSelectOptions();
        documentSelectOptions.maxSelectNumber = 1;
        documentSelectOptions.fileSuffixFilters = ['.json'];

        try {
            const documentViewPicker = new picker.DocumentViewPicker(context);
            const uris = await documentViewPicker.select(documentSelectOptions);

            if (uris.length === 0) {
                Logger.warn(this.LOG_TAG, '未选择备份文件');
                return null;
            }

            return uris[0];
        } catch (err) {
            const businessErr = err as BusinessError;
            if (businessErr.code === 100006) {
                Logger.warn(this.LOG_TAG, '用户取消选择');
                return null;
            }
            Logger.error(this.LOG_TAG, `选择备份文件失败, ${businessErr.code}, ${businessErr.message}`);
            throw new Error('备份文件选择失败');
        }
    }

    /** 读取已选文件的文本；读不到返回 null */
    async readText(uri: string): Promise<string | null> {
        try {
            const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);

            try {
                const fileStat = fs.statSync(file.fd);
                const fileSize = fileStat.size;

                // 不能用 readText(Sync)：会抛 13900002（No such file or directory）
                const arrayBuffer = new ArrayBuffer(fileSize);
                const readLen = fs.readSync(file.fd, arrayBuffer);

                if (readLen !== fileSize) {
                    Logger.warn(this.LOG_TAG, `应读取 ${fileSize} 字节, 实际读取 ${readLen}`);
                }

                return buffer.from(arrayBuffer, 0, readLen).toString();
            } finally {
                fs.closeSync(file);
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取备份文件失败, ${err}`);
            return null;
        }
    }

    private requireContext(): common.UIAbilityContext | null {
        if (!this.context) {
            Logger.error(this.LOG_TAG, '文件网关未初始化：先由 EntryAbility 调 initFileGateway()');
            return null;
        }
        return this.context;
    }
}