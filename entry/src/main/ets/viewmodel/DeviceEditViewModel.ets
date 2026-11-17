import { Logger } from '../common/log/Logger';
import { checkMac } from '../common/util/MacAddress';
import { PortInput } from '../common/util/PortInput';
import { isStringNullOrEmpty } from '../common/util/Strings';
import { AffectedForms } from '../common/model/CardBindingData';
import { CardBindingService } from '../domain/CardBindingService';
import { DeviceService } from '../domain/DeviceService';
import { DraftIssue } from './DeviceAddViewModel';
import { DeviceViewModel } from './DeviceViewModel';

/** 编辑设备页的视图模型：草稿、校验、保存 */
@ObservedV2
export class DeviceEditViewModel {
    private LOG_TAG = '[DeviceEditViewModel]';

    @Trace draft: DeviceViewModel = new DeviceViewModel();
    /** 端口输入的原始字符：输入原样写入，数字只在保存时由 PortInput.parse 得出 */
    @Trace portText: string = '';
    @Trace validation: DraftIssue = 'none';
    @Trace cardRefreshError: string = '';

    private deviceService: DeviceService;
    private cards: CardBindingService;

    constructor(deviceService: DeviceService, cards: CardBindingService) {
        this.deviceService = deviceService;
        this.cards = cards;
    }

    /** 用列表里的那条设备填充草稿（保存前不影响源对象）；端口输入填成当前值的字符形式 */
    loadFrom(source: DeviceViewModel): void {
        const copy = new DeviceViewModel();
        copy.fromDevice(source.toDevice());
        this.draft = copy;
        this.portText = String(source.Port);
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

    async save(): Promise<boolean> {
        if (this.validate() !== 'none') return false;

        const port: number | null = PortInput.parse(this.portText);
        if (port === null) {
            this.validation = 'port';
            return false;
        }
        // 端口数字在保存这一刻得出：空串在这里归一为默认值，草稿里的 Port 只写这一次
        this.draft.Port = port;

        const mutation = await this.deviceService.update(this.draft.toDevice());
        if (!mutation.ok) {
            Logger.error(this.LOG_TAG, `保存设备失败: ${mutation.reason}`);
            return false;
        }

        const affected = mutation.affected ?? AffectedForms.empty();
        if (!affected.isEmpty()) {
            const report = await this.cards.publish(affected);
            if (report.failed.length > 0) this.cardRefreshError = report.failed.join(',');
        }

        return true;
    }

    consumeCardRefreshError(): string {
        const message = this.cardRefreshError;
        this.cardRefreshError = '';
        return message;
    }
}