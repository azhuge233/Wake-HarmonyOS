import { common } from '@kit.AbilityKit';

import { Logger } from '../../common/log/Logger';

/**
 * 资源文案。显式收 context、不设默认值，取不到就返回空串——
 * 兜底字符串会把"资源没读到"伪装成一句正常提示。
 */
export function resourceText(resource: Resource, context: common.UIAbilityContext): string {
    try {
        return context.resourceManager.getStringSync(resource.id);
    } catch (err) {
        Logger.error('[ResourceText]', `获取资源字符串失败, ${err}`);
        return '';
    }
}