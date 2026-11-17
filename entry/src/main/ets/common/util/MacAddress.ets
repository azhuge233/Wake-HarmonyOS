import { StyleConstants } from '../constants/StyleConstants';

/** MAC 校验结果；文案由 UI 依本结果取资源，叶子层不产出 Resource */
export type MacIssue = 'none' | 'too-short' | 'format';

/**
 * 检查 MAC 合法性，分隔符仅支持 ':' 和 '-'。
 * 合法返回 'none'。
 */
export function checkMac(mac: string): MacIssue {
    if (mac.length < StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH) {
        return 'too-short';
    }

    const regex = /^(?:[0-9A-Fa-f]{2}([-:]))(?:[0-9A-Fa-f]{2}\1){4}[0-9A-Fa-f]{2}$/;

    if (!regex.test(mac)) {
        return 'format';
    }

    return 'none';
}