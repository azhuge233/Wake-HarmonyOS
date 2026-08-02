import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { formProvider } from '@kit.FormKit';

import CommonUtils from '../../common/utils/CommonUtils';
import Logger from '../../common/utils/Logger';
import NET from '../../common/utils/NET';
import { DB } from '../../common/utils/DB';
import MultipleDevicesFormData from '../model/MultipleDevicesFormData';
import CommonConstants from '../../common/constants/CommonConstants';
import WidgetDevice from '../model/WidgetDevice';

export default class MultipleDevicesWidgetEntryAbility extends UIAbility {
    private LOG_TAG = "[MultipleDevicesWidgetEntryAbility]";

    private db = DB.getInstance();
    private net = new NET();

    private formID: string = '';
    private deviceID: number = -1;
    private mac: string = '';
    private address: string = '';
    private port: number = 9;
    private deviceList: Array<WidgetDevice> = [];

    // 如果UIAbility启动，在收到call事件后会触发onCreate生命周期回调
    async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
        Logger.debug(this.LOG_TAG, `onCreate()`);

        // Logger.warn(this.LOG_TAG, JSON.stringify(want));

        await this.init();

        try {
            // 直接通过 want 获取 call 事件参数
            if (want.parameters && want.parameters.params) {
                const params: Record<string, Object> = JSON.parse(want.parameters.params as string);

                this.formID = params['formID'] as string;
                this.deviceID = params['deviceID'] as number;
                this.mac = params['mac'] as string;
                this.address = params['address'] as string;
                this.port = params['port'] as number;
                this.deviceList = params['deviceList'] as Array<WidgetDevice>;

                Logger.debug(this.LOG_TAG, `onCreate() 从 call 事件获得参数: ${this.formID}, ${this.deviceID}, ${this.mac}, ${this.address}, ${this.port}, ${this.deviceList}`);

                CommonUtils.vibrate(CommonConstants.Vibrate_Effect_ID_HARD);

                // 从数据库更新待执行的设备信息
                // 防止执行时卡片UI没有及时更新
                // 对比卡片信息与数据库信息，不一致时使用数据库信息
                await this.updateCommandFromDB();

                // 向卡片发送正在运行参数
                await this.sendFormRunning();

                const result = await this.sendPacket();
                await this.showResult(result);
            } else Logger.warn(this.LOG_TAG, `onCreate() want 为空`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `onCreate() 错误, ${err}`);
        } finally {
            CommonUtils.closeApplication(this.LOG_TAG, this.context);
        }
    }

    async onDestroy(): Promise<void> {
        Logger.debug(this.LOG_TAG, `onDestroy()`);
    }

    private async init() {
        this.db.init(this.context.getApplicationContext());
        await this.net.refresh();
    }

    private getNewFormData(): MultipleDevicesFormData {
        const formData = new MultipleDevicesFormData(this.formID, true);

        formData.deviceList = this.deviceList;

        return formData;
    }

    private async sendFormRunning() {
        const formData = this.getNewFormData();
        formData.isRunning = true;

        const formInfo = CommonUtils.createMultipleDevicesFormBindingData(formData);
        try {
            await formProvider.updateForm(this.formID, formInfo);
        } catch (err) {
            Logger.error(this.LOG_TAG, `sendFormRunning() 失败, ${err}`);
        }
    }

    private async updateCommandFromDB(): Promise<void> {
        const device = await this.db.getDeviceByID(this.deviceID);
        if(device) {
            const dbMAC = device.MAC;
            const dbAddress = device.Address;
            const dbPort = device.Port;

            if(dbMAC !== this.mac) {
                Logger.warn(this.LOG_TAG, `DB MAC: ${dbMAC}, 卡片 MAC: ${this.mac}, 不一致，使用 DB MAC`);
                this.mac = dbMAC;
            }

            if(dbAddress !== this.address) {
                Logger.warn(this.LOG_TAG, `DB Address: ${dbAddress}, 卡片 Address: ${this.address}, 不一致，使用 DB Address`);
                this.address = dbAddress;
            }

            if(dbPort !== this.port) {
                Logger.warn(this.LOG_TAG, `DB Port: ${dbPort}, 卡片 Port: ${this.port}, 不一致，使用 DB Port`);
                this.port = dbPort;
            }
        }
    }

    private async sendPacket(): Promise<string> {
        Logger.debug(this.LOG_TAG, `sendPacket() 执行指令: ${this.mac}`);

        try {
            const result = await this.net.send(this.mac, this.address, this.port);

            if(typeof(result) === 'boolean') return CommonUtils.getStringFromResource(this.context, $r("app.string.form_run_success"));
            else if(typeof(result) === 'string') return result;
            else return CommonUtils.getStringFromResource(this.context, result);
        } catch (err) {
            Logger.error(this.LOG_TAG, `sendPacket() 指令 ${this.mac} 执行错误, ${err}`);
            return CommonUtils.getStringFromResource(this.context, $r("app.string.form_run_failed"));
        }
    }

    private async showResult(result: string): Promise<void> {
        try {
            const formData = this.getNewFormData();

            formData.runResult = result; // 显示执行结果
            formData.isRunning = false; // 取消卡片正在运行状态
            const formInfo = CommonUtils.createMultipleDevicesFormBindingData(formData);
            await formProvider.updateForm(this.formID, formInfo); // 更新

            // await formProvider.setFormNextRefreshTime(this.formID, 5);
            Logger.debug(this.LOG_TAG, `showResult() 已显示执行结果`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `showResult() 错误, ${err as BusinessError}`);
        }
    }
}