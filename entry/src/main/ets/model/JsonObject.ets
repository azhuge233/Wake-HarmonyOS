export class DeviceJsonObject {
    MAC: string = "";
    Alias: string = "";
    Address: string | null = null;
    Port: number | null = null;
    OrderIndex: number = -1;

    constructor(mac: string, alias: string, addr: string | null = null, port: number | null = null, orderIndex: number = -1) {
        this.MAC = mac;
        this.Alias = alias;
        this.Address = addr;
        this.Port = port;
        this.OrderIndex = orderIndex;
    }
}