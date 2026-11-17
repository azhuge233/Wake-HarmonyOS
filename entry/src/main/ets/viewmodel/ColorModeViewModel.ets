import { CommonConstants } from '../common/constants/CommonConstants';
import { Result } from '../common/util/Result';
import { AppSettingsService } from '../domain/AppSettingsService';

/**
 * 颜色模式设置页的视图模型：只负责持久化。
 * 把模式应用到应用上下文是平台副作用，留在页面用 ui/util/ColorModeApplier 调（§3.6）。
 */
@ObservedV2
export class ColorModeViewModel {
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