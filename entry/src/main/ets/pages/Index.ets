import { JSON } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

import Machine from '../model/Machine';
import MachineTile from '../view/MachineTile';
import Logger from '../common/utils/Logger';
import { DB } from '../common/utils/DB';
import NET from '../common/utils/NET';
import IPBanner from '../view/IPBanner';
import StyleConstants from '../common/constants/StyleConstants';

@Entry
@Component
struct Index {
    pageStack: NavPathStack = new NavPathStack();

    @State machines: Array<Machine> = [];
    @State ipBannerText: string = '';

    private LOG_TAG = '[pages/Index]';

    private scrollerForList: ListScroller = new ListScroller();

    private db = DB.getInstance();

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    // private applicationContext = this.context.getApplicationContext();

    alert(message: Resource) {
        promptAction.showToast({
            message: message
        })
    }

    refreshIPBanner() {
        NET.refreshCurrentNetwork();
        this.ipBannerText =
            `${this.context.resourceManager.getStringByNameSync("current_broadcast_ip")}${NET.BROADCAST_IP}`;
    }

    async getMachineList(): Promise<void> {
        await this.db.waitForReady();
        this.db.getMachineList().then((list) => {
            if (list === undefined) {
                Logger.info(this.LOG_TAG, 'No Machine found!');
                return;
            }

            this.machines = list;
            Logger.debug(this.LOG_TAG, `Machines found: ${JSON.stringify(this.machines)}`);
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Query failed. Code: ${err.code}, message: ${err.message}`)
        })
    }

    async onPageShow(): Promise<void> {
        this.refreshIPBanner();
        await this.getMachineList();
    }

    onPageHide(): void {
        this.scrollerForList.closeAllSwipeActions();
        this.refreshIPBanner();
    }

    @Builder DeleteButton(id: number, index: number) {
        Row() {
            Button() {
                Image("./media/icon/trash.png")
                    .objectFit(ImageFit.Cover)
                    .width(StyleConstants.SIXTY_PERCENT)
                    .height(StyleConstants.SIXTY_PERCENT)
            }
            .backgroundColor($r("app.color.red"))
            .type(ButtonType.Circle)
            .width(StyleConstants.DELETE_BUTTON_WIDTH)
            .height(StyleConstants.DELETE_BUTTON_HEIGHT)
            .onClick(() => {
                this.db.deleteMachineByID(id).then(() => {
                    this.machines.splice(index, 1)
                });
            })
        }
        .margin({
            left: StyleConstants.MARGIN_THREE_PERCENT
        })
    }

    @Builder EditButton(machine: Machine) {
        Row() {
            Button() {
                Image("./media/icon/square_and_pencil.png")
                    .objectFit(ImageFit.Cover)
                    .width(StyleConstants.SIXTY_PERCENT)
                    .height(StyleConstants.SIXTY_PERCENT)
            }
            .backgroundColor($r("app.color.green"))
            .type(ButtonType.Circle)
            .width(StyleConstants.DELETE_BUTTON_WIDTH)
            .height(StyleConstants.DELETE_BUTTON_HEIGHT)
            .onClick(async () => {
                this.scrollerForList.closeAllSwipeActions();
                this.pageStack.pushPath({
                    name: "Edit",
                    param: machine,
                    onPop: async (popInfo: PopInfo) => {
                        await this.getMachineList();
                        Logger.debug(this.LOG_TAG,
                            `Returned from page [${popInfo.info.name}], result: ${JSON.stringify(popInfo.result)}`);
                    }
                });
            })
        }
        .margin({
            left: StyleConstants.MARGIN_THREE_PERCENT
        })
    }

    build() {
        Navigation(this.pageStack) {
            Column() {
                IPBanner({ ipBannerText: $ipBannerText })

                List({ scroller: this.scrollerForList }) {
                    ForEach(this.machines, (machine: Machine, index) => {
                        ListItem() {
                            MachineTile({
                                machineMAC: $r("app.string.machine_mac_label", machine.MAC),
                                machineAlias: $r("app.string.machine_alias_label", machine.Alias),
                                machineMACAddr: machine.MAC
                            })
                        }
                        .swipeAction({
                            end: {
                                builder: () => {
                                    this.EditButton(machine);
                                    this.DeleteButton(machine.ID, index);
                                }
                            }
                        })
                        .margin({
                            top: StyleConstants.MARGIN_TWO_PERCENT,
                            left: StyleConstants.MARGIN_ONE_PERCENT,
                            right: StyleConstants.MARGIN_THREE_PERCENT,
                            bottom: StyleConstants.MARGIN_TWO_PERCENT
                        })
                    })
                }
                .listDirection(Axis.Vertical)
                .alignSelf(ItemAlign.Start)
                .height(StyleConstants.EIGHTY_FIVE_PERCENT)
                .width(StyleConstants.FULL_PERCENT)

                Button($r("app.string.button_Add_label"))
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .margin({
                        top: StyleConstants.MARGIN_FIVE_PERCENT
                    })
                    .onClick(() => {
                        this.pageStack.pushPath({ name: "AddMachine" });
                    })
            }
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween)
        }
        .mode(NavigationMode.Auto)
        .titleMode(NavigationTitleMode.Full)
        .title($r("app.string.title_label"))
        .menus([
            {
                value: $r("app.string.navigation_menu_refresh"),
                icon: "./media/icon/network_refresh.png",
                action: () => {
                    this.refreshIPBanner();
                    this.alert($r("app.string.network_refreshed"));
                }
            },
            {
                value: $r("app.string.navigation_menu_more"),
                icon: "./media/icon/gearshape.png",
                action: () => {
                    this.pageStack.pushPath({ name: "More" })
                }
            }
        ])
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}
