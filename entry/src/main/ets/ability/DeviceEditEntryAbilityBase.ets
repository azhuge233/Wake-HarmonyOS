import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { AppStorageV2, window } from '@kit.ArkUI';

import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/log/Logger';
import { Result } from '../common/util/Result';
import { AppSettingsService } from '../domain/AppSettingsService';
import { AppSettings } from '../viewmodel/AppSettings';
import { closeApplication } from '../ui/util/AppExit';
import { apply as applyColorMode } from '../ui/util/ColorModeApplier';
import { AbilitySetup, WindowParams } from './AbilitySetup';

/**
 * 两个卡片绑定 Ability 的共用基类（multiton：每个卡片编辑各占一个实例）。
 * 窗口参数走各自实例的 LocalStorage，双开时 formID 不串。
 */
export default class DeviceEditEntryAbilityBase extends UIAbility {
    protected LOG_TAG: string;
    protected targetPage: string;
    protected deviceTypeLabel: string;

    private currentWindowStage: window.WindowStage | null = null;
    private storage: LocalStorage | null = null;

    private params: WindowParams = {};

    constructor(targetPage: string, logTag: string, deviceTypeLabel: string) {
        super();
        this.targetPage = targetPage;
        this.LOG_TAG = logTag;
        this.deviceTypeLabel = deviceTypeLabel;
    }

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, 'onCreate()');

        AbilitySetup.initDataLayer(this.context);

        this.handleFormWant(want);
    }

    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        Logger.debug(this.LOG_TAG, 'onNewWant()');

        this.handleFormWant(want);
        if (this.storage !== null) AbilitySetup.applyWindowParams(this.storage, this.params);
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
        const formID: string = want.parameters?.formId as string;

        Logger.debug(this.LOG_TAG, `编辑${this.deviceTypeLabel}卡片，卡片 ID = ${formID}`);

        if (formID !== undefined && formID.trim() !== '') {
            this.params.formID = formID;
        } else {
            Logger.warn(this.LOG_TAG, 'handleFormWant() 卡片 ID 无效');
            closeApplication(this.LOG_TAG, this.context);
        }
    }

    private async setColorMode(): Promise<void> {
        const ensured: Result<number> = await AppSettingsService.instance().ensureColorMode();
        // 读不到持久化值时用系统默认启动并留一行日志：颜色模式只影响外观，卡片数据不受影响
        const persisted: number = ensured.ok && ensured.value !== null
            ? ensured.value : CommonConstants.COLOR_MODE_NOT_SET;
        if (!ensured.ok) Logger.error(this.LOG_TAG, `读取颜色模式失败，本次使用系统默认: ${ensured.error}`);

        applyColorMode(this.context, persisted);
        AppStorageV2.connect(AppSettings, CommonConstants.APP_SETTINGS_STORAGE_KEY,
            () => new AppSettings(persisted as ConfigurationConstant.ColorMode));

        Logger.debug(this.LOG_TAG, `窗口颜色设置: ${persisted}`);
    }
}