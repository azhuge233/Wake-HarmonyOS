class CommonConstants {
    public readonly MAC_INPUT_ID = "mac_input";
    public readonly ALIAS_INPUT_ID = "alias_input";
    public readonly ADDRESS_INPUT_ID = "address_input";
    public readonly PORT_INPUT_ID = "port_input";

    public readonly VIBRATE_EFFECT_ID_SOFT = 'haptic.effect.soft';
    public readonly VIBRATE_EFFECT_ID_HARD = 'haptic.effect.hard';

    public readonly APP_STORAGE_KEY_SHORTCUT_PATH = 'path';
    public readonly APP_STORAGE_KEY_FORM_ID = 'formID';
    public readonly APP_STORAGE_KEY_APP_SETTINGS = "AppSettings";

    public readonly FILE_PICKER_CANCEL_ERROR_CODE = 100006;

    public readonly FORM_MESSAGE_RESTORE = 'restore';

    public readonly FORM_CALL_RUN = 'run';

    public readonly FORM_RESULT_MAP_KEY_SINGLE = 'single';
    public readonly FORM_RESULT_MAP_KEY_MULTIPLE = 'multiple';
}

const commonConstants = new CommonConstants();
export { commonConstants as CommonConstants };