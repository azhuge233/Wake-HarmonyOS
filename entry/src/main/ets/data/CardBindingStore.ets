import { preferences } from '@kit.ArkData';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

import { Logger } from '../common/log/Logger';

/**
 * 卡片绑定的持久化：首选项名 Wake_Forms_Preferences、键 = formID、值 = 绑定数据 JSON 字符串，全部冻结。
 * 只做存取，不认识 Device；"某台设备绑在哪些卡片上"是领域判定。
 */
export class CardBindingStore {
    private LOG_TAG = '[CardBindingStore]';

    private static instance: CardBindingStore | null = null;

    private initPromise: Promise<void> | null = null;
    /** 初始化失败的原因：initPromise 已清空后仍留着，供 ready() 把原始错误交出去 */
    private initError: Error | null = null;
    private dataPreferences: preferences.Preferences | null = null;

    private readonly PREFERENCES_NAME = 'Wake_Forms_Preferences';

    private readonly isGSKVSupported: boolean =
        deviceInfo.sdkApiVersion >= 18 && preferences.isStorageTypeSupported(preferences.StorageType.GSKV);

    constructor() {
    }

    static getInstance(): CardBindingStore {
        if (!CardBindingStore.instance) CardBindingStore.instance = new CardBindingStore();
        return CardBindingStore.instance;
    }

    /**
     * 幂等：重复调用与并发调用共用同一个 initPromise，只建一个 preferences。
     * initPromise 只在失败分支清空（供下次 init() 重试），而清空那一刻 dataPreferences 尚未赋值。
     * 失败原因另存 initError：initPromise 清空后 ready() 仍能把原始错误交给调用方。
     * 只用应用上下文建首选项：首选项路径由传入的上下文决定，
     * UIAbilityContext 会落到 `<bundle>/entry/preferences`，与 2.8.0 的卡片绑定不是一个文件。
     */
    init(context: Context): void {
        if (this.initPromise) return;

        const appContext: Context = context.getApplicationContext();

        this.initPromise = new Promise<void>((resolve: () => void, reject: (reason: Error) => void) => {
            const options: preferences.Options = {
                name: this.PREFERENCES_NAME,
                storageType: this.isGSKVSupported ? preferences.StorageType.GSKV : preferences.StorageType.XML
            };

            preferences.getPreferences(appContext, options).then((preference: preferences.Preferences) => {
                this.dataPreferences = preference;
                this.initError = null; // 本次初始化成功（含失败后的重试成功）：旧的失败原因不再成立
                resolve();
            }).catch((err: BusinessError) => {
                Logger.error(this.LOG_TAG, `卡片绑定首选项初始化失败, ${err}`);
                const failure = new Error(`卡片绑定首选项初始化失败: ${err.message}`);
                this.initError = failure; // 先留原因再清 initPromise：ready() 在那之后仍拿得到原始错误
                this.initPromise = null; // 允许下次 init() 重试
                reject(failure);
            });
        });

        this.initPromise.catch((err: Error) => {
            Logger.warn(this.LOG_TAG, `卡片绑定首选项初始化失败（已记录）: ${err.message}`);
        });
    }

    /**
     * 三种拒绝与 DeviceDao.ready 同形：初始化进行中 ⇒ 交回那次 init 的 promise；
     * 初始化失败（initPromise 已清空、失败原因仍在）⇒ 原样拒绝失败原因，文案带原始错误信息；
     * 从未 init ⇒ 「未初始化」。
     */
    ready(): Promise<void> {
        const pending = this.initPromise;
        if (pending) return pending;

        const failure = this.initError;
        if (failure) return Promise.reject(failure);

        return Promise.reject(new Error('卡片绑定首选项未初始化，先执行 init()'));
    }

    async put(formID: string, rawJson: string): Promise<boolean> {
        await this.ready();

        if (!this.dataPreferences) return false;

        try {
            await this.dataPreferences.put(formID, rawJson);
            if (!this.isGSKVSupported) await this.dataPreferences.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `写入卡片绑定失败, formID: ${formID}, ${err}`);
            return false;
        }
    }

    async getRaw(formID: string): Promise<string | null> {
        await this.ready();

        if (!this.dataPreferences) return null;

        try {
            const raw = await this.dataPreferences.get(formID, '') as string;
            return raw === '' ? null : raw;
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取卡片绑定失败, formID: ${formID}, ${err}`);
            return null;
        }
    }

    async remove(formID: string): Promise<boolean> {
        await this.ready();

        if (!this.dataPreferences) return false;

        try {
            await this.dataPreferences.delete(formID);
            if (!this.isGSKVSupported) await this.dataPreferences.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `删除卡片绑定失败, formID: ${formID}, ${err}`);
            return false;
        }
    }

    /** formID → 原始 JSON */
    async getAllRaw(): Promise<Map<string, string>> {
        await this.ready();

        const result: Map<string, string> = new Map<string, string>();
        if (!this.dataPreferences) return result;

        try {
            const all = await this.dataPreferences.getAll();
            const map = (all ?? {}) as Record<string, string>;
            for (const key of Object.keys(map)) {
                result.set(key, map[key]);
            }
            return result;
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取全部卡片绑定失败, ${err}`);
            return result;
        }
    }

    async clear(): Promise<boolean> {
        await this.ready();

        if (!this.dataPreferences) return false;

        try {
            await this.dataPreferences.clear();
            if (!this.isGSKVSupported) await this.dataPreferences.flush();
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `清空卡片绑定失败, ${err}`);
            return false;
        }
    }
}