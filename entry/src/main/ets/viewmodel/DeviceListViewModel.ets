import { Device } from "../model/Device";
import { DeviceList } from "../model/DeviceList";
import { Logger } from '../common/utils/Logger';
import { DeviceJsonObject } from "../model/JsonObject";
import { DeviceViewModel } from "./DeviceViewModel";
import { PM } from "../common/utils/PM";
import { CommonUtils } from "../common/utils/CommonUtils";
import { formProvider } from "@kit.FormKit";
import { CommonConstants } from "../common/constants/CommonConstants";

@ObservedV2
export class DeviceListViewModel {
    private LOG_TAG = '[DeviceListViewModel]';

    @Trace devices: Array<DeviceViewModel> = [];
    private dataModel: DeviceList;

    private pm: PM;

    constructor(dataModel: DeviceList = new DeviceList([]), pm: PM = PM.getInstance()) {
        this.dataModel = dataModel;
        this.pm = pm;
    }

    async loadDevices() {
        await this.dataModel.loadDevices();

        this.devices = this.dataModel.devices.map(entry => {
            const viewModel = new DeviceViewModel();
            viewModel.fromDevice(entry);
            return viewModel;
        });
    }

    async addDevice(device: Device): Promise<boolean> {
        const success = await this.dataModel.addDevice(device);
        if (success) {
            await this.loadDevices();
            return true;
        }
        return false;
    }

    async updateDevice(device: Device): Promise<boolean> {
        const result = await this.dataModel.updateDevice(device);

        // 更新成功，返回绑定了该设备的所有 formID
        if (result.ok) {
            await this.loadDevices();

            if (result.formIDs) await this.updateForms(result.formIDs);

            return true;
        }
        return false;
    }

    async deleteDevice(device: Device): Promise<boolean> {
        const result = await this.dataModel.deleteDevice(device);
        // 删除成功，返回绑定了该设备的所有 formID
        if (result.ok) {
            // 删除后刷新 device 和 dataModel 内的 device
            await this.loadDevices();
            // 刷新后再更新列表内剩余条目的位置下标
            // 要注意执行顺序，如果在刷新前执行，位置下标不变
            // 因为 device 和 dataModel 内的 device 未更新
            await this.updateDevicesOrder();

            if (result.formIDs) await this.updateForms(result.formIDs);

            return true;
        }
        return false;
    }

    async clearDevices(): Promise<boolean> {
        const result = await this.dataModel.clearDevices();
        if (result.ok) {
            await this.loadDevices();

            if (result.formIDs) await this.updateForms(result.formIDs);

            return true;
        }
        return false;
    }

    async toDeviceJsonObjectList(): Promise<Array<DeviceJsonObject>> {
        await this.loadDevices();
        return this.devices.map(entry => entry.toJsonObject());
    }

    async reorderDevices(fromIndex: number, toIndex: number): Promise<boolean> {
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0 ||
            fromIndex >= this.devices.length || toIndex >= this.devices.length) {
            return false;
        }

        // 创建当前视图模型数组的副本
        const currentDevices = [...this.devices];

        const movedItem = currentDevices.splice(fromIndex, 1);
        currentDevices.splice(toIndex, 0, movedItem[0]);

        // 批量更新数据库的数据
        const updatePayload = currentDevices.map((entry, index) => [entry.ID, index]);
        const success = await this.dataModel.updateDevicesOrder(updatePayload);

        if(success) {
            await this.loadDevices();
            return true;
        }
        return false;
    }

    private async updateDevicesOrder(): Promise<boolean> {
        // 提取当前列表的 [id - 位置] 下标映射（长度为2的数组）
        const updatePayload = this.devices.map((entry, index) => [entry.ID, index]);
        // 更新到数据库
        const success = await this.dataModel.updateDevicesOrder(updatePayload);

        if(success) {
            await this.loadDevices();
            return true;
        }
        return false;
    }

    private async updateForms(formIDMap: Map<string, string[]>): Promise<boolean> {
        const singleFormIDs = formIDMap.get(CommonConstants.FORM_RESULT_MAP_KEY_SINGLE) ?? [];
        const multipleFormIDs = formIDMap.get(CommonConstants.FORM_RESULT_MAP_KEY_MULTIPLE) ?? [];

        if(singleFormIDs.length === 0 && multipleFormIDs.length === 0) return true;

        let allSucceeded = true;

        // 单卡逐张更新；某一张失败不影响其余卡片
        for(const formID of singleFormIDs) {
            try {
                const formData = await this.pm.getFormDataByIDSingle(formID);

                // 如果 formData 不为空，生成新 FormBindingData 更新卡片 UI
                // 如果 formData 为空，说明该卡片已解绑，生成空 FormBindingData
                const formInfo = CommonUtils.createSingleDeviceFormBindingData(formData ?? formID);
                await formProvider.updateForm(formID, formInfo);

                Logger.debug(this.LOG_TAG, `已更新单设备卡片, formID = ${formID}`);
            } catch (err) {
                allSucceeded = false;
                Logger.error(this.LOG_TAG, `更新单设备卡片失败, formID = ${formID}, ${err}`);
            }
        }

        // 多卡逐张更新；某一张失败不影响其余卡片
        for(const formID of multipleFormIDs) {
            try {
                const formData = await this.pm.getFormDataByIDMultiple(formID);

                const formInfo = CommonUtils.createMultipleDevicesFormBindingData(formData ?? formID);
                await formProvider.updateForm(formID, formInfo);

                Logger.debug(this.LOG_TAG, `已更新多设备卡片, formID = ${formID}`);
            } catch (err) {
                allSucceeded = false;
                Logger.error(this.LOG_TAG, `更新多设备卡片失败, formID = ${formID}, ${err}`);
            }
        }

        return allSucceeded;
    }
}