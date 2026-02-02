import WidgetDevice from "./WidgetDevice";

export default class MultipleDevicesFormData {
    formID: string = '';
    isInitialized: boolean = false;
    isRunning: boolean = false;

    deviceList: Array<WidgetDevice> = [];

    runResult: string = '';

    constructor(formID: string, isInitialized: boolean) {
        this.formID = formID;
        this.isInitialized = isInitialized;
    }
}