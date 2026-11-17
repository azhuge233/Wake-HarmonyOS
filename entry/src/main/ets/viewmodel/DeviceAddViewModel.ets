import { Logger } from '../common/log/Logger';
import { checkMac } from '../common/util/MacAddress';
import { PortInput } from '../common/util/PortInput';
import { isStringNullOrEmpty } from '../common/util/Strings';
import { NewDeviceRecord } from '../common/model/Device';
import { DeviceService } from '../domain/DeviceService';
import { NeighborCandidate, NeighborService } from '../domain/NeighborService';
import { DeviceViewModel } from './DeviceViewModel';

/** 输入校验结果；页面据此决定提示文案与焦点目标 */
export type DraftIssue = 'none' | 'empty' | 'port' | 'mac-short' | 'mac-format';

/** 新增设备页的视图模型：草稿、邻居表、校验 */
@ObservedV2
export class DeviceAddViewModel {
    private LOG_TAG = '[DeviceAddViewModel]';

    @Trace draft: DeviceViewModel = new DeviceViewModel();
    /** 端口输入的原始字符：输入原样写入，数字只在保存时由 PortInput.parse 得出 */
    @Trace portText: string = '';
    @Trace neighbors: Array<NeighborCandidate> = [];
    @Trace neighborHint: string = '';
    @Trace validation: DraftIssue = 'none';
    @Trace isLoadingNeighbors: boolean = false;
    @Trace isNeighborPermissionDenied: boolean = false;

    private deviceService: DeviceService;
    private neighborService: NeighborService;

    constructor(deviceService: DeviceService, neighborService: NeighborService) {
        this.deviceService = deviceService;
        this.neighborService = neighborService;
    }

    validate(): DraftIssue {
        const mac = this.draft.MAC.trim();
        const alias = this.draft.Alias.trim();

        if (isStringNullOrEmpty(mac) || isStringNullOrEmpty(alias)) {
            this.validation = 'empty';
            return this.validation;
        }

        if (PortInput.parse(this.portText) === null) {
            this.validation = 'port';
            return this.validation;
        }

        const macIssue = checkMac(mac);
        if (macIssue === 'too-short') {
            this.validation = 'mac-short';
            return this.validation;
        }
        if (macIssue === 'format') {
            this.validation = 'mac-format';
            return this.validation;
        }

        this.validation = 'none';
        return this.validation;
    }

    /** 手工添加：校验通过后写入；端口数字在保存这一刻得出 */
    async add(): Promise<boolean> {
        if (this.validate() !== 'none') return false;

        const port: number | null = PortInput.parse(this.portText);
        if (port === null) {
            this.validation = 'port';
            return false;
        }

        const current = this.draft;
        return this.addWith(current.MAC.trim(), current.Alias.trim(), current.Address.trim(), port);
    }

    async addWith(mac: string, alias: string, address: string, port: number): Promise<boolean> {
        const record: NewDeviceRecord = { mac: mac, alias: alias, address: address, port: port, orderIndex: 0 };
        const mutation = await this.deviceService.add(record);

        if (!mutation.ok) {
            Logger.error(this.LOG_TAG, `添加设备失败: ${mutation.reason}`);
            return false;
        }

        this.resetDraft();
        return true;
    }

    async loadNeighbors(): Promise<void> {
        this.isLoadingNeighbors = true;

        const result = await this.neighborService.query();
        this.isNeighborPermissionDenied = result.permissionDenied;
        this.neighbors = result.items;
        this.neighborHint = result.permissionDenied ? 'permission-denied' : '';

        this.isLoadingNeighbors = false;
    }

    /** 已添加的邻居从列表里移除 */
    removeNeighbor(ip: string, mac: string): void {
        const index = this.neighbors.findIndex((item: NeighborCandidate) => item.mac === mac && item.ip === ip);
        if (index !== -1) this.neighbors.splice(index, 1);
    }

    resetDraft(): void {
        this.draft = new DeviceViewModel();
        this.portText = '';
    }
}