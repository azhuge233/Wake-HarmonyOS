import { AffectedForms } from '../common/model/CardBindingData';
import { Device } from '../common/model/Device';
import { Logger } from '../common/log/Logger';
import { CardBindingService } from '../domain/CardBindingService';
import { DeviceService } from '../domain/DeviceService';
import { WakeResult, WakeService } from '../domain/WakeService';
import { DeviceViewModel } from './DeviceViewModel';

/** 列表加载状态：失败与空列表分开 */
export type LoadState = 'idle' | 'loading' | 'ok' | 'failed';

/** 设备列表页的视图模型：加载、刷新、唤醒、重排、删除。页面只装配 */
@ObservedV2
export class DeviceListViewModel {
    private LOG_TAG = '[DeviceListViewModel]';

    @Trace devices: Array<DeviceViewModel> = [];
    @Trace loadState: LoadState = 'idle';
    @Trace loadError: string = '';
    @Trace broadcastAddress: string = '';
    @Trace cardRefreshError: string = '';

    private deviceService: DeviceService;
    private cards: CardBindingService;
    private wakeService: WakeService;

    constructor(deviceService: DeviceService, cards: CardBindingService, wakeService: WakeService) {
        this.deviceService = deviceService;
        this.cards = cards;
        this.wakeService = wakeService;
    }

    async load(): Promise<void> {
        this.loadState = 'loading';

        const result = await this.deviceService.load();
        if (!result.ok) {
            this.devices = [];
            this.loadError = result.error;
            this.loadState = 'failed';
            return;
        }

        const loaded: Device[] = result.value ?? [];
        this.devices = loaded.map((entry: Device) => {
            const viewModel = new DeviceViewModel();
            viewModel.fromDevice(entry);
            return viewModel;
        });

        this.loadError = '';
        this.loadState = 'ok';
    }

    /** 刷新广播地址并回填要显示的文本片段 */
    async refreshBroadcast(): Promise<void> {
        const state = await this.wakeService.prepare();
        this.broadcastAddress = state.address;
    }

    /** 监听默认网络变化；页面只收回调，监听本身在数据层 */
    watchNetwork(onNetChange: () => void): void {
        this.wakeService.watch(onNetChange);
    }

    unwatchNetwork(): void {
        this.wakeService.unwatch();
    }

    /** 页面退出时释放 socket，下次刷新会懒创建 */
    async releaseSender(): Promise<void> {
        await this.wakeService.release();
    }

    async wake(device: DeviceViewModel): Promise<WakeResult> {
        return this.wakeService.wake(device.toDevice());
    }

    async reorder(from: number, to: number): Promise<boolean> {
        const mutation = await this.deviceService.reorder(from, to);
        if (!mutation.ok) {
            Logger.error(this.LOG_TAG, `重排设备失败: ${mutation.reason}`);
            return false;
        }
        await this.load();
        return true;
    }

    async remove(device: DeviceViewModel): Promise<boolean> {
        const mutation = await this.deviceService.remove(device.toDevice());
        if (!mutation.ok) {
            Logger.error(this.LOG_TAG, `删除设备失败: ${mutation.reason}`);
            return false;
        }

        await this.load();
        await this.publishAffected(mutation.affected ?? AffectedForms.empty());
        return true;
    }

    /** 发布受影响卡片；失败进入 cardRefreshError，由页面提示一次 */
    async publishAffected(affected: AffectedForms): Promise<void> {
        if (affected.isEmpty()) return;

        const report = await this.cards.publish(affected);
        if (report.failed.length > 0) {
            this.cardRefreshError = report.failed.join(',');
        }
    }

    /** 取走一次刷新失败提示；无失败返回空串 */
    consumeCardRefreshError(): string {
        const message = this.cardRefreshError;
        this.cardRefreshError = '';
        return message;
    }
}