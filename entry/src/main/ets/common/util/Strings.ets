/** 检查字符串是否为空：undefined、null、空串都算空 */
export function isStringNullOrEmpty(str?: string): boolean {
    return str === undefined || str === null || str === '' || str.length === 0;
}