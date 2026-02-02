export default class SingleDeviceFormData {
    formID: string = '';
    isInitialized: boolean = false;
    isRunning: boolean = false;

    deviceID: number | null = null;
    alias: string | null = null;
    mac: string | null = null;

    runResult: string = '';

    constructor(formID: string, isInitialized: boolean) {
        this.formID = formID;
        this.isInitialized = isInitialized;
    }
}