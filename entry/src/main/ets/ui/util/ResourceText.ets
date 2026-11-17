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

/**
 * 带格式化参数取资源文案：args 按序替换资源值里的 %d / %s。
 * args 必填、无默认值——少传即编译不过，占位符不会静默留在提示上。
 * 取不到或格式化失败同样返回空串，日志带资源 id 与实参，能从日志还原那句话。
 */
export function resourceTextFormatted(resource: Resource, context: common.UIAbilityContext,
    args: Array<string | number>): string {
    try {
        return context.resourceManager.getStringSync(resource.id, ...args);
    } catch (err) {
        Logger.error('[ResourceText]', `获取资源字符串失败, id=${resource.id}, args=${args.join(',')}, ${err}`);
        return '';
    }
}