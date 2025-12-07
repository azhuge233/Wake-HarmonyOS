import Device from "../model/Device";
import DeviceList from "../model/DeviceList";
import { DeviceJsonObject } from "../model/JsonObject";
import { DeviceViewModel } from "./DeviceViewModel";

@ObservedV2
export default class DeviceListViewModel {
    @Trace devices: Array<DeviceViewModel> = [];
    private dataModel: DeviceList = new DeviceList([]);

    async loadDevices() {
        await this.dataModel.loadDevices();

        this.devices = this.dataModel.devices.map(entry => {
            const viewModel = new DeviceViewModel();
            viewModel.updateDevice(entry);
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
        const success = await this.dataModel.updateDevice(device);
        if(success) {
            await this.loadDevices();
            return true;
        }
        return false;
    }

    async deleteDevice(device: Device): Promise<boolean> {
        const success = await this.dataModel.deleteDevice(device);
        if(success) {
            // 删除后刷新 commandEntries 和 dataModel 内的 commandEntries
            await this.loadDevices();
            // 刷新后再更新列表内剩余条目的位置下标
            // 要注意执行顺序，如果在刷新前执行，位置下标不变
            // 因为 commandEntries 和 dataModel 内的 commandEntries 未更新
            await this.updateDevicesOrder();
            return true;
        }
        return false;
    }

    async clearDevices(): Promise<boolean> {
        const success = await this.dataModel.clearDevices();
        if(success) {
            await this.loadDevices();
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

        // 重新分配连续的 orderIndex
        const reorderedDevicesWithNewIndex = currentDevices.map((entry, index) => {
            entry.OrderIndex = index;
            return entry;
        });

        // 批量更新数据库的数据
        const updatePayload = reorderedDevicesWithNewIndex.map((entry, index) => [entry.ID, index]);
        const success = await this.dataModel.updateDevicesOrder(updatePayload);

        if(success) {
            await this.loadDevices();
            return true;
        }
        return false;
    }

    private async updateDevicesOrder(): Promise<boolean> {
        // 重新设置当前列表条目的位置下标，生成新的列表
        const reorderedDevicesWithNewIndex = this.devices.map((entry, index) => {
            entry.OrderIndex = index;
            return entry;
        });

        // 提取新列表的 [id - 位置] 下标映射（长度为2的数组）
        const updatePayload = reorderedDevicesWithNewIndex.map((entry, index) => [entry.ID, index]);
        // 更新到数据库
        const success = await this.dataModel.updateDevicesOrder(updatePayload);

        if(success) {
            await this.loadDevices();
            return true;
        }
        return false;
    }
}