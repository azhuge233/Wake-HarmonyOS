/**
 * 卡片绑定数据的纯数据类。字段名与 JSON 键与旧版逐字一致，卡片与首选项里的历史数据可直接反序列化。
 * 本档不引任何 kit：FormBindingData 由 data/CardPublisher 负责构造。
 */

/** 多设备卡片列表里的一项；JSON 键沿用旧版小写 id/alias/mac/address/port */
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

/** 单设备卡片的绑定数据 */
export class SingleCardBindingData {
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

    /** 新卡片首次绑定前的空数据 */
    static empty(formID: string): SingleCardBindingData {
        return new SingleCardBindingData(formID, false);
    }
}

/** 多设备卡片的绑定数据 */
export class MultipleCardBindingData {
    formID: string = '';
    isInitialized: boolean = false;
    isRunning: boolean = false;

    deviceList: Array<WidgetDevice> = [];

    runResult: string = '';

    constructor(formID: string, isInitialized: boolean) {
        this.formID = formID;
        this.isInitialized = isInitialized;
    }

    /** 新卡片首次绑定前的空数据 */
    static empty(formID: string): MultipleCardBindingData {
        return new MultipleCardBindingData(formID, false);
    }
}

/**
 * 一次变更影响到的卡片集合。放在叶子层是因为两个领域服务与视图模型都要用它，
 * 放进 device 服务会让卡片绑定服务反向 import 领域内的另一个服务，形成环。
 */
export class AffectedForms {
    single: string[] = [];
    multiple: string[] = [];

    static empty(): AffectedForms {
        return new AffectedForms();
    }

    isEmpty(): boolean {
        return this.single.length === 0 && this.multiple.length === 0;
    }
}