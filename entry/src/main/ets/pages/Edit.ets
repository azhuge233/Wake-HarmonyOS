import { promptAction, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Decimal } from '@kit.ArkTS';

import Machine from '../model/Machine';
import Logger from '../common/utils/Logger';
import { DB } from '../common/utils/DB';
import StyleConstants from '../common/constants/StyleConstants';
import TextItem, { INPUT_TYPE } from '../view/TextItem';
import CommonConstants from '../common/constants/CommonConstants';

@Builder
export function EditBuilder() {
    Edit();
}

@Entry
@Component
struct Edit {
    pathStack: NavPathStack | undefined = undefined;

    @State editId: number = -1;
    @State newMAC: string = "";
    @State newAlias: string = "";

    @State screenHeight: string = StyleConstants.FULL_PERCENT;

    private LOG_TAG = '[pages/Edit]';

    private db = DB.getInstance();

    private uiContext = this.getUIContext();
    private focusController = this.uiContext.getFocusController();
    private totalHeight: number = 0;

    aboutToAppear(): void {
        window.getLastWindow(this.uiContext.getHostContext()).then(currentWindow =>{
            let property = currentWindow.getWindowProperties();
            this.totalHeight = property.windowRect.height;

            Logger.debug(this.LOG_TAG, `screenHeight initialized to: ${this.screenHeight}`);

            // 监视软键盘的弹出和收起
            currentWindow.on('keyboardHeightChange', async keyboardHeight => {
                if(keyboardHeight == 0) {
                    this.screenHeight = StyleConstants.FULL_PERCENT;
                    return;
                }
                let keyboardHeightPercent: number = new Decimal(keyboardHeight / this.totalHeight * 100).ceil().toNumber();
                this.screenHeight = `${100 - keyboardHeightPercent}%`;
                Logger.debug(this.LOG_TAG, `screenHeight changed to: ${this.screenHeight}`);
            })
        })
    }

    alert(message: string | Resource) {
        promptAction.showToast({
            message: message,
            bottom: StyleConstants.TOAST_BOTTOM_SPACE
        })
    }

    async updateMachine(id: number, mac: string, alias: string) {
        await this.db.updateMachineByID(id, mac, alias).then(id => {
            Logger.debug(this.LOG_TAG, `Updated machine - ID: ${id}, MAC: ${mac}, Alias: ${alias}`);
            this.alert($r("app.string.update_machine_success", alias));
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Update device Error! Code: ${err.code}, message: ${err.message}`);
        })
    }

    isStringNullOrEmpty(str: string): boolean {
        return str == null || str == '' || str.length == 0;
    }

    macValidate(mac: string): Resource | string {
        if (mac.length < StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH) {
            return $r("app.string.validate_mac_too_short");
        }

        const regex = /^(?:[0-9A-Fa-f]{2}([-:]))(?:[0-9A-Fa-f]{2}\1){4}[0-9A-Fa-f]{2}$/

        if (!regex.test(mac)) {
            return $r("app.string.validate_mac_regex_fail");
        }

        Logger.info(this.LOG_TAG, `MAC validateion passed. MAC: ${mac}`);

        return '';
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
                    text: this.newMAC
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
                    text: this.newAlias
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        left: StyleConstants.MARGIN_FIVE_PERCENT
                    })

                Button($r("app.string.button_edit_confirm"))
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .onClick(async () => {
                        const mac = this.newMAC;
                        const alias = this.newAlias;

                        if (this.isStringNullOrEmpty(mac)) {
                            this.alert($r("app.string.input_cannot_be_null_or_empty"));
                            this.focusController.requestFocus(CommonConstants.MAC_INPUT_ID);
                            return;
                        }

                        if (this.isStringNullOrEmpty(alias)) {
                            this.alert($r("app.string.input_cannot_be_null_or_empty"));
                            this.focusController.requestFocus(CommonConstants.ALIAS_INPUT_ID);
                            return;
                        }

                        const validate_result = this.macValidate(mac);

                        if (validate_result != '') {
                            this.alert(validate_result);
                            return;
                        }

                        await this.updateMachine(this.editId, mac, alias);

                        this.pathStack?.pop("OK");
                    })
            }
            .height(this.screenHeight)
            .justifyContent(FlexAlign.Center)
        }
        .title($r("app.string.edit_title"))
        .alignSelf(ItemAlign.Center)
        .align(Alignment.Center)
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
            const editMachine = context.pathInfo.param as Machine;

            this.editId = editMachine.ID;
            this.newMAC = editMachine.MAC;
            this.newAlias = editMachine.Alias;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}