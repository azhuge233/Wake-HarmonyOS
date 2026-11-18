import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { AppStorageV2 } from '@kit.ArkUI';

import { CommonConstants } from '../../common/constants/CommonConstants';
import { StyleConstants } from '../../common/constants/StyleConstants';
import { Logger } from '../../common/log/Logger';
import { AppSettingsService } from '../../domain/AppSettingsService';
import { AppSettings } from '../../viewmodel/AppSettings';
import { MoreViewModel } from '../../viewmodel/MoreViewModel';
import { MoreMenuItem } from '../component/MoreMenuItem';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { SettingGroup } from '../component/SettingGroup';
import { SettingRow } from '../component/SettingRow';
import { showToast } from '../feedback/Feedback';
import { apply } from '../util/ColorModeApplier';

/** 颜色模式的一档：显示文字 + 平台枚举值 */
class ColorModeOption {
    label: ResourceStr;
    mode: ConfigurationConstant.ColorMode;

    constructor(label: ResourceStr, mode: ConfigurationConstant.ColorMode) {
        this.label = label;
        this.mode = mode;
    }
}

/** 三档顺序即下拉框顺序：跟随系统 / 浅色 / 深色 */
const colorModeOptions: Array<ColorModeOption> = [
    new ColorModeOption($r('app.string.page_color_mode_system'), ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET),
    new ColorModeOption($r('app.string.page_color_mode_light'), ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT),
    new ColorModeOption($r('app.string.page_color_mode_dark'), ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
];

function createDefaultAppSettings(): AppSettings {
    return new AppSettings(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
}

@Builder
export function MoreBuilder() {
    More();
}

/**
 * 设置首页：四张卡——颜色模式（行内选择）、网络信息、数据管理、关于。
 * 颜色模式的三档选项与「写共享状态 + 落盘 + 应用」逻辑只在本页；导出 / 导入 / 清除搬进 DataManagement，
 * 版本号搬进 About，本页不再有版本号页脚。
 */
@ComponentV2
struct More {
    private LOG_TAG = '[ui/pages/More]';

    @Local appSettings: AppSettings = AppStorageV2.connect(AppSettings,
        CommonConstants.APP_SETTINGS_STORAGE_KEY, () => createDefaultAppSettings())!;

    private viewModel: MoreViewModel = new MoreViewModel(AppSettingsService.instance());

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

    /** 选中即生效：写共享状态 + 落盘 + 应用；保存失败时三处都不动 */
    private async applyColorMode(option: ConfigurationConstant.ColorMode): Promise<void> {
        if (this.appSettings.colorMode === option) return;

        const saved = await this.viewModel.save(option);
        if (!saved.ok) {
            Logger.error(this.LOG_TAG, `保存颜色模式失败: ${option}, ${saved.error}`);
            showToast(this.promptAction, $r('app.string.unkown_error'));
            return;
        }

        this.appSettings.colorMode = option;
        apply(this.context, option);
    }

    /** 下拉框的选项与当前档：显示文字来自三档表，下标按当前共享状态认 */
    private colorModeSelectOptions(): Array<SelectOption> {
        const options: Array<SelectOption> = [];
        for (const option of colorModeOptions) {
            const item: SelectOption = { value: option.label };
            options.push(item);
        }
        return options;
    }

    private colorModeIndex(): number {
        for (let index = 0; index < colorModeOptions.length; index++) {
            if (colorModeOptions[index].mode === this.appSettings.colorMode) return index;
        }
        return 0;
    }

    private colorModeLabel(): ResourceStr {
        return colorModeOptions[this.colorModeIndex()].label;
    }

    @Builder
    ColorModeSelect() {
        Select(this.colorModeSelectOptions())
            .selected(this.colorModeIndex())
            .value(this.colorModeLabel())
            .font({ size: StyleConstants.TEXT_FONT_SIZE_FOURTEEN })
            .fontColor($r('sys.color.font_secondary'))
            .margin({ left: StyleConstants.MARGIN_TEN })
            .onSelect((index: number) => {
                this.applyColorMode(colorModeOptions[index].mode).catch((err: Error) => {
                    Logger.error(this.LOG_TAG, `切换颜色模式失败, ${err}`);
                });
            })
    }

    @Builder
    ColorModeRow() {
        SettingRow({
            icon: $r('sys.symbol.brush'),
            title: $r('app.string.color_mode_title'),
            desc: $r('app.string.color_mode_desc'),
            showArrow: false,
            interactive: false,
            titleColor: $r('sys.color.font_primary'),
            trailing: (): void => {
                this.ColorModeSelect();
            }
        })
    }

    @Builder
    NetworkInfoRow() {
        MoreMenuItem({
            menuTitleText: $r('app.string.network_info_title'),
            menuDescText: $r('app.string.network_info_desc'),
            menuIcon: $r('sys.symbol.wifi'),
            onTap: () => {
                this.pathStack?.pushPath({ name: 'NetworkInfo', param: this.pathStack });
            }
        })
    }

    @Builder
    DataManagementRow() {
        MoreMenuItem({
            menuTitleText: $r('app.string.data_management_title'),
            menuDescText: $r('app.string.data_management_desc'),
            menuIcon: $r('sys.symbol.doc_plaintext'),
            onTap: () => {
                this.pathStack?.pushPath({ name: 'DataManagement', param: this.pathStack });
            }
        })
    }

    @Builder
    AboutRow() {
        MoreMenuItem({
            menuTitleText: $r('app.string.about_title'),
            menuIcon: $r('sys.symbol.info_circle'),
            onTap: () => {
                this.pathStack?.pushPath({ name: 'About', param: this.pathStack });
            }
        })
    }

    @Builder
    PageContent() {
        Column({ space: StyleConstants.CARD_SPACE }) {
            SettingGroup({
                rows: (): void => {
                    this.ColorModeRow();
                }
            })

            SettingGroup({
                rows: (): void => {
                    this.NetworkInfoRow();
                }
            })

            SettingGroup({
                rows: (): void => {
                    this.DataManagementRow();
                }
            })

            SettingGroup({
                rows: (): void => {
                    this.AboutRow();
                }
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .padding({
            top: StyleConstants.PAGE_PADDING,
            bottom: StyleConstants.PAGE_PADDING,
            left: StyleConstants.PAGE_PADDING,
            right: StyleConstants.PAGE_PADDING
        })
    }

    build() {
        PageScaffold({
            title: $r('app.string.settings_title'),
            logTag: this.LOG_TAG,
            scrollable: true,
            pageBackground: $r('sys.color.background_secondary'),
            content: (): void => {
                this.PageContent();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            }
        })
    }
}
