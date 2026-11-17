import { common } from '@kit.AbilityKit';
import { KeyboardAvoidMode, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/log/Logger';
import { BackupFileGateway } from '../data/BackupFileGateway';
import { CardBindingStore } from '../data/CardBindingStore';
import { DeviceDao } from '../data/DeviceDao';
import { SettingsStore } from '../data/SettingsStore';

/** 一次性窗口参数：每个 Ability 实例一份 LocalStorage 承载 */
export interface WindowParams {
    formID?: string;
    shortcutPath?: string;
}

/**
 * 入口环的装配助手：数据层初始化、窗口参数通道、页面加载。
 * initDataLayer 收 common.Context：FormExtensionAbility 没有 UI 上下文，
 * 宽类型才让同一段初始化跑在两类宿主里。库与首选项的路径不在这里定——三个 data 单例
 * 各自在 init 内部取应用上下文（设计 §2.1），此处只把宿主上下文分发下去。
 * 文件选择器要 UI 上下文，因此单开一个入口只在 EntryAbility 调。
 */
export class AbilitySetup {
    private static LOG_TAG = '[AbilitySetup]';

    /** 只分发宿主上下文；取应用上下文是三个 data 单例自己的事 */
    static initDataLayer(context: common.Context): void {
        DeviceDao.getInstance().init(context);
        CardBindingStore.getInstance().init(context);
        SettingsStore.getInstance().init(context);
    }

    static initFileGateway(context: common.UIAbilityContext): void {
        BackupFileGateway.getInstance().init(context);
    }

    /** 只在 onWindowStageCreate 调一次 */
    static createWindowStorage(params: WindowParams): LocalStorage {
        const storage = new LocalStorage();
        AbilitySetup.applyWindowParams(storage, params);
        return storage;
    }

    /** 写进本窗口已有的那一份；onNewWant 只能用这个方法 */
    static applyWindowParams(storage: LocalStorage, params: WindowParams): void {
        const formID: string | undefined = params.formID;
        if (formID !== undefined && formID !== '') {
            storage.setOrCreate(CommonConstants.WINDOW_PARAM_FORM_ID, formID);
        }

        const shortcutPath: string | undefined = params.shortcutPath;
        if (shortcutPath !== undefined && shortcutPath !== '') {
            storage.setOrCreate(CommonConstants.WINDOW_PARAM_SHORTCUT_PATH, shortcutPath);
        }
    }

    static loadPage(windowStage: window.WindowStage, page: string, storage: LocalStorage,
        done?: (err: BusinessError) => void): void {
        windowStage.loadContent(page, storage, (err: BusinessError) => {
            try {
                windowStage.getMainWindowSync().getUIContext().setKeyboardAvoidMode(
                    KeyboardAvoidMode.RESIZE_WITH_CARET);
            } catch (keyboardErr) {
                Logger.error(AbilitySetup.LOG_TAG, `设置软键盘避让失败, ${keyboardErr}`);
            }

            if (err && err.code) {
                Logger.error(AbilitySetup.LOG_TAG, `loadContent() 加载 ${page} 失败 ${JSON.stringify(err)}`);
            } else {
                Logger.debug(AbilitySetup.LOG_TAG, `loadContent() 加载 ${page} 成功`);
            }

            if (done !== undefined) done(err);
        });
    }
}