import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { AppStorageV2, window } from '@kit.ArkUI';

import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/log/Logger';
import { Result } from '../common/util/Result';
import { AppSettingsService } from '../domain/AppSettingsService';
import { AppSettings } from '../viewmodel/AppSettings';
import { apply as applyColorMode } from '../ui/util/ColorModeApplier';
import { AbilitySetup, WindowParams } from './AbilitySetup';

/** 应用主入口：装配数据层、窗口参数通道与颜色模式，然后加载 Index */
export default class EntryAbility extends UIAbility {
    private LOG_TAG = '[EntryAbility]';

    private targetPage: string = 'ui/pages/Index';
    private currentWindowStage: window.WindowStage | null = null;
    private storage: LocalStorage | null = null;

    /** onCreate 暂存，onWindowStageCreate 建 storage 时写入 */
    private params: WindowParams = {};

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, 'onCreate()');

        AbilitySetup.initDataLayer(this.context);
        AbilitySetup.initFileGateway(this.context);

        if (want.parameters?.params) {
            this.handleFormWant(want);
        } else if (want.parameters?.isFromShortcut) {
            this.handleShortcutWant(want);
        } else {
            Logger.debug(this.LOG_TAG, 'onCreate() 应用图标转入');
        }
    }

    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, 'onNewWant()');

        if (want.parameters?.params) {
            this.handleFormWant(want);
            // 卡片路由：写进已有那份 storage，再用同一份重载页面
            if (this.storage !== null && this.currentWindowStage !== null) {
                AbilitySetup.applyWindowParams(this.storage, this.params);
                AbilitySetup.loadPage(this.currentWindowStage, this.targetPage, this.storage);
            }
        } else if (want.parameters?.isFromShortcut) {
            this.handleShortcutWant(want);
            // 快捷方式：只写不重载，Index 在 onPageShow 取用
            if (this.storage !== null) AbilitySetup.applyWindowParams(this.storage, this.params);
        } else {
            Logger.debug(this.LOG_TAG, 'onNewWant() 应用图标转入');
        }
    }

    onDestroy(): void {
        Logger.debug(this.LOG_TAG, 'onDestroy()');
    }

    async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
        Logger.debug(this.LOG_TAG, 'onWindowStageCreate()');

        if (this.currentWindowStage === null) this.currentWindowStage = windowStage;

        await this.setColorMode();

        this.storage = AbilitySetup.createWindowStorage(this.params);
        this.params = {};
        AbilitySetup.loadPage(windowStage, this.targetPage, this.storage);
    }

    onWindowStageDestroy(): void {
        Logger.debug(this.LOG_TAG, 'onWindowStageDestroy()');
    }

    onForeground(): void {
        Logger.debug(this.LOG_TAG, 'onForeground()');
    }

    onBackground(): void {
        Logger.debug(this.LOG_TAG, 'onBackground()');
    }

    private handleFormWant(want: Want): void {
        Logger.debug(this.LOG_TAG, '桌面卡片转入');

        const params: Record<string, Object> = JSON.parse(want.parameters?.params as string);

        this.targetPage = params.targetPage as string;

        const formID = params.formID as string;
        if (formID !== undefined && formID.trim() !== '') this.params.formID = formID;
    }

    private handleShortcutWant(want: Want): void {
        Logger.debug(this.LOG_TAG, '长按快捷方式转入');

        const shortcutPath = want?.parameters?.shortCutKey as string;
        if (shortcutPath !== undefined && shortcutPath !== '') this.params.shortcutPath = shortcutPath;
    }

    private async setColorMode(): Promise<void> {
        const ensured: Result<number> = await AppSettingsService.instance().ensureColorMode();
        // 读不到持久化值时用系统默认启动并留一行日志：颜色模式只影响外观，设备数据不受影响
        const persisted: number = ensured.ok && ensured.value !== null
            ? ensured.value : CommonConstants.COLOR_MODE_NOT_SET;
        if (!ensured.ok) Logger.error(this.LOG_TAG, `读取颜色模式失败，本次使用系统默认: ${ensured.error}`);

        applyColorMode(this.context, persisted);
        AppStorageV2.connect(AppSettings, CommonConstants.APP_SETTINGS_STORAGE_KEY,
            () => new AppSettings(persisted as ConfigurationConstant.ColorMode));

        Logger.debug(this.LOG_TAG, `窗口颜色设置: ${persisted}`);
    }
}