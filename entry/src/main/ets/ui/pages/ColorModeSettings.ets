import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';

import { CommonConstants } from '../../common/constants/CommonConstants';
import { Logger } from '../../common/log/Logger';
import { AppSettingsService } from '../../domain/AppSettingsService';
import { AppSettings } from '../../viewmodel/AppSettings';
import { ColorModeViewModel } from '../../viewmodel/ColorModeViewModel';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { SettingGroup } from '../component/SettingGroup';
import { SettingRow } from '../component/SettingRow';
import { showToast } from '../feedback/Feedback';
import { apply } from '../util/ColorModeApplier';

export class ColorModeOption {
    label: ResourceStr;
    mode: ConfigurationConstant.ColorMode;

    constructor(label: ResourceStr, mode: ConfigurationConstant.ColorMode) {
        this.label = label;
        this.mode = mode;
    }
}

export const colorModeOptions: Array<ColorModeOption> = [
    new ColorModeOption($r('app.string.page_color_mode_system'), ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET),
    new ColorModeOption($r('app.string.page_color_mode_light'), ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT),
    new ColorModeOption($r('app.string.page_color_mode_dark'), ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
];

function createDefaultAppSettings(): AppSettings {
    return new AppSettings(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
}

@Builder
export function ColorModeSettingsBuilder() {
    ColorModeSettings();
}

@ComponentV2
struct ColorModeSettings {
    private LOG_TAG = '[ui/pages/ColorModeSettings]';

    @Local appSettings: AppSettings = AppStorageV2.connect(AppSettings,
        CommonConstants.APP_SETTINGS_STORAGE_KEY, () => createDefaultAppSettings())!;

    private viewModel: ColorModeViewModel = new ColorModeViewModel(AppSettingsService.instance());

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    private promptAction = this.uiContext.getPromptAction();

    pathStack: NavPathStack | undefined = undefined;

    async aboutToAppear(): Promise<void> {
        // 冷启动/页面恢复时可能先于 EntryAbility 连接，这里用持久化值回填
        const loaded = await this.viewModel.load();
        if (!loaded.ok) {
            // 读不到持久化值：本次沿用已在用的模式，不把失败当成「未写入」写回去；
            // 失败必须看得见——选中态照旧呈现而不提示，等于在 UI 面把失败又当成了未写入
            Logger.error(this.LOG_TAG, `读取颜色模式失败，本次沿用当前模式: ${loaded.error}`);
            showToast(this.promptAction, $r('app.string.unkown_error'));
            return;
        }

        const persisted: number = loaded.value ?? this.appSettings.colorMode;
        if (persisted !== this.appSettings.colorMode) {
            this.appSettings.colorMode = persisted as ConfigurationConstant.ColorMode;
            apply(this.context, persisted);
        }
    }

    /** 行点击与单选共用一条路径：写共享状态 + 持久化 + 应用颜色模式 */
    private async applyColorMode(option: ConfigurationConstant.ColorMode): Promise<void> {
        if (this.appSettings.colorMode === option) return;

        const saved = await this.viewModel.save(option);
        if (!saved.ok) {
            // 保存失败：共享状态与单选都不动（不报一次没落盘的切换），失败同样要看得见
            Logger.error(this.LOG_TAG, `保存颜色模式失败: ${option}, ${saved.error}`);
            showToast(this.promptAction, $r('app.string.unkown_error'));
            return;
        }

        this.appSettings.colorMode = option;
        apply(this.context, option);
    }

    @Builder
    ModeRows() {
        ForEach(colorModeOptions, (option: ColorModeOption) => {
            SettingRow({
                title: option.label,
                showRadio: true,
                checked: option.mode === this.appSettings.colorMode,
                onTap: () => {
                    this.applyColorMode(option.mode).catch((err: Error) => {
                        Logger.error(this.LOG_TAG, `切换颜色模式失败, ${err}`);
                    });
                }
            })
                .width('90%')
        }, (option: ColorModeOption) => option.mode.toString())
    }

    @Builder
    PageContent() {
        Column() {
            SettingGroup({
                rows: (): void => {
                    this.ModeRows();
                }
            })
        }
        .width('100%')
        .padding({
            top: 15
        })
    }

    @Builder
    PageOverlay() {
    }

    build() {
        PageScaffold({
            title: $r('app.string.color_mode_title'),
            logTag: this.LOG_TAG,
            fillSize: true,
            themeColorMode: true,
            pageBackground: $r('sys.color.background_primary'),
            content: (): void => {
                this.PageContent();
            },
            overlayContent: (): void => {
                this.PageOverlay();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            },
            onBack: () => {
                this.pathStack?.pop('Back pressed');
                return true;
            }
        })
    }
}