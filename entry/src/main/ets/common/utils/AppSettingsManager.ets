import { preferences } from '@kit.ArkData';
import { deviceInfo } from '@kit.BasicServicesKit';
import { ConfigurationConstant } from '@kit.AbilityKit';

import { Logger } from '../utils/Logger';
import { AppSettings } from '../../model/AppSettings';

interface StoredAppSettings {
    colorMode: number;
}

@ObservedV2
export class AppSettingsManager {
    private LOG_TAG = "[AppSettingsManager]";

    private static instance: AppSettingsManager | null = null;

    private dataPreferences: preferences.Preferences | null = null;

    private readonly PREFERENCES_NAME = 'ASFS_App_Preferences';
    private readonly STORE_KEY = 'AppSettings';

    private readonly isGSKVSupported = deviceInfo.sdkApiVersion >= 18 && preferences.isStorageTypeSupported(preferences.StorageType.GSKV);

    private constructor() {}

    public static getInstance(): AppSettingsManager {
        if (!AppSettingsManager.instance) AppSettingsManager.instance = new AppSettingsManager();
        return AppSettingsManager.instance;
    }

    init(context: Context) {
        try {
            let options: preferences.Options = {
                name: this.PREFERENCES_NAME,
                storageType: this.isGSKVSupported ? preferences.StorageType.GSKV : preferences.StorageType.XML
            }

            this.dataPreferences = preferences.getPreferencesSync(context, options);

            Logger.debug(this.LOG_TAG, `应用设置初始化完成`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `应用设置初始化失败, ${err}`);
        }
    }

    async set(appSettings: AppSettings): Promise<boolean> {
        if(!this.checkReady()) return false;

        try {
            // 只持久化纯数据，避免 @ObservedV2 代理对象序列化后字段异常
            const stored: StoredAppSettings = { colorMode: appSettings.colorMode as number };
            Logger.debug(this.LOG_TAG, `set() 写入: ${JSON.stringify(stored)}`);
            await this.dataPreferences?.put(this.STORE_KEY, stored);
            if(!this.isGSKVSupported) await this.dataPreferences?.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `保存应用设置失败, ${err}`);
            return false;
        }
    }

    async get(): Promise<AppSettings | null> {
        if(!this.checkReady()) return null;

        try {
            const storeObj = await this.dataPreferences!.get(this.STORE_KEY, '') as Record<string, Object>;
            Logger.debug(this.LOG_TAG, `get() 读取: ${JSON.stringify(storeObj)}`);

            if(storeObj && typeof storeObj === 'object') {
                const colorMode = storeObj.colorMode;
                if (typeof colorMode === 'number') {
                    return new AppSettings(colorMode as ConfigurationConstant.ColorMode);
                }
            }

            return null;
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取应用设置失败, ${err}`);
            return null;
        }
    }

    private checkReady(): boolean {
        if (!this.dataPreferences) {
            Logger.error(this.LOG_TAG, `首选项未初始化`);
            return false;
        }
        return true;
    }
}