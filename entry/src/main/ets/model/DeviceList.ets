import Device from "./Device";
import Logger from '../common/utils/Logger';
import { DB } from "../common/utils/DB"
import { PM } from "../common/utils/PM";

export default class DeviceList {
    devices: Array<Device> =[];

    private LOG_TAG = "[Model/DeviceList]";

    private db = DB.getInstance();
    private pm = PM.getInstance();

    constructor(devices: Array<Device>) {
        this.devices = devices;
    }

    async loadDevices(): Promise<void> {
        try {
            let result = await this.db.getDevices();
            if(result === undefined) throw new Error("指令列表 undefined");
            else this.devices = result;
        } catch (err) {
            Logger.error(this.LOG_TAG, `加载列表失败, ${err}`);
        }
    }

    async addDevice(device: Device): Promise<boolean> {
        try {
            let newOrderIndex = 0;
            if (this.devices.length > 0) {
                const maxOrderIndex = Math.max(...this.devices.map(entry => entry.OrderIndex));
                newOrderIndex = maxOrderIndex + 1;
            }

            device.OrderIndex = newOrderIndex;

            const result = await this.db.addDevice(device);
            Logger.debug(this.LOG_TAG, `新命令添加成功，ID: ${result}`);
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `添加命令失败, ${err}`);
            return false;
        }
    }

    // 更新成功返回更新 entry 对应的所有 formID
    // 只有更新失败返回布尔值
    async updateDevice(device: Device): Promise<boolean | string[]> {
        try {
            const result = await this.db.updateDeviceByID(device);
            Logger.debug(this.LOG_TAG, `设备更新成功, ${result}`);

            const updatedFormIDs = await this.updateAllFormBelongsToDevice(device);

            return updatedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `设备更新失败, ${err}`);
            return false;
        }
    }

    // 删除成功返回删除 entry 对应的所有 formID
    // 只有删除失败返回布尔值
    async deleteDevice(device: Device): Promise<boolean | string[]> {
        try {
            const result = await this.db.deleteDeviceByID(device);
            Logger.debug(this.LOG_TAG, `设备删除成功, ${result}`);

            const removedFormIDs = await this.removeAllFormBelongsToDeviceID(device.ID);

            return removedFormIDs;
        } catch (err) {
            Logger.error(this.LOG_TAG, `设备删除失败, ${err}`);
            return false;
        }
    }

    async clearDevices(): Promise<boolean | string[]> {
        try {
            await this.db.clearTable();
            Logger.debug(this.LOG_TAG, `设备列表清除成功`);

            // 获取全部卡片 formID，供 ViewModel 清空绑定
            const allBindings = await this.pm.getAllCardBindingsSingle();
            const allFormIDs = allBindings.map(binding => binding.formID);

            // 清空卡片绑定
            const success = await this.pm.clearAllBindings();
            if(success) {
                Logger.debug(this.LOG_TAG, `指令绑定已清空`);
                return allFormIDs; // 成功清除则返回所有 formID
            } else {
                Logger.warn(this.LOG_TAG, `指令绑定清空失败`);
                return false;
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `设备列表清除失败, ${err}`);
            return false;
        }
    }

    async updateDevicesOrder(reorderedDevices: Array<Array<number>>): Promise<boolean> {
        try {
            await this.db.batchUpdateOrderIndices(reorderedDevices);
            Logger.debug(this.LOG_TAG, `顺序更新成功，共更新 ${reorderedDevices.length} 个设备`);
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `设备顺序更新失败: ${err}`);
            return false;
        }
    }

    /*
     * 以下为桌面卡片(Form)相关
     * 仅更改持久化存储，不刷新卡片 UI
     * 卡片 UI 在 ViewModel 刷新
     */
    private async updateAllFormBelongsToDevice(device: Device): Promise<string[]> {
        const updatedFormIDs = await this.pm.updateByDeviceSingle(device);
        Logger.debug(this.LOG_TAG, `已更新 ${updatedFormIDs.length} 个相关卡片`);
        return updatedFormIDs;
    }

    private async removeAllFormBelongsToDeviceID(deviceID: number): Promise<string[]> {
        const removedFormIDs = await this.pm.removeBindingsByDeviceIdSingle(deviceID);
        Logger.debug(this.LOG_TAG, `已清除 ${removedFormIDs.length} 个相关卡片`);
        return removedFormIDs;
    }
}