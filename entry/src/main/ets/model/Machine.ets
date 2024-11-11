@Observed
export default class Machine {
    ID: number
    MAC: string = ''
    Alias: string = ''

    constructor(id: number, mac: string, alias: string) {
        this.ID = id
        this.MAC = mac;
        this.Alias = alias;
    }
}