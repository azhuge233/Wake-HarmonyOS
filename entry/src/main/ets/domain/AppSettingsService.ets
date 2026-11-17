import { SettingsStore } from '../data/SettingsStore';

import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/log/Logger';
import { Result } from '../common/util/Result';

/**
 * 颜色模式持久化与默认值回填。三种结果各自可区分（Result 的失败态与空结果不是一回事）：
 * 读到了 ⇒ ok 带值；从未写入 ⇒ ok 带 null，此时 ensureColorMode() 回填默认值并返回它；
 * 初始化失败或读写失败 ⇒ 失败带原因——调用方据此用系统默认启动，不拿默认值覆盖已存的值。
 */
export class AppSettingsService {
    private LOG_TAG = '[AppSettingsService]';

    private static shared: AppSettingsService | null = null;

    private store: SettingsStore;

    constructor(store: SettingsStore) {
        this.store = store;
    }

    static instance(): AppSettingsService {
        if (!AppSettingsService.shared) {
            AppSettingsService.shared = new AppSettingsService(SettingsStore.getInstance());
        }
        return AppSettingsService.shared;
    }

    async loadColorMode(): Promise<Result<number | null>> {
        return this.store.getColorMode();
    }

    async saveColorMode(colorMode: number): Promise<Result<number>> {
        return this.store.setColorMode(colorMode);
    }

    /** 未写入过时回填默认值，返回最终要使用的模式；读取失败则失败，不写回任何值 */
    async ensureColorMode(): Promise<Result<number>> {
        const loaded = await this.loadColorMode();
        if (!loaded.ok) return Result.failure<number>(loaded.error);

        if (loaded.value !== null) return Result.success<number>(loaded.value);

        const fallback = CommonConstants.COLOR_MODE_NOT_SET;
        const saved = await this.saveColorMode(fallback);
        if (!saved.ok) {
            Logger.warn(this.LOG_TAG, `回填默认颜色模式失败: ${saved.error}`);
            return Result.failure<number>(saved.error);
        }
        return Result.success<number>(fallback);
    }
}