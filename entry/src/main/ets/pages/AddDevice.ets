import { KeyboardAvoidMode } from '@kit.ArkUI';
import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit';

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

    @Local showAdvanced: boolean = false;

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
        this.newDevice.Address = '';
        this.newDevice.Port = 9;
    }

    async saveDevice() {
        const mac = this.newDevice.MAC.trim();
        const alias = this.newDevice.Alias.trim();
        const address = this.newDevice.Address.trim();
        const port = this.newDevice.Port;

        try {
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

            if (!CommonUtils.isStringNullOrEmpty(port.toString())) {
                if (port < 1 || port > 65535) {
                    CommonUtils.alert($r("app.string.port_invalid"), this.promptAction);
                    this.focusController.requestFocus(CommonConstants.PORT_INPUT_ID);
                    return;
                }
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `移动输入焦点失败, ${err}`);
        }

        const validateResult = CommonUtils.macValidate(mac);

        if (validateResult != '') {
            CommonUtils.alert(validateResult, this.promptAction);
            return;
        }

        try {
            const success = await this.deviceList.addDevice(this.newDevice.toDevice());
            if(success) {
                Logger.debug(this.LOG_TAG, `设备已添加 - MAC: ${mac}, Alias: ${alias}, Address: ${address}, Port: ${port}`);
                this.clearInput();
                CommonUtils.alert($r("app.string.add_machine_success", alias), this.promptAction);
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `保存设备失败: ${err}`);
            CommonUtils.alert($r("app.string.add_machine_failed", alias), this.promptAction);
        }
    }

    build() {
        HdsNavDestination() {
            Column() {
                TextItem({
                    inputType: INPUT_TYPE.MAC,
                    inputId: CommonConstants.MAC_INPUT_ID,
                    isDefaultFocus: true,
                    textResource: $r("app.string.add_mac_input_label"),
                    placeholderResource: $r("app.string.add_mac_input_placeholder"),
                    text: this.newDevice.MAC,
                    onInputChange: (value: string | number) => { this.newDevice.MAC = String(value) }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)

                TextItem({
                    inputType: INPUT_TYPE.ALIAS,
                    inputId: CommonConstants.ALIAS_INPUT_ID,
                    isDefaultFocus: false,
                    textResource: $r("app.string.add_alias_input_label"),
                    placeholderResource: $r("app.string.add_alias_input_placeholder"),
                    text: this.newDevice.Alias,
                    onInputChange: (value: string | number) => { this.newDevice.Alias = String(value) }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)

                Column() {
                    Stack() {
                        Divider()
                            .strokeWidth(StyleConstants.DIVIDER_STOKE_WIDTH)
                            .width(StyleConstants.EIGHTY_PERCENT)
                            .color($r("sys.color.background_emphasize"))

                        Row() {
                            Text($r("app.string.divider_label"))
                                .fontColor($r("sys.color.font_emphasize"))
                                .fontSize(StyleConstants.DIVIDER_FONT_SIZE)
                                .margin({
                                    right: StyleConstants.MARGIN_ONE_PERCENT
                                })

                            SymbolGlyph($r("sys.symbol.chevron_up"))
                                .width(StyleConstants.DIVIDER_SYMBOL_SIZE)
                                .height(StyleConstants.DIVIDER_SYMBOL_SIZE)
                                .fontColor([$r("sys.color.font_emphasize")])
                                .margin({
                                    left: StyleConstants.MARGIN_ONE_PERCENT
                                })
                                .rotate({
                                    angle: this.showAdvanced ? 180 : 0
                                })
                        }
                        .width(StyleConstants.TWENTY_PERCENT)
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)
                        .backgroundColor($r("sys.color.background_primary"))
                        .margin({
                            left: StyleConstants.ONE_PERCENT
                        })
                        .onClick(() => {
                            this.showAdvanced = !this.showAdvanced;
                        })
                    }
                    .alignContent(Alignment.Start)
                    .margin({
                        top: StyleConstants.MARGIN_TWO_PERCENT
                    })

                    if (this.showAdvanced) {
                        TextItem({
                            inputType: INPUT_TYPE.ADDRESS,
                            inputId: CommonConstants.ADDRESS_INPUT_ID,
                            isDefaultFocus: false,
                            textResource: $r("app.string.add_address_input_label"),
                            placeholderResource: $r("app.string.add_address_input_placeholder"),
                            text: this.newDevice.Address,
                            onInputChange: (value: string | number) => { this.newDevice.Address = String(value) }
                        })
                            .width(StyleConstants.EIGHTY_PERCENT)

                        TextItem({
                            inputType: INPUT_TYPE.PORT,
                            inputId: CommonConstants.PORT_INPUT_ID,
                            isDefaultFocus: false,
                            textResource: $r("app.string.add_port_input_label"),
                            placeholderResource: $r("app.string.add_port_input_placeholder"),
                            text: this.newDevice.Port,
                            onInputChange: (value: string | number) => { this.newDevice.Port = Number(value) }
                        })
                            .width(StyleConstants.EIGHTY_PERCENT)
                    }
                }
                .alignItems(HorizontalAlign.Center)


                Button($r("app.string.button_add_machine_confirm"))
                    .enabled(!CommonUtils.isStringNullOrEmpty(this.newDevice.MAC.trim()) && !CommonUtils.isStringNullOrEmpty(this.newDevice.Alias.trim()))
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .margin({
                        top: StyleConstants.MARGIN_TEN_PERCENT
                    })
                    .onClick(async () => {
                        await this.saveDevice();
                    })
            }
            .height(StyleConstants.FULL_PERCENT)
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.Center)
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.add_machine_title")
                }
            },
            style: {
                systemMaterialEffect: { // 设置沉浸光感
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                },
            },
            enableComponentSafeArea: true // 启用标题栏占位
        })
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