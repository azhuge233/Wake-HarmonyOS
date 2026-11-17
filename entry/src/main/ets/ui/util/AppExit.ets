import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { Logger } from '../../common/log/Logger';

/** 关闭应用；terminateSelf 需要 UIAbilityContext */
export function closeApplication(logTag: string, context: common.UIAbilityContext): void {
    Logger.info(logTag, '关闭应用');
    context.terminateSelf().catch((err: BusinessError) => {
        Logger.error(logTag, `关闭应用失败, ${err}`);
    });
}