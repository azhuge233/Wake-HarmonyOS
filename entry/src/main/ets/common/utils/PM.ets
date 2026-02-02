import preferences from '@ohos.data.preferences';
import { deviceInfo } from '@kit.BasicServicesKit';

import Logger from './Logger';
import SingleDeviceFormData from '../../singledevicewidget/model/SingleDeviceFormData';
import Device from '../../model/Device';

export class PM {
    private LOG_TAG = '[PM]';

    private static instance: PM | null = null;

    private isInitialized: boolean = false; // 初始化标志
    private initPromise: Promise<void> | null = null;
    private resolveInit: (() => void) | null = null;

    private dataPreferences: preferences.Preferences | null = null;

    private readonly PREFERENCES_NAME = 'Wake_Forms_Preferences';

    private readonly isGSKVSupported = deviceInfo.sdkApiVersion >= 18 && preferences.isStorageTypeSupported(preferences.StorageType.GSKV);

    private constructor() {}

    public static getInstance(): PM {
        if (!PM.instance) PM.instance = new PM();
        return PM.instance;
    }

    async init(context: Context): Promise<void> {
        if (this.initPromise) return;

        this.initPromise = new Promise((resolve) => {
            this.resolveInit = resolve;

            let options: preferences.Options = {
                name: this.PREFERENCES_NAME,
                storageType: this.isGSKVSupported ? preferences.StorageType.GSKV : preferences.StorageType.XML
            }

            // 异步初始化数据库
            preferences.getPreferences(context, options).then((preference) => {
                this.dataPreferences = preference;
                this.isInitialized = true;
                resolve(); // 解析Promise表示初始化完成
            }).catch((err: BusinessError) => {
                Logger.error(this.LOG_TAG, `首选项初始化失败, ${err}`);
                resolve(); // 即使失败也要resolve，避免永久阻塞
            });
        });
    }

    async bind(formId: string, formData: SingleDeviceFormData): Promise<boolean> {
        await this.waitForReady();

        if (!this.dataPreferences) return false;

        try {
            const formDataStr = JSON.stringify(formData);
            await this.dataPreferences.put(formId, formDataStr);
            if(!this.isGSKVSupported) await this.dataPreferences.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `绑定卡片失败, ${err}`);
            return false;
        }
    }

    async unbind(formId: string): Promise<boolean> {
        await this.waitForReady();

        if (!this.dataPreferences) return false;

        try {
            const formDataStr = await this.dataPreferences.get(formId, '') as string;

            if (formDataStr !== '') {
                await this.dataPreferences.delete(formId);
                if(!this.isGSKVSupported) await this.dataPreferences.flush();
            } else Logger.warn(this.LOG_TAG, `${formId} 不存在`);

            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `解除绑定失败, ${err}`);
            return false;
        }
    }

    async getFormDataByID(formId: string): Promise<SingleDeviceFormData | null> {
        await this.waitForReady();

        if (!this.dataPreferences) return null;

        try {
            const formDataStr = await this.dataPreferences.get(formId, '') as string;

            if(formDataStr !== '') {
                const formData: SingleDeviceFormData = JSON.parse(formDataStr);
                return formData;
            } else return null;
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取绑定失败, ${err}`);
            return null;
        }
    }

    async getAllCardBindings(): Promise<Array<SingleDeviceFormData>> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataMap = (await this.dataPreferences.getAll() ?? {}) as Record<string, string>;
            const keys = Object.keys(formDataMap);

            return keys.map(key => JSON.parse(formDataMap[key]) as SingleDeviceFormData);
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取所有绑定失败, ${err}`);
            return [];
        }
    }

    async updateByDevice(device: Device): Promise<string[]> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataArr = await this.getAllCardBindings();

            let updatedFormIDs: string[] = [];

            // 更新所有绑定该指令的卡片，统计受影响的 formID
            formDataArr.forEach(async formData => {
                if(formData.deviceID === device.ID) {
                    updatedFormIDs.push(formData.formID);

                    formData.alias = device.Alias;
                    formData.mac = device.MAC;

                    await this.bind(formData.formID, formData);
                }
            });

            return updatedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `更新指令绑定失败, ${err}`);
            return [];
        }
    }

    async removeBindingsByDeviceId(deviceID: number): Promise<string[]> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataArr = await this.getAllCardBindings();

            let removedFormIDs: string[] = [];

            // 删除所有绑定该指令的卡片，统计受影响的 formID
            formDataArr.forEach(async formData => {
                if(formData.deviceID === deviceID) {
                    removedFormIDs.push(formData.formID);
                    await this.unbind(formData.formID);
                }
            });

            return removedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `删除指令绑定失败, ${err}`);
            return [];
        }
    }

    async clearAllBindings(): Promise<boolean> {
        await this.waitForReady();

        if (!this.dataPreferences) return false;

        try {
            await this.dataPreferences.clear();
            if(!this.isGSKVSupported) await this.dataPreferences.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `清空绑定失败, ${err}`);
            return false;
        }
    }

    private async waitForReady(): Promise<void> {
        if (!this.initPromise) throw new Error("首选项未初始化，先执行 init()");
        await this.initPromise;
    }
}