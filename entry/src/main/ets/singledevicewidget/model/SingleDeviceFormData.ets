export class SingleDeviceFormData {
    formID: string = '';
    isInitialized: boolean = false;
    isRunning: boolean = false;

    deviceID: number | null = null;
    alias: string | null = null;
    mac: string | null = null;
    address: string | null = null;
    port: number | null = null;

    runResult: string = '';

    constructor(formID: string, isInitialized: boolean) {
        this.formID = formID;
        this.isInitialized = isInitialized;
    }
}