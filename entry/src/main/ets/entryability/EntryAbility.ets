import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DB } from '../common/utils/DB';
import NET from '../common/utils/NET';


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
    private LOG_PREFIX = "[Wake]";
    private LOG_FORMAT = '%{public}s -> %{public}s';
    private LOG_TAG = "[EntryAbility]";

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        try {
            this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        } catch (err) {
            hilog.error(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, `Failed to set colorMode. Cause: ${JSON.stringify(err)}`);
        }

        hilog.info(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Ability onCreate');

        // 数据库
        DB.getInstance().initDB(this.context);

        // 网络
        NET.init();

        // 应用冷启动，添加快捷方式
        if(want?.parameters?.isFromShortcut ?? false) AppStorage.setOrCreate('want', want);
    }

    // 应用启动后，由后台转前台，添加快捷方式
    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        if(want?.parameters?.isFromShortcut ?? false) AppStorage.setOrCreate('want', want);
        hilog.debug(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Ability onNewWant');
    }

    onDestroy(): void {
        hilog.info(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Ability onDestroy');
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        // Main window is created, set main page for this ability
        hilog.info(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Ability onWindowStageCreate');

        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                hilog.error(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, `Failed to load the content, ${JSON.stringify(err)}`);
                return;
            }

            hilog.info(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Succeeded in loading the content.');
        });
    }

    onWindowStageDestroy(): void {
        // Main window is destroyed, release UI related resources
        hilog.info(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Ability onWindowStageDestroy');
    }

    onForeground(): void {
        // Ability has brought to foreground
        hilog.info(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Ability onForeground');
    }

    onBackground(): void {
        // Ability has back to background
        hilog.info(DOMAIN, this.LOG_PREFIX, this.LOG_FORMAT, this.LOG_TAG, 'Ability onBackground');
    }
}
