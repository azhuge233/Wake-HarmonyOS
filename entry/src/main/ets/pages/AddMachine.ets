import Logger from '../common/utils/Logger';
import TextItem, { INPUT_TYPE } from '../view/TextItem';
import DB from '../common/utils/DB';
import { BusinessError } from '@kit.BasicServicesKit';
import StyleConstants from '../common/constants/StyleConstants';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct AddMachine {
    @State mac: string = '';
    @State alias: string = '';

    private LOG_TAG = '[pages/AddMachine]'

    addMachine(mac: string, alias: string) {
        DB.addMachine(mac, alias)?.then(id => {
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
        if(mac.length < StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH) {
            return $r("app.string.validate_mac_too_short");
        }

        const regex = /^(?:[0-9A-Fa-f]{2}([-:]))(?:[0-9A-Fa-f]{2}\1){4}[0-9A-Fa-f]{2}$/

        if(!regex.test(mac)) {
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
                    textResource: $r("app.string.add_mac_input_label"),
                    placeholderResource: $r("app.string.add_mac_input_placeholder"),
                    text: this.mac
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        left: StyleConstants.MARGIN_TWO_PERCENT
                    })

                TextItem({
                    inputType: INPUT_TYPE.ALIAS,
                    textResource: $r("app.string.add_alias_input_label"),
                    placeholderResource: $r("app.string.add_alias_input_placeholder"),
                    text: this.alias
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        left: StyleConstants.MARGIN_TWO_PERCENT
                    })

                Button($r("app.string.button_add_machine_confirm"))
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .margin({
                        top: StyleConstants.MARGIN_TEN_PERCENT
                    })
                    .onClick(() => {
                        const mac = this.mac;
                        const alias = this.alias;

                        if(this.isStringNullOrEmpty(mac) || this.isStringNullOrEmpty(alias)) {
                            this.alert($r("app.string.input_cannot_be_null_or_empty"));
                            return;
                        }

                        const validate_result = this.macValidate(mac);

                        if(validate_result != '') {
                            this.alert(validate_result);
                            return;
                        }

                        this.addMachine(this.mac, this.alias);

                        this.mac = '';
                        this.alias = '';
                    })
            }
            .margin({
                top: StyleConstants.SIXTY_PERCENT
            })
        }
        .titleMode(NavigationTitleMode.Mini)
        .title($r("app.string.add_machine_title"))
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}