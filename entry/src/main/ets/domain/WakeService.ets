import { AddressResolver, ResolvedAddress } from '../data/AddressResolver';
import { BroadcastState, WakeSender } from '../data/WakeSender';

import { Logger } from '../common/log/Logger';
import { Device } from '../common/model/Device';

/** 三类穷尽出口，不设第四类兜底 */
export type WakeFailure = 'no-broadcast' | 'resolve-empty' | 'socket';

/**
 * 唤醒结果。用类而不是对象字面量联合类型：ArkTS 不接受对象字面量做类型声明。
 * ok 为真时 kind 为 null；失败时 kind 必填、detail 供 UI 拼提示。
 */
export class WakeResult {
    readonly ok: boolean;
    readonly kind: WakeFailure | null;
    readonly detail: string;

    constructor(ok: boolean, kind: WakeFailure | null, detail: string) {
        this.ok = ok;
        this.kind = kind;
        this.detail = detail;
    }

    static success(): WakeResult {
        return new WakeResult(true, null, '');
    }

    static failure(kind: WakeFailure, detail: string): WakeResult {
        return new WakeResult(false, kind, detail);
    }
}

/**
 * 唤醒用例。文案不进领域层：UI 依 kind 取字符串资源。
 * 没有广播地址 ⇒ no-broadcast；解析成功但结果为空 ⇒ resolve-empty；socket 未就绪或发送抛错 ⇒ socket。
 * 网络监听也是平台能力，由数据层承接；本服务只把它转给视图模型，ui/ 因此不必 import data/。
 */
export class WakeService {
    private LOG_TAG = '[WakeService]';

    private static shared: WakeService | null = null;

    private sender: WakeSender;
    private resolver: AddressResolver;

    constructor(sender: WakeSender, resolver: AddressResolver) {
        this.sender = sender;
        this.resolver = resolver;
    }

    static instance(): WakeService {
        if (!WakeService.shared) {
            WakeService.shared = new WakeService(WakeSender.getInstance(), new AddressResolver());
        }
        return WakeService.shared;
    }

    async prepare(): Promise<BroadcastState> {
        return this.sender.refreshBroadcast();
    }

    /** 默认网络可用/能力变化/丢失时回调 */
    watch(onNetChange: () => void): void {
        this.sender.watch(onNetChange);
    }

    unwatch(): void {
        this.sender.unwatch();
    }

    async wake(device: Device): Promise<WakeResult> {
        const targetAddress = (device.Address ?? '').trim();
        let target: ResolvedAddress | null = null;

        if (targetAddress === '') {
            const state = await this.prepare();
            if (!state.available) {
                return WakeResult.failure('no-broadcast', '当前没有可用的广播地址');
            }
        } else {
            target = await this.resolver.resolve(targetAddress);
            if (target === null) {
                return WakeResult.failure('resolve-empty', `解析 ${targetAddress} 的结果为空`);
            }
        }

        try {
            const sent = await this.sender.send(device.MAC, target, device.Port);
            if (!sent) return WakeResult.failure('socket', '魔法包未发出');
            return WakeResult.success();
        } catch (err) {
            Logger.error(this.LOG_TAG, `发送魔法包失败, ${err}`);
            return WakeResult.failure('socket', `${err}`);
        }
    }

    async release(): Promise<void> {
        await this.sender.close();
    }
}