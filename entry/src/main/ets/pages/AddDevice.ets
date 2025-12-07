import { KeyboardAvoidMode } from '@kit.ArkUI';

import Logger from '../common/utils/Logger';
import TextItem, { INPUT_TYPE } from '../view/TextItem';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import CommonUtils from '../common/utils/CommonUtils';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';


@Builder
export function AddDeviceBuilder() {
    AddDevice();
}

@Entry
@ComponentV2
struct AddDevice {
    private LOG_TAG = '[pages/AddDevice]'

    @Local newDevice: DeviceViewModel = new DeviceViewModel();

    private uiContext = this.getUIContext();
    private promptAction = this.uiContext.getPromptAction();
    private focusController = this.uiContext.getFocusController();

    private deviceList: DeviceListViewModel = new DeviceListViewModel();

    pathStack: NavPathStack | undefined = undefined;

    aboutToAppear() {
        // 设置软键盘避让
        this.uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    }

    clearInput() {
        this.newDevice.MAC = '';
        this.newDevice.Alias = '';
    }

    async saveDevice() {
        const mac = this.newDevice.MAC.trim();
        const alias = this.newDevice.Alias.trim();

        if (CommonUtils.isStringNullOrEmpty(mac)) {
            CommonUtils.alert($r("app.string.input_cannot_be_null_or_empty"), this.promptAction);
            this.focusController.requestFocus(CommonConstants.MAC_INPUT_ID);
            return;
        }

        if (CommonUtils.isStringNullOrEmpty(alias)) {
            CommonUtils.alert($r("app.string.input_cannot_be_null_or_empty"), this.promptAction);
            this.focusController.requestFocus(CommonConstants.ALIAS_INPUT_ID);
            return;
        }

        const validateResult = CommonUtils.macValidate(mac);

        if (validateResult != '') {
            CommonUtils.alert(validateResult, this.promptAction);
            return;
        }

        try {
            const success = await this.deviceList.addDevice(this.newDevice.toDevice());
            if(success) {
                Logger.debug(this.LOG_TAG, `设备已添加 - MAC: ${mac}, Alias: ${alias}`);
                this.clearInput();
                CommonUtils.alert($r("app.string.add_machine_success", alias), this.promptAction);
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `保存设备失败: ${err}`);
            CommonUtils.alert($r("app.string.add_machine_failed", alias), this.promptAction);
        }
    }

    build() {
        NavDestination() {
            Column() {
                TextItem({
                    inputType: INPUT_TYPE.MAC,
                    inputId: CommonConstants.MAC_INPUT_ID,
                    isDefaultFocus: true,
                    textResource: $r("app.string.add_mac_input_label"),
                    placeholderResource: $r("app.string.add_mac_input_placeholder"),
                    text: this.newDevice.MAC,
                    onInputChange: (value: string) => { this.newDevice.MAC = value }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        left: StyleConstants.MARGIN_FIVE_PERCENT
                    })

                TextItem({
                    inputType: INPUT_TYPE.ALIAS,
                    inputId: CommonConstants.ALIAS_INPUT_ID,
                    isDefaultFocus: false,
                    textResource: $r("app.string.add_alias_input_label"),
                    placeholderResource: $r("app.string.add_alias_input_placeholder"),
                    text: this.newDevice.Alias,
                    onInputChange: (value: string) => { this.newDevice.Alias = value }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        left: StyleConstants.MARGIN_FIVE_PERCENT
                    })

                Button($r("app.string.button_add_machine_confirm"))
                    .enabled(!CommonUtils.isStringNullOrEmpty(this.newDevice.MAC.trim()) && !CommonUtils.isStringNullOrEmpty(this.newDevice.Alias.trim()))
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .onClick(async () => {
                        await this.saveDevice();
                    })
            }
            .height(StyleConstants.FULL_PERCENT)
            .justifyContent(FlexAlign.Center)
        }
        .title($r("app.string.add_machine_title"))
        .alignSelf(ItemAlign.Center)
        .align(Alignment.Center)
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
            this.deviceList = context.pathInfo.param as DeviceListViewModel;
        })
        .onBackPressed(() => {
            this.pathStack?.pop("Back pressed");
            return true;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}