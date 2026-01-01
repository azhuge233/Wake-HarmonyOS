import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

import { DB } from '../common/utils/DB';
import Logger from '../common/utils/Logger';
import { PM } from '../common/utils/PM';
import CommonConstants from '../common/constants/CommonConstants';

export default class EntryAbility extends UIAbility {
    private LOG_TAG = "[EntryAbility]";

    private targetPage: string = 'pages/Index'; // 指定页面，默认为 Index
    private currentWindowStage: window.WindowStage | null = null;

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, `onCreate()`);

        try {
            this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        } catch (err) {
            Logger.error(this.LOG_TAG, `设置主题颜色失败，${err}`);
        }

        // 持久化存储初始化
        DB.getInstance().init(this.context);
        PM.getInstance().init(this.context);

        if(want?.parameters?.params) this.handleFormWant(want);
        else if (want?.parameters?.isFromShortcut) this.handleShortcutWant(want);
        else Logger.debug(this.LOG_TAG, `onCreate() 应用图标转入`);

        Logger.debug(this.LOG_TAG, `onCreate() targetPage: ${this.targetPage}`);
    }

    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, `onNewWant()`);

        if(want?.parameters?.params) {
            this.handleFormWant(want);
            // 手动进入目标页面
            this.loadContent();
        } else if(want?.parameters?.isFromShortcut) this.handleShortcutWant(want);
        else Logger.debug(this.LOG_TAG, `onNewWant() 应用图标转入`);

        Logger.debug(this.LOG_TAG, `onNewWant() targetPage: ${this.targetPage}`);
    }

    onDestroy(): void {
        Logger.debug(this.LOG_TAG, `onDestroy()`);
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        // Main window is created, set main page for this ability
        Logger.debug(this.LOG_TAG, `onWindowStageCreate()`);

        // 设置当前窗口为传入窗口
        if (this.currentWindowStage === null) this.currentWindowStage = windowStage;

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

    private loadContent(): void {
        if(this.currentWindowStage) {
            this.currentWindowStage.loadContent(this.targetPage, (err) => {
                if (err.code) {
                    Logger.error(this.LOG_TAG, `loadContent() 加载 ${this.targetPage} 失败 ${JSON.stringify(err)}`,);
                    return;
                }
                Logger.debug(this.LOG_TAG, `loadContent() 加载 ${this.targetPage} 成功`);
            });
        } else Logger.warn(this.LOG_TAG, 'loadContent() 当前窗口为空');
    }

    private handleFormWant(want: Want): void {
        Logger.debug(this.LOG_TAG, `桌面卡片转入`);

        const params: Record<string, Object> = JSON.parse(want?.parameters?.params as string);

        this.targetPage = params.targetPage as string; // 目标页面
        const formID = params.formID as string; // formID

        if(formID && formID.trim() !== '') AppStorage.setOrCreate(CommonConstants.AppStorage_KEY_FormID, formID);
    }

    private handleShortcutWant(want: Want): void {
        Logger.debug(this.LOG_TAG, `长按快捷方式转入`);
        if(want?.parameters?.shortCutKey) AppStorage.setOrCreate(CommonConstants.AppStorage_KEY_ShortcutPath, want?.parameters?.shortCutKey as string);
    }
}
