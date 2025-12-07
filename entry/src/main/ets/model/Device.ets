export default class Device {
    ID: number = -1;
    MAC: string = 'FF:FF:FF:FF:FF:FF';
    Alias: string = 'Dummy';
    OrderIndex: number = -1;

    constructor(id: number, mac: string, alias: string, orderIndex: number) {
        this.ID = id
        this.MAC = mac;
        this.Alias = alias;
        this.OrderIndex = orderIndex;
    }
}