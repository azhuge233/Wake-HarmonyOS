import preferences from '@ohos.data.preferences';
import { deviceInfo } from '@kit.BasicServicesKit';

import { Logger } from './Logger';
import { SingleDeviceFormData } from '../../singledevicewidget/model/SingleDeviceFormData';
import { Device } from '../../model/Device';
import { MultipleDevicesFormData } from '../../multipledeviceswidget/model/MultipleDevicesFormData';

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
                this.initPromise = null;
                resolve(); // 允许下次 init() 重试
            });
        });
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

    async bindSingle(formId: string, formData: SingleDeviceFormData): Promise<boolean> {
        await this.waitForReady();

        if (!this.dataPreferences) return false;

        try {
            const formDataStr = JSON.stringify(formData);
            await this.dataPreferences.put(formId, formDataStr);
            if(!this.isGSKVSupported) await this.dataPreferences.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `bindSingle() 绑定卡片失败, ${err}`);
            return false;
        }
    }

    async getFormDataByIDSingle(formId: string): Promise<SingleDeviceFormData | null> {
        await this.waitForReady();

        if (!this.dataPreferences) return null;

        try {
            const formDataStr = await this.dataPreferences.get(formId, '') as string;

            if(formDataStr !== '') {
                const formData: SingleDeviceFormData = JSON.parse(formDataStr);
                return formData;
            } else return null;
        } catch (err) {
            Logger.error(this.LOG_TAG, `getFormDataByIDSingle() 获取绑定失败, ${err}`);
            return null;
        }
    }

    // deviceList 属性只存在于多设备卡片数据中；解析后判断属性，避免 MAC/别名里出现 deviceList 时误判
    private isMultipleCardData(raw: string): boolean {
        try {
            const parsed = JSON.parse(raw) as Record<string, Object>;
            return Array.isArray(parsed['deviceList']);
        } catch (err) {
            return false;
        }
    }

    async getAllCardBindingsSingle(): Promise<Array<SingleDeviceFormData>> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataMap = (await this.dataPreferences.getAll() ?? {}) as Record<string, string>;
            let keys = Object.keys(formDataMap);
            keys = keys.filter(key => !this.isMultipleCardData(formDataMap[key]));

            return keys.map(key => JSON.parse(formDataMap[key]) as SingleDeviceFormData);
        } catch (err) {
            Logger.error(this.LOG_TAG, `getAllCardBindingsSingle() 获取所有绑定失败, ${err}`);
            return [];
        }
    }

    async updateByDeviceSingle(device: Device): Promise<string[]> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataArr = await this.getAllCardBindingsSingle();

            let updatedFormIDs: string[] = [];

            // 更新所有绑定该设备的卡片，统计受影响的 formID
            for (const formData of formDataArr) {
                if(formData.deviceID === device.ID) {
                    updatedFormIDs.push(formData.formID);

                    formData.alias = device.Alias;
                    formData.mac = device.MAC;
                    formData.address = device.Address;
                    formData.port = device.Port;

                    await this.bindSingle(formData.formID, formData);
                }
            }

            return updatedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `updateByDeviceSingle() 更新设备绑定失败, ${err}`);
            return [];
        }
    }

    async removeBindingsByDeviceIdSingle(deviceID: number): Promise<string[]> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataArr = await this.getAllCardBindingsSingle();

            let removedFormIDs: string[] = [];

            // 删除所有绑定该设备的卡片，统计受影响的 formID
            for (const formData of formDataArr) {
                if(formData.deviceID === deviceID) {
                    removedFormIDs.push(formData.formID);
                    await this.unbind(formData.formID);
                }
            }

            return removedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `removeBindingsByDeviceIdSingle() 删除设备绑定失败, ${err}`);
            return [];
        }
    }

    async bindMultiple(formId: string, formData: MultipleDevicesFormData): Promise<boolean> {
        await this.waitForReady();

        if (!this.dataPreferences) return false;

        try {
            const formDataStr = JSON.stringify(formData);
            await this.dataPreferences.put(formId, formDataStr);
            if(!this.isGSKVSupported) await this.dataPreferences.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `bindMultiple() 绑定卡片失败, ${err}`);
            return false;
        }
    }

    async getFormDataByIDMultiple(formId: string): Promise<MultipleDevicesFormData | null> {
        await this.waitForReady();

        if (!this.dataPreferences) return null;

        try {
            const formDataStr = await this.dataPreferences.get(formId, '') as string;

            if(formDataStr !== '') {
                const formData: MultipleDevicesFormData = JSON.parse(formDataStr);
                return formData;
            } else return null;
        } catch (err) {
            Logger.error(this.LOG_TAG, `getFormDataByIDMultiple() 获取绑定失败, ${err}`);
            return null;
        }
    }

    async getAllCardBindingsMultiple(): Promise<Array<MultipleDevicesFormData>> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataMap = (await this.dataPreferences.getAll() ?? {}) as Record<string, string>;
            let keys = Object.keys(formDataMap);
            keys = keys.filter(key => this.isMultipleCardData(formDataMap[key]));

            return keys.map(key => JSON.parse(formDataMap[key]) as MultipleDevicesFormData);
        } catch (err) {
            Logger.error(this.LOG_TAG, `getAllCardBindingsMultiple() 获取所有绑定失败, ${err}`);
            return [];
        }
    }

    async updateByDeviceMultiple(device: Device): Promise<string[]> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataArr = await this.getAllCardBindingsMultiple();

            let updatedFormIDs: string[] = [];

            // 更新所有绑定该设备的卡片，统计受影响的 formID
            for(const formData of formDataArr) {
                let needsUpdate: boolean = false;

                for(let shortcut of formData.deviceList) {
                    if(shortcut.id == device.ID) {
                        needsUpdate = true;

                        shortcut.alias = device.Alias;
                        shortcut.mac = device.MAC;
                        shortcut.address = device.Address;
                        shortcut.port = device.Port;

                        break;
                    }
                }

                if(needsUpdate) {
                    updatedFormIDs.push(formData.formID);
                    await this.bindMultiple(formData.formID, formData);
                }
            }

            return updatedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `updateByDeviceMultiple() 更新设备绑定失败, ${err}`);
            return [];
        }
    }

    async removeBindingsByDeviceIdMultiple(deviceID: number): Promise<string[]> {
        await this.waitForReady();

        if (!this.dataPreferences) return [];

        try {
            const formDataArr = await this.getAllCardBindingsMultiple();

            let affectedFormIDs: string[] = [];

            // 删除所有绑定该设备的卡片，统计受影响的 formID
            for(let formData of formDataArr) {
                // 过滤掉要删除的设备
                const originalLength = formData.deviceList.length;
                formData.deviceList = formData.deviceList.filter(
                  shortcut => shortcut.id !== deviceID
                );

                // 如果设备列表有变化
                if(formData.deviceList.length !== originalLength) {
                    affectedFormIDs.push(formData.formID);

                    // 如果设备列表为空，删除整个卡片
                    if(formData.deviceList.length === 0) await this.unbind(formData.formID);
                    else await this.bindMultiple(formData.formID, formData); // 否则更新卡片
                }
            }

            return affectedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `removeBindingsByDeviceIdMultiple() 删除设备绑定失败, ${err}`);
            return [];
        }
    }

    private async waitForReady(): Promise<void> {
        if (!this.initPromise) throw new Error("首选项未初始化，先执行 init()");
        await this.initPromise;
    }
}