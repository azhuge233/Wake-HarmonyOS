import { Logger } from '../../common/log/Logger';

/** 子页返回时打一行日志；PopInfo 是 ArkUI 的导航类型，只能落在 UI 侧 */
export function logPopResult(logTag: string, popInfo: PopInfo): void {
    Logger.debug(logTag, `从 [${popInfo.info.name}] 页面返回, 携带参数: ${JSON.stringify(popInfo.result)}`);
}