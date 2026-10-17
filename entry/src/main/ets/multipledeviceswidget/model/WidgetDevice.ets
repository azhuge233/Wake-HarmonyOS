export class WidgetDevice {
    id: number;
    alias: string;
    mac: string;
    address: string;
    port: number;

    constructor(id: number, alias: string, mac: string, address: string, port: number) {
        this.id = id;
        this.alias = alias;
        this.mac = mac;
        this.address = address;
        this.port = port;
    }
}