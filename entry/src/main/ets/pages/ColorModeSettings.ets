import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit';
import { AppStorageV2 } from '@kit.ArkUI';

import { StyleConstants } from '../common/constants/StyleConstants';
import { AppSettingsManager } from '../common/utils/AppSettingsManager';
import { Logger } from '../common/utils/Logger';
import { AppSettings } from '../model/AppSettings';
import { CommonConstants } from '../common/constants/CommonConstants';

function createDefaultAppSettings(): AppSettings {
    return new AppSettings(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
}

export class ColorModeOption {
    label: string | Resource;
    mode: ConfigurationConstant.ColorMode;

    constructor(label: string | Resource, mode: ConfigurationConstant.ColorMode) {
        this.label = label;
        this.mode = mode;
    }
}

export const colorModeOptions: Array<ColorModeOption> = [
    new ColorModeOption($r("app.string.page_color_mode_system"), ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET),
    new ColorModeOption($r("app.string.page_color_mode_light"), ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT),
    new ColorModeOption($r("app.string.page_color_mode_dark"), ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
];

@Builder
export function ColorModeSettingsBuilder() {
    ColorModeSettings();
}

@Entry
@ComponentV2
struct ColorModeSettings {
    private LOG_TAG = "[pages/ColorModeSettings]";

    @Local appSettings: AppSettings = AppStorageV2.connect(AppSettings, CommonConstants.APP_STORAGE_KEY_APP_SETTINGS, () => createDefaultAppSettings())!;

    pathStack: NavPathStack | undefined = undefined;

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    private asm: AppSettingsManager = AppSettingsManager.getInstance();

    async aboutToAppear(): Promise<void> {
        // 冷启动/页面恢复时可能先于 EntryAbility 连接，这里用持久化值回填
        const persisted = await this.asm.get();
        if (persisted && persisted.colorMode !== this.appSettings.colorMode) {
            this.appSettings.colorMode = persisted.colorMode;
            try {
                this.context.getApplicationContext().setColorMode(persisted.colorMode);
            } catch (err) {
                Logger.error(this.LOG_TAG, `恢复窗口颜色模式失败, ${err}`);
            }
        }
    }

    private async applyColorMode(selectedColorMode: ConfigurationConstant.ColorMode): Promise<void> {
        // 行点击和 Radio 共用同一条路径：写内存 + 持久化 + 应用窗口颜色
        Logger.debug(this.LOG_TAG, `applyColorMode: selected=${selectedColorMode}, current=${this.appSettings.colorMode}`);
        if (this.appSettings.colorMode === selectedColorMode) return;

        this.appSettings.colorMode = selectedColorMode;
        const saved = await this.asm.set(this.appSettings);
        Logger.debug(this.LOG_TAG, `applyColorMode 保存: ${saved}, colorMode=${this.appSettings.colorMode}`);

        try {
            this.context.getApplicationContext().setColorMode(selectedColorMode);
            Logger.debug(this.LOG_TAG, `窗口颜色设置: ${this.appSettings.colorMode}`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `设置窗口颜色模式失败, ${err}`);
        }
    }

    @Builder
    MainContent() {
        Column() {
            ForEach(colorModeOptions, (option: ColorModeOption) => {
                Row() {
                    Text(option.label)
                        .fontColor($r("sys.color.font_primary"))
                        .layoutWeight(1)
                        .padding(StyleConstants.PADDING_FIFTEEN);

                    Radio({
                        value: option.mode.toString(),
                        group: 'colorMode'
                    })
                        .height(StyleConstants.RADIO_SIZE)
                        .width(StyleConstants.RADIO_SIZE)
                        .checked(option.mode === this.appSettings.colorMode)
                        .onChange(async (isChecked: boolean) => {
                            if (isChecked) {
                                await this.applyColorMode(option.mode);
                            }
                        })
                        .padding({
                            right: StyleConstants.PADDING_FIFTEEN
                        });
                }
                .width(StyleConstants.NINETY_PERCENT)
                .border({
                    width: { bottom: StyleConstants.BORDER_WIDTH },
                    color: $r("sys.color.font_tertiary")
                })
                .onClick(() => {
                    this.applyColorMode(option.mode).catch((err: Error) => {
                        Logger.error(this.LOG_TAG, `切换颜色模式失败, ${err}`);
                    });
                })
            }, (option: ColorModeOption) => option.mode.toString());
        }
        .width(StyleConstants.FULL_PERCENT)
        .padding({
            top: StyleConstants.PADDING_FIFTEEN
        });
    }

    build() {
        HdsNavDestination() {
            this.MainContent();
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.color_mode_title")
                }
            },
            style: {
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                }
            },
            enableComponentSafeArea: true
        })
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .withTheme({
            enableThemeColorMode: true
        })
        .backgroundColor($r("sys.color.background_primary"))
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
        })
        .onBackPressed(() => {
            this.pathStack?.pop("Back pressed");
            return true;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}