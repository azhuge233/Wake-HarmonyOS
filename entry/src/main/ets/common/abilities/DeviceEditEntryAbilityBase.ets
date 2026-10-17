import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from "@kit.AbilityKit";
import { AppStorageV2, window, KeyboardAvoidMode } from '@kit.ArkUI';

import { DB } from '../../common/utils/DB';
import { Logger } from '../../common/utils/Logger';
import { PM } from '../../common/utils/PM';
import { CommonConstants } from '../../common/constants/CommonConstants';
import { AppSettingsManager } from '../../common/utils/AppSettingsManager';
import { AppSettings } from '../../model/AppSettings';
import { CommonUtils } from '../../common/utils/CommonUtils';

export default class DeviceEditEntryAbilityBase extends UIAbility {
    protected LOG_TAG: string;
    protected targetPage: string;
    protected deviceTypeLabel: string;

    private currentWindowStage: window.WindowStage | null = null;

    private db = DB.getInstance();
    private pm = PM.getInstance();
    private asm = AppSettingsManager.getInstance();

    constructor(targetPage: string, logTag: string, deviceTypeLabel: string) {
        super();
        this.targetPage = targetPage;
        this.LOG_TAG = logTag;
        this.deviceTypeLabel = deviceTypeLabel;
    }

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, `onCreate()`);

        this.init();

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
        Logger.debug(this.LOG_TAG, `onWindowStageCreate()`);

        if (this.currentWindowStage === null) this.currentWindowStage = windowStage;

        await this.setColorMode();

        this.loadContent();
    }

    onWindowStageDestroy(): void {
        Logger.debug(this.LOG_TAG, `onWindowStageDestroy()`);
    }

    onForeground(): void {
        Logger.debug(this.LOG_TAG, `onForeground()`);
    }

    onBackground(): void {
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

        Logger.debug(this.LOG_TAG, `编辑${this.deviceTypeLabel}卡片，卡片 ID = ${formID}`);

        if(formID && formID.trim() !== '') AppStorage.setOrCreate(CommonConstants.APP_STORAGE_KEY_FORM_ID, formID);
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

            AppStorageV2.connect(AppSettings, CommonConstants.APP_STORAGE_KEY_APP_SETTINGS, () => appSettings);

            Logger.debug(this.LOG_TAG, `setColorMode() 窗口颜色设置: ${appSettings.colorMode}`)
        } catch (err) {
            Logger.error(this.LOG_TAG, `setColorMode() 设置窗口颜色模式失败, ${err}`);
        }
    }
}
