import Device from "./Device";
import Logger from '../common/utils/Logger';
import { DB } from "../common/utils/DB"

export default class DeviceList {
    devices: Array<Device> =[];

    private LOG_TAG = "[Model/DeviceList]";

    private db = DB.getInstance();

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

    async updateDevice(device: Device): Promise<boolean> {
        try {
            const result = await this.db.updateDeviceByID(device);
            Logger.debug(this.LOG_TAG, `设备更新成功, ${result}`);
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `设备更新失败, ${err}`);
            return false;
        }
    }

    async deleteDevice(device: Device): Promise<boolean> {
        try {
            const result = await this.db.deleteDeviceByID(device);
            Logger.debug(this.LOG_TAG, `设备删除成功, ${result}`);
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `设备删除失败, ${err}`);
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

    async clearDevices(): Promise<boolean> {
        try {
            await this.db.clearTable();
            Logger.debug(this.LOG_TAG, `设备列表清除成功`);
            return true;
        } catch (err) {
            Logger.error(this.LOG_TAG, `设备列表清除失败, ${err}`);
            return false;
        }
    }
}