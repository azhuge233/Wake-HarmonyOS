import { preferences } from '@kit.ArkData';
import { deviceInfo } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

import { Logger } from '../common/log/Logger';
import { Result } from '../common/util/Result';

interface StoredAppSettings {
    colorMode: number;
}

/**
 * 应用设置的持久化：首选项名 ASFS_App_Preferences、键 AppSettings、存储体 { colorMode: number }，冻结。
 * 只收发数字，不引用视图模型层的 AppSettings 类型。
 */
export class SettingsStore {
    private LOG_TAG = '[SettingsStore]';

    private static instance: SettingsStore | null = null;

    private dataPreferences: preferences.Preferences | null = null;
    /** 初始化失败的原因：显式记下，读取方走失败通道，不把「初始化失败」当成「从未写入」 */
    private initError: string = '';

    private readonly PREFERENCES_NAME = 'ASFS_App_Preferences';
    private readonly STORE_KEY = 'AppSettings';

    private readonly isGSKVSupported: boolean =
        deviceInfo.sdkApiVersion >= 18 && preferences.isStorageTypeSupported(preferences.StorageType.GSKV);

    constructor() {
    }

    static getInstance(): SettingsStore {
        if (!SettingsStore.instance) SettingsStore.instance = new SettingsStore();
        return SettingsStore.instance;
    }

    /**
     * 只用应用上下文建首选项：首选项路径由传入的上下文决定，
     * UIAbilityContext 会落到 `<bundle>/entry/preferences`，与 2.8.0 的应用设置不是一个文件。
     */
    init(context: Context): void {
        try {
            const options: preferences.Options = {
                name: this.PREFERENCES_NAME,
                storageType: this.isGSKVSupported ? preferences.StorageType.GSKV : preferences.StorageType.XML
            };

            this.dataPreferences = preferences.getPreferencesSync(context.getApplicationContext(), options);
            this.initError = '';
            Logger.debug(this.LOG_TAG, '应用设置初始化完成');
        } catch (err) {
            this.dataPreferences = null;
            this.initError = `应用设置首选项初始化失败: ${err}`;
            Logger.error(this.LOG_TAG, `应用设置初始化失败, ${err}`);
        }
    }

    /**
     * 从未写入 ⇒ ok、值为 null；初始化失败或读取失败 ⇒ 失败、带原因。
     * 两种情形不同形：调用方不会把一个 null 当成「用户没设过」再写回去。
     */
    async getColorMode(): Promise<Result<number | null>> {
        if (!this.dataPreferences) {
            return Result.failure<number | null>(this.initError !== '' ? this.initError : '应用设置首选项未初始化');
        }

        try {
            const stored = await this.dataPreferences.get(this.STORE_KEY, '') as Record<string, Object>;
            if (stored && typeof stored === 'object') {
                const colorMode = stored['colorMode'];
                if (typeof colorMode === 'number') return Result.success<number | null>(colorMode as number);
            }
            return Result.success<number | null>(null);
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取应用设置失败, ${err}`);
            return Result.failure<number | null>(`读取应用设置失败: ${err}`);
        }
    }

    /** 写入成功 ⇒ ok、值为写入的模式；初始化失败或写入失败 ⇒ 失败、带原因，与「未写入」可区分 */
    async setColorMode(colorMode: number): Promise<Result<number>> {
        if (!this.dataPreferences) {
            return Result.failure<number>(this.initError !== '' ? this.initError : '应用设置首选项未初始化');
        }

        try {
            const stored: StoredAppSettings = { colorMode: colorMode };
            await this.dataPreferences.put(this.STORE_KEY, stored);
            if (!this.isGSKVSupported) await this.dataPreferences.flush();
            return Result.success<number>(colorMode);
        } catch (err) {
            Logger.error(this.LOG_TAG, `保存应用设置失败, ${err}`);
            return Result.failure<number>(`保存应用设置失败: ${err}`);
        }
    }
}