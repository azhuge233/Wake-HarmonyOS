import Logger from '../common/utils/Logger';
import TextItem from '../view/TextItem';
import DB from '../common/utils/DB';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct AddMachine {
    @State mac: string = '';
    @State alias: string = '';

    private LOG_TAG = '[pages/AddMachine]'

    addMachine(mac: string, alias: string) {
        DB.addMachine(mac, alias)?.then(id => {
            // this.machines.push(new Machine(id, mac, alias));
            Logger.debug(this.LOG_TAG, `Added machine - ID: ${id}, MAC: ${mac}, Alias: ${alias}`);
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Add Error! Code: ${err.code}, message: ${err.message}`);
        })
    }

    build() {
        Navigation() {
            Column() {
                Column() {
                    TextItem({
                        textResource: $r("app.string.add_mac_input_label"),
                        placeholderResource: $r("app.string.add_mac_input_placeholder"),
                        text: this.mac
                    })
                        .width('80%')

                    TextItem({
                        textResource: $r("app.string.add_alias_input_label"),
                        placeholderResource: $r("app.string.add_alias_input_placeholder"),
                        text: this.alias
                    })
                        .width('80%')
                        .margin({
                            bottom: '10%'
                        })

                    Button($r("app.string.button_add_machine_confirm"))
                        .width('80%')
                        .onClick(() => {
                            this.addMachine(this.mac, this.alias);
                            this.mac = '';
                            this.alias = '';
                        })
                }
                .height('62%')
            }
            .margin({
                top: '50%'
            })
        }
        .titleMode(NavigationTitleMode.Mini)
        .title($r("app.string.add_machine_title"))
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}