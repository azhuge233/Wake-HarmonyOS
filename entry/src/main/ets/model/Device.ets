export default class Device {
    ID: number = -1;
    MAC: string = 'FF:FF:FF:FF:FF:FF';
    Alias: string = 'Dummy';
    Address: string = '';
    Port: number = 9;
    OrderIndex: number = -1;

    constructor(id: number, mac: string, alias: string, addr: string, port: number, orderIndex: number) {
        this.ID = id
        this.MAC = mac;
        this.Alias = alias;
        this.Address = addr;
        this.Port = port;
        this.OrderIndex = orderIndex;
    }
}