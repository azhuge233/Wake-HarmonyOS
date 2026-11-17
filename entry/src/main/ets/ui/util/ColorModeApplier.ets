import { common, ConfigurationConstant } from '@kit.AbilityKit';

import { Logger } from '../../common/log/Logger';

const LOG_TAG = '[ColorModeApplier]';

/** 把颜色模式应用到应用上下文；app 级语义，不引入窗口级差异 */
export function apply(context: common.UIAbilityContext, mode: number): void {
    try {
        context.getApplicationContext().setColorMode(mode as ConfigurationConstant.ColorMode);
        Logger.debug(LOG_TAG, `已应用颜色模式: ${mode}`);
    } catch (err) {
        Logger.error(LOG_TAG, `应用颜色模式失败: ${err}`);
    }
}