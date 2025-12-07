export class DeviceJsonObject {
    MAC: string = "";
    Alias: string = "";
    OrderIndex: number = -1;

    constructor(mac: string, alias: string, orderIndex: number) {
        this.MAC = mac;
        this.Alias = alias;
        this.OrderIndex = orderIndex;
    }
}