import { KeyboardAvoidMode } from '@kit.ArkUI';

import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';
import TextItem, { INPUT_TYPE } from '../view/TextItem';
import CommonConstants from '../common/constants/CommonConstants';
import CommonUtils from '../common/utils/CommonUtils';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';

@Builder
export function EditBuilder() {
    Edit();
}

@Entry
@ComponentV2
struct Edit {
    private LOG_TAG = '[pages/Edit]';

    @Local updatingDevice: DeviceViewModel = new DeviceViewModel();

    private uiContext = this.getUIContext();
    private promptAction = this.uiContext.getPromptAction();
    private focusController = this.uiContext.getFocusController();

    private deviceList: DeviceListViewModel = new DeviceListViewModel();

    pathStack: NavPathStack | undefined = undefined;

    aboutToAppear() {
        // 设置软键盘避让
        this.uiContext.setKeyboardAvoidMode(KeyboardAvoidMode.RESIZE);
    }

    async updateDevice() {
        const mac = this.updatingDevice.MAC.trim();
        const alias = this.updatingDevice.Alias.trim();

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
            const success = await this.deviceList.updateDevice(this.updatingDevice.toDevice());
            if (success) {
                CommonUtils.alert($r("app.string.update_machine_success", this.updatingDevice.Alias), this.promptAction);
                this.pathStack?.pop("Button pressed");
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `更新设备失败: ${err}`);
            CommonUtils.alert($r("app.string.update_machine_failed", err), this.promptAction);
        }
    }

    build() {
        NavDestination(){
            Column() {
                TextItem({
                    inputType: INPUT_TYPE.MAC,
                    inputId: CommonConstants.MAC_INPUT_ID,
                    isDefaultFocus: true,
                    textResource: $r("app.string.add_mac_input_label"),
                    placeholderResource: $r("app.string.add_mac_input_placeholder"),
                    text: this.updatingDevice.MAC,
                    onInputChange: (value: string) => { this.updatingDevice.MAC = value }
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
                    text: this.updatingDevice.Alias,
                    onInputChange: (value: string) => { this.updatingDevice.Alias = value }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        left: StyleConstants.MARGIN_FIVE_PERCENT
                    })

                Button($r("app.string.button_edit_confirm"))
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .onClick(async () => {
                        await this.updateDevice();
                    })
            }
            .height(StyleConstants.FULL_PERCENT)
            .justifyContent(FlexAlign.Center)
        }
        .title($r("app.string.edit_title"))
        .alignSelf(ItemAlign.Center)
        .align(Alignment.Center)
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
            const param = this.pathStack.getParamByIndex(0) as Array<object>;
            this.deviceList = param[0] as DeviceListViewModel;
            this.updatingDevice = param[1] as DeviceViewModel;
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