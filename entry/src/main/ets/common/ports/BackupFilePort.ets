/**
 * 文件系统导入导出端口。接口本身无 kit 依赖，故可放叶子层：
 * domain/ 使用它，data/ 实现它；放在 domain/ 会让 data/ 反向 import 领域层。
 */
export interface BackupFilePort {
    /** 让用户选保存位置并写出 JSON；用户取消返回 null */
    saveJson(suffix: string, json: string): Promise<string | null>;

    /** 让用户选一个 JSON 文件；用户取消返回 null */
    pickJson(): Promise<string | null>;

    /** 读取已选文件的文本；读不到返回 null */
    readText(uri: string): Promise<string | null>;
}