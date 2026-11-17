import { Logger } from '../common/log/Logger';
import { Device } from '../common/model/Device';
import { CardBindingService } from '../domain/CardBindingService';
import { DeviceService } from '../domain/DeviceService';
import { DeviceViewModel } from './DeviceViewModel';

/** 单设备卡片绑定页的视图模型：加载、选择、绑定 */
@ObservedV2
export class SingleCardBindViewModel {
    private LOG_TAG = '[SingleCardBindViewModel]';

    @Trace devices: Array<DeviceViewModel> = [];
    @Trace selectedID: number | null = null;
    @Trace formID: string = '';
    @Trace bindError: string = '';
    @Trace isUpdating: boolean = false;
    @Trace isLoading: boolean = true;
    @Trace loadError: string = '';

    private deviceService: DeviceService;
    private cards: CardBindingService;

    constructor(deviceService: DeviceService, cards: CardBindingService) {
        this.deviceService = deviceService;
        this.cards = cards;
    }

    async load(): Promise<void> {
        this.isLoading = true;

        const result = await this.deviceService.load();
        if (!result.ok) {
            this.devices = [];
            this.loadError = result.error;
        } else {
            const loaded: Device[] = result.value ?? [];
            this.devices = loaded.map((entry: Device) => {
                const viewModel = new DeviceViewModel();
                viewModel.fromDevice(entry);
                return viewModel;
            });
            this.loadError = '';
        }

        this.isLoading = false;
    }

    setFormID(formID: string): void {
        this.formID = formID;
    }

    toggle(id: number): void {
        this.selectedID = this.selectedID === id ? null : id;
    }

    /** 绑定失败留在当前页：bindError 非空即提示，页面不关闭 */
    async confirm(): Promise<boolean> {
        if (this.selectedID === null || this.isUpdating || this.formID === '') return false;

        const selected = this.devices.find((item: DeviceViewModel) => item.ID === this.selectedID);
        if (!selected) {
            Logger.error(this.LOG_TAG, '未找到选中的设备');
            this.bindError = '未找到选中的设备';
            return false;
        }

        this.isUpdating = true;
        const outcome = await this.cards.bindSingle(this.formID, selected.toDevice());
        this.isUpdating = false;

        if (!outcome.ok) {
            this.bindError = outcome.reason ?? '绑定失败';
            return false;
        }

        if (outcome.published !== null && outcome.published.failed.length > 0) {
            this.bindError = `卡片刷新失败: ${outcome.published.failed.join(',')}`;
            return true;
        }

        this.bindError = '';
        return true;
    }
}