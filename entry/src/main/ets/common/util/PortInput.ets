/**
 * 端口输入的判定：字符串进，数字出。无 kit 依赖的叶子工具。
 * 返回值只有两种含义：合法给数字，非法给 null；空串属于合法，返回 DEFAULT_PORT，不返回 null。
 * 另收一条读侧的存量归一（normalizeStored）：缺字段与 `0` 都取 DEFAULT_PORT，只作用于读出来的旧数据，
 * 不放宽用户输入的合法性。
 */
export class PortInput {
    /** 端口留空时入库的值；端口输入的默认值只来自 PortInput.DEFAULT_PORT */
    static readonly DEFAULT_PORT: number = 9;

    /**
     * 存量端口归一：缺字段（JSON 里键缺失读出 `undefined`，旧库读出 `null`）与 `0`（2.8.0 把「留空」存成 `0`）
     * 都返回 DEFAULT_PORT，其余原样。两个读侧入口共用：存量库行（DeviceDao）与旧备份行（BackupService）——
     * 同一条规则只在这里判定。
     */
    static normalizeStored(value: number | null | undefined): number {
        if (value === null || value === undefined) return PortInput.DEFAULT_PORT;
        return value === 0 ? PortInput.DEFAULT_PORT : value;
    }

    /**
     * '' ⇒ PortInput.DEFAULT_PORT（9）；1..65535 的整数 ⇒ 该值；其余 ⇒ null。
     * 只认十进制整数字面量：'8 0'、'1e3'、' 9'、'+9' 一律非法，不做静默归一。
     */
    static parse(text: string): number | null {
        if (text === '') return PortInput.DEFAULT_PORT;
        if (!/^[0-9]+$/.test(text)) return null;

        const value = Number(text);
        if (value < 1 || value > 65535) return null;
        return value;
    }
}