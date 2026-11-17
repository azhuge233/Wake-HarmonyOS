import { CommonConstants } from '../common/constants/CommonConstants';
import { Result } from '../common/util/Result';
import { AppSettingsService } from '../domain/AppSettingsService';

/**
 * 更多页的视图模型：只做颜色模式——持久化与默认值回填。
 * 把模式应用到应用上下文是平台副作用，留在页面用 ui/util/ColorModeApplier 调；
 * 共享的 AppSettings 也由页面写，VM 只管落盘。
 */
@ObservedV2
export class MoreViewModel {
    @Trace selected: number = CommonConstants.COLOR_MODE_NOT_SET;
    @Trace saving: boolean = false;

    private service: AppSettingsService;

    constructor(service: AppSettingsService) {
        this.service = service;
    }

    /** 读取持久化值；未写入过时回填默认值；读取失败则返回失败，selected 保持不动 */
    async load(): Promise<Result<number>> {
        const ensured = await this.service.ensureColorMode();
        if (ensured.ok && ensured.value !== null) this.selected = ensured.value;
        return ensured;
    }

    /** 保存成功才算切换：失败时 selected 不动，返回失败原因 */
    async save(mode: number): Promise<Result<number>> {
        if (mode === this.selected) return Result.success<number>(mode);

        this.saving = true;
        const saved = await this.service.saveColorMode(mode);
        if (saved.ok) this.selected = mode;
        this.saving = false;
        return saved;
    }
}
