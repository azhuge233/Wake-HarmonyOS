import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from "@kit.AbilityKit";
import { AppStorageV2, window, KeyboardAvoidMode } from '@kit.ArkUI';

import { DB } from '../../common/utils/DB';
import Logger from '../../common/utils/Logger';
import { PM } from '../../common/utils/PM';
import CommonConstants from '../../common/constants/CommonConstants';
import { AppSettingsManager } from '../../common/utils/AppSettingsManager';
import { AppSettings } from '../../model/AppSettings';
import CommonUtils from "../../common/utils/CommonUtils";

export default class MultipleDevicesEditEntryAbility extends UIAbility {
    private LOG_TAG = "[MultipleDevicesEditEntryAbility]";

    private targetPage: string = 'pages/MultipleDevicesFormEdit';
    private currentWindowStage: window.WindowStage | null = null;

    private db = DB.getInstance();
    private pm = PM.getInstance();
    private asm = AppSettingsManager.getInstance();

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, `onCreate()`);

        this.init();

        // Logger.warn(this.LOG_TAG, `${JSON.stringify(want.parameters)}`);

        this.handleFormWant(want);

        Logger.debug(this.LOG_TAG, `onCreate() targetPage: ${this.targetPage}`);
    }

    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, `onNewWant()`);

        this.handleFormWant(want);

        Logger.debug(this.LOG_TAG, `onNewWant() targetPage: ${this.targetPage}`);
    }

    onDestroy(): void {
        Logger.debug(this.LOG_TAG, `onDestroy()`);
    }

    async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
        // Main window is created, set main page for this ability
        Logger.debug(this.LOG_TAG, `onWindowStageCreate()`);

        // 设置当前窗口为传入窗口
        if (this.currentWindowStage === null) this.currentWindowStage = windowStage;

        // 从首选项加载并设置颜色模式
        await this.setColorMode();

        // 加载页面
        this.loadContent();
    }

    onWindowStageDestroy(): void {
        // Main window is destroyed, release UI related resources
        Logger.debug(this.LOG_TAG, `onWindowStageDestroy()`);
    }

    onForeground(): void {
        // Ability has brought to foreground
        Logger.debug(this.LOG_TAG, `onForeground()`);
    }

    onBackground(): void {
        // Ability has back to background
        Logger.debug(this.LOG_TAG, `onBackground()`);
    }

    private init() {
        const appContext = this.context.getApplicationContext();
        this.asm.init(appContext);
        this.db.init(appContext);
        this.pm.init(appContext);
    }

    private handleFormWant(want: Want): void {
        const formID: string = want.parameters?.formId as string;

        Logger.debug(this.LOG_TAG, `编辑多设备卡片，卡片 ID = ${formID}`);

        if(formID && formID.trim() !== '') AppStorage.setOrCreate(CommonConstants.AppStorage_KEY_FormID, formID);
        else {
            Logger.warn(this.LOG_TAG, 'handleFormWant() 卡片 ID 无效');
            CommonUtils.closeApplication(this.LOG_TAG, this.context);
        }
    }

    private loadContent(): void {
        if(this.currentWindowStage) {
            this.currentWindowStage.loadContent(this.targetPage, (err) => {
                try {
                    this.currentWindowStage?.getMainWindowSync().getUIContext().setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE_WITH_CARET);
                } catch (err) {
                    Logger.error(this.LOG_TAG, `设置软键盘避让失败, ${err}`);
                }

                if (err.code) {
                    Logger.error(this.LOG_TAG, `loadContent() 加载 ${this.targetPage} 失败 ${JSON.stringify(err)}`);
                    return;
                }
                Logger.debug(this.LOG_TAG, `loadContent() 加载 ${this.targetPage} 成功`);
            });
        } else Logger.warn(this.LOG_TAG, 'loadContent() 当前窗口为空');
    }

    private async setColorMode(): Promise<void> {
        try {
            let appSettings = await this.asm.get();

            if(!appSettings) {
                appSettings = new AppSettings(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
                await this.asm.set(appSettings);
            }

            this.context.getApplicationContext().setColorMode(appSettings.colorMode);

            AppStorageV2.connect(AppSettings, CommonConstants.AppStorage_KEY_AppSettings, () => appSettings);

            Logger.debug(this.LOG_TAG, `setColorMode() 窗口颜色设置: ${appSettings.colorMode}`)
        } catch (err) {
            Logger.error(this.LOG_TAG, `setColorMode() 设置窗口颜色模式失败, ${err}`);
        }
    }
}