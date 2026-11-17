import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

import { Logger } from '../../common/log/Logger';

/**
 * 打开外链的唯一实现：Help 与 About 共用。
 * 成功记 info、失败记 error，不返回错误、不弹提示；日志标签与上下文由调用方给，模块内不写死标签。
 */
export function openInSystemBrowser(logTag: string, context: common.UIAbilityContext, url: string): void {
    const want: Want = {
        'action': 'ohos.want.action.viewData',
        'entities': ['entity.system.browsable'],
        'uri': url
    };

    context.startAbility(want)
        .then(() => {
            Logger.info(logTag, `成功在系统浏览器中打开: ${url}`);
        })
        .catch((err: BusinessError) => {
            Logger.error(logTag, `打开系统浏览器失败: ${JSON.stringify(err)}`);
        });
}
