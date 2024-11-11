import Machine from '../model/Machine';
import MachineTile from '../view/MachineTile';
import Logger from '../common/utils/Logger';
import { router } from '@kit.ArkUI';
import DB from '../common/utils/DB';
import { JSON } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
    @State machines: Array<Machine> = [];
    private LOG_TAG = '[pages/Index]';

    getMachineList(): void {
        DB.getMachineList().then((list) => {
            if(list === undefined) return;

            this.machines = list;
            Logger.debug(this.LOG_TAG, `Machines found: ${JSON.stringify(this.machines)}`);
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Query failed. Code: ${err.code}, message: ${err.message}`)
        })
    }

    aboutToAppear(): void {
        this.getMachineList()
    }

    onPageShow(): void {
        this.getMachineList()
    }

    build() {
        Navigation() {
            Column() {
                List() {
                    ForEach(this.machines, (machine: Machine) => {
                        ListItem() {
                            MachineTile({
                                machineMAC: $r("app.string.machine_mac_label", machine.MAC),
                                machineAlias: $r("app.string.machine_alias_label", machine.Alias)
                            })
                        }.margin({
                            top: '2%',
                            left: '0%',
                            right: '5%',
                            bottom: '2%'
                        })
                    })
                }
                .listDirection(Axis.Vertical)
                .alignSelf(ItemAlign.Start)
                .height('88%')


                Button($r("app.string.button_Add_label"))
                    .width('80%')
                    .margin({
                        top: '5%'
                    })
                    .onClick(() => {
                        router.pushUrl({
                            url: "pages/AddMachine"
                        })
                    })
            }
        }
        .size({width: '100%', height: '100%'})
        .titleMode(NavigationTitleMode.Full)
        .title($r("app.string.title_label"))
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}