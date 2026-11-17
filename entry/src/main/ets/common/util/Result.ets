/**
 * 用例结果：成功带值，失败带可指认的原因。
 * 失败与"空结果"是两件事，调用方必须能区分（列表加载失败 vs 空列表）。
 */
export class Result<T> {
    readonly ok: boolean;
    readonly value: T | null;
    readonly error: string;

    private constructor(ok: boolean, value: T | null, error: string) {
        this.ok = ok;
        this.value = value;
        this.error = error;
    }

    static success<T>(value: T): Result<T> {
        return new Result<T>(true, value, '');
    }

    static failure<T>(error: string): Result<T> {
        return new Result<T>(false, null, error);
    }
}