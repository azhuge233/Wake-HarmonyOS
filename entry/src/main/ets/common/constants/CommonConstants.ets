class CommonConstants {
    public readonly MAC_INPUT_ID = "mac_input";
    public readonly ALIAS_INPUT_ID = "alias_input";
    public readonly ADDRESS_INPUT_ID = "address_input";
    public readonly PORT_INPUT_ID = "port_input";

    public readonly VIBRATE_EFFECT_ID_SOFT = 'haptic.effect.soft';
    public readonly VIBRATE_EFFECT_ID_HARD = 'haptic.effect.hard';

    // 一次性窗口参数的 LocalStorage 键：每个 Ability 实例一份，页面从本窗口的共享 storage 读
    public readonly WINDOW_PARAM_FORM_ID = 'formID';
    public readonly WINDOW_PARAM_SHORTCUT_PATH = 'path';

    // AppStorageV2 的进程级共享键，承载应用设置对象
    public readonly APP_SETTINGS_STORAGE_KEY = "AppSettings";

    // 与 ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET 同值；领域层不引 AbilityKit，故此处给数值
    public readonly COLOR_MODE_NOT_SET = -1;

    public readonly FILE_PICKER_CANCEL_ERROR_CODE = 100006;

    public readonly FORM_MESSAGE_RESTORE = 'restore';

    public readonly FORM_CALL_RUN = 'run';
}

const commonConstants = new CommonConstants();
export { commonConstants as CommonConstants };