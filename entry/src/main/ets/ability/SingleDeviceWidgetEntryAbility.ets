import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';

import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/log/Logger';
import { SingleCardBindingData } from '../common/model/CardBindingData';
import { Device } from '../common/model/Device';
import { CardPublisher } from '../data/CardPublisher';
import { DeviceDao } from '../data/DeviceDao';
import { WakeResult, WakeService } from '../domain/WakeService';
import { vibrate } from '../ui/feedback/Feedback';
import { closeApplication } from '../ui/util/AppExit';
import { resourceText } from '../ui/util/ResourceText';
import { AbilitySetup } from './AbilitySetup';

/**
 * 单设备卡片的执行 Ability。序列固定五步：
 * 取 want → 数据库值校正 → 发布运行中 → 发包 → 发布结果；失败进返回值。
 * 运行序列本身不新增能力（不设超时、不设会话、不保活）。
 */
export default class SingleDeviceWidgetEntryAbility extends UIAbility {
    private LOG_TAG = '[SingleDeviceWidgetEntryAbility]';

    private publisher: CardPublisher = CardPublisher.getInstance();
    private dao: DeviceDao = DeviceDao.getInstance();

    private formID: string = '';
    private deviceID: number = -1;
    private alias: string = '';
    private mac: string = '';
    private address: string = '';
    private port: number = 9;

    async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
        Logger.debug(this.LOG_TAG, 'onCreate()');

        AbilitySetup.initDataLayer(this.context);

        try {
            if (want.parameters && want.parameters.params) {
                const params: Record<string, Object> = JSON.parse(want.parameters.params as string);

                this.formID = params['formID'] as string;
                this.deviceID = params['deviceID'] as number;
                this.alias = params['alias'] as string;
                this.mac = params['mac'] as string;
                this.address = params['address'] as string;
                this.port = params['port'] as number;

                if (!this.formID || !this.mac) {
                    Logger.error(this.LOG_TAG, `onCreate() 参数不完整: formID=${this.formID}, mac=${this.mac}`);
                    return;
                }

                vibrate(CommonConstants.VIBRATE_EFFECT_ID_HARD);

                await this.run();
            } else {
                Logger.warn(this.LOG_TAG, 'onCreate() want 为空');
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `onCreate() 错误, ${err}`);
        } finally {
            await WakeService.instance().release();
            closeApplication(this.LOG_TAG, this.context);
        }
    }

    async onDestroy(): Promise<void> {
        Logger.debug(this.LOG_TAG, 'onDestroy()');
    }

    private async run(): Promise<void> {
        await WakeService.instance().prepare();
        await this.correctFromDB();

        // 运行中：整张卡片数据替换
        const running = this.buildData();
        running.isRunning = true;
        await this.publisher.publishRunSingle(this.formID, running);

        const result: WakeResult = await WakeService.instance().wake(this.toDevice());

        const finished = this.buildData();
        finished.runResult = this.resultText(result);
        finished.isRunning = false;
        const report = await this.publisher.publishRunSingle(this.formID, finished);

        if (report.failed.length > 0) {
            Logger.error(this.LOG_TAG, `运行结果发布失败: ${report.failed.join(',')}`);
        }
    }

    private buildData(): SingleCardBindingData {
        const data = new SingleCardBindingData(this.formID, true);
        data.deviceID = this.deviceID;
        data.alias = this.alias;
        data.mac = this.mac;
        data.address = this.address;
        data.port = this.port;
        return data;
    }

    private toDevice(): Device {
        return new Device(this.deviceID, this.mac, this.alias, this.address, this.port, -1);
    }

    /** 卡片 UI 可能滞后，执行前用数据库值校正 */
    private async correctFromDB(): Promise<void> {
        const device = await this.dao.getByID(this.deviceID);
        if (device === null) return;

        if (device.MAC !== this.mac) {
            Logger.warn(this.LOG_TAG, `DB MAC: ${device.MAC}, 卡片 MAC: ${this.mac}, 不一致，使用 DB MAC`);
            this.mac = device.MAC;
        }

        if (device.Address !== this.address) {
            Logger.warn(this.LOG_TAG, `DB Address: ${device.Address}, 卡片 Address: ${this.address}, 不一致，使用 DB Address`);
            this.address = device.Address;
        }

        if (device.Port !== this.port) {
            Logger.warn(this.LOG_TAG, `DB Port: ${device.Port}, 卡片 Port: ${this.port}, 不一致，使用 DB Port`);
            this.port = device.Port;
        }
    }

    private resultText(result: WakeResult): string {
        if (result.ok) return resourceText($r('app.string.form_run_success'), this.context);
        if (result.kind === 'no-broadcast') return resourceText($r('app.string.no_broadcast_ip'), this.context);
        return resourceText($r('app.string.form_run_failed'), this.context);
    }
}