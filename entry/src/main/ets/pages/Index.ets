import { JSON } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction, router } from '@kit.ArkUI';
import Machine from '../model/Machine';
import MachineTile from '../view/MachineTile';
import Logger from '../common/utils/Logger';
import DB from '../common/utils/DB';
import NET from '../common/utils/NET';
import IPBanner from '../view/IPBanner';

@Entry
@Component
struct Index {
    @State machines: Array<Machine> = [];
    @State ipBannerText: string = '';

    private LOG_TAG = '[pages/Index]';

    refreshIPBanner() {
        NET.refreshCurrentNetwork();
        this.ipBannerText = `${getContext(this).resourceManager.getStringByNameSync("current_broadcast_ip")}${NET.BROADCAST_IP}`;
    }

    getMachineList(): void {
        DB.getMachineList().then((list) => {
            if(list === undefined) return;

            this.machines = list;
            Logger.debug(this.LOG_TAG, `Machines found: ${JSON.stringify(this.machines)}`);
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Query failed. Code: ${err.code}, message: ${err.message}`)
        })
    }

    onPageShow(): void {
        this.refreshIPBanner();
        this.getMachineList();
    }

    onPageHide(): void {
        this.refreshIPBanner();
    }

    build() {
        Navigation() {
            Column() {
                IPBanner({ ipBannerText: $ipBannerText })

                List() {
                    ForEach(this.machines, (machine: Machine) => {
                        ListItem() {
                            MachineTile({
                                machineMAC: $r("app.string.machine_mac_label", machine.MAC),
                                machineAlias: $r("app.string.machine_alias_label", machine.Alias),
                                machineMACAddr: machine.MAC
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
                .width('100%')

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
        .menus([
            {
                value: 'Refresh',
                icon: "./media/icon/network-refresh.png",
                action: () => {
                    this.refreshIPBanner();
                }
            },
            {
                value: 'Help',
                icon: "./media/icon/questionmark_circle.png",
                action: () => {
                    promptAction.showDialog({
                        title: $r("app.string.help_title"),
                        message: $r("app.string.help_info"),
                        buttons: [
                            {
                                text: $r("app.string.button_confirm_label"),
                                color: $r("app.color.black")
                            }
                        ]
                    })
                }
            }
        ])
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}