export default class WidgetDevice {
    id: number;
    alias: string;
    mac: string;

    constructor(id: number, alias: string, mac: string) {
        this.id = id;
        this.alias = alias;
        this.mac = mac;
    }
}