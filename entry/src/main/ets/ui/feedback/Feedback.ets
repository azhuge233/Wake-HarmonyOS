import { BusinessError } from '@kit.BasicServicesKit';
import { vibrator } from '@kit.SensorServiceKit';
import { PromptAction } from '@ohos.arkui.UIContext';

import { Logger } from '../../common/log/Logger';

const LOG_TAG = '[Feedback]';

/** 一次提示。页面不直接调 kit */
export function showToast(promptAction: PromptAction, message: string | Resource): void {
    promptAction.openToast({
        message: message
    }).catch((err: BusinessError) => {
        Logger.error(LOG_TAG, `显示提示失败, ${err}`);
    });
}

/** 设备振动 */
export function vibrate(effectId: string): void {
    try {
        vibrator.isSupportEffect(effectId, (err: BusinessError, state: boolean) => {
            if (err) {
                Logger.error(LOG_TAG, `查询振动效果失败, 代码: ${err.code}, 错误信息: ${err.message}`);
                return;
            }

            if (!state) return;

            try {
                vibrator.startVibration({
                    type: 'preset',
                    effectId: effectId,
                    count: 1,
                    intensity: 100
                }, {
                    usage: 'unknown'
                }, (error: BusinessError) => {
                    if (error) Logger.error(LOG_TAG, `振动触发失败, 代码: ${error.code}, 错误信息: ${error.message}`);
                });
            } catch (error) {
                Logger.error(LOG_TAG, `振动发生未知错误, ${error}`);
            }
        });
    } catch (error) {
        Logger.error(LOG_TAG, `振动发生未知错误, ${error}`);
    }
}