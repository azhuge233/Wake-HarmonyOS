import DeviceEditEntryAbilityBase from '../../common/abilities/DeviceEditEntryAbilityBase';

export default class SingleDeviceEditEntryAbility extends DeviceEditEntryAbilityBase {
    constructor() {
        super('pages/SingleDeviceFormEdit', '[SingleDeviceEditEntryAbility]', '单设备');
    }
}
