import Logger from '../common/utils/Logger';
import TextItem, { INPUT_TYPE } from '../view/TextItem';
import { DB } from '../common/utils/DB';
import { BusinessError } from '@kit.BasicServicesKit';
import StyleConstants from '../common/constants/StyleConstants';
import { promptAction, window } from '@kit.ArkUI';
import CommonConstants from '../common/constants/CommonConstants';
import { Decimal } from '@kit.ArkTS';

@Entry
@Component
struct AddMachine {
    @State mac: string = '';
    @State alias: string = '';
    @State screenHeight: string = StyleConstants.FULL_PERCENT;

    private LOG_TAG = '[pages/AddMachine]'
    private focusController = this.getUIContext().getFocusController();
    private totalHeight: number = 0;

    private db = DB.getInstance();

    private uiContext = this.getUIContext();

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

    addMachine(mac: string, alias: string) {
        this.db.addMachine(mac, alias).then(id => {
            Logger.debug(this.LOG_TAG, `Added machine - ID: ${id}, MAC: ${mac}, Alias: ${alias}`);
            this.alert($r("app.string.add_machine_success", alias));
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Add Error! Code: ${err.code}, message: ${err.message}`);
        })
    }

    alert(message: string | Resource) {
        promptAction.showToast({
            message: message,
            bottom: StyleConstants.TOAST_BOTTOM_SPACE
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
        Navigation() {
            Column() {
                TextItem({
                    inputType: INPUT_TYPE.MAC,
                    inputId: CommonConstants.MAC_INPUT_ID,
                    isDefaultFocus: true,
                    textResource: $r("app.string.add_mac_input_label"),
                    placeholderResource: $r("app.string.add_mac_input_placeholder"),
                    text: this.mac
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
                    text: this.alias
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        left: StyleConstants.MARGIN_FIVE_PERCENT
                    })

                Button($r("app.string.button_add_machine_confirm"))
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .onClick(() => {
                        const mac = this.mac;
                        const alias = this.alias;

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

                        this.addMachine(this.mac, this.alias);

                        this.mac = '';
                        this.alias = '';
                    })
            }
            .height(this.screenHeight)
            .justifyContent(FlexAlign.Center)
        }
        .titleMode(NavigationTitleMode.Mini)
        .title($r("app.string.add_machine_title"))
        .alignSelf(ItemAlign.Center)
        .align(Alignment.Center)
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}