import { Device } from '../common/model/Device';
import { DeviceJsonObject } from '../common/model/DeviceJsonObject';
import { PortInput } from '../common/util/PortInput';

/** 一屏内一条设备的可观察状态 */
@ObservedV2
export class DeviceViewModel {
    @Trace ID: number = -1;
    @Trace MAC: string = '';
    @Trace Alias: string = '';
    @Trace Address: string = '';
    @Trace Port: number = PortInput.DEFAULT_PORT;
    @Trace OrderIndex: number = -1;

    fromDevice(device: Device): void {
        this.ID = device.ID;
        this.MAC = device.MAC;
        this.Alias = device.Alias;
        this.Address = device.Address;
        this.Port = device.Port;
        this.OrderIndex = device.OrderIndex;
    }

    toDevice(): Device {
        return new Device(
            this.ID,
            this.MAC,
            this.Alias,
            this.Address,
            this.Port,
            this.OrderIndex
        );
    }

    toJsonObject(): DeviceJsonObject {
        return new DeviceJsonObject(
            this.MAC,
            this.Alias,
            this.Address,
            this.Port,
            this.OrderIndex
        );
    }
}