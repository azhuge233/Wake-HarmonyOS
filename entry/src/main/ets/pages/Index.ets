import { BusinessError } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';

import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';
import Logger from '../common/utils/Logger';
import NET from '../common/utils/NET';
import IPBanner from '../view/IPBanner';
import StyleConstants from '../common/constants/StyleConstants';
import CommonUtils from '../common/utils/CommonUtils';
import CommonConstants from '../common/constants/CommonConstants';
import DeviceTile from '../view/DeviceTile';

@Entry
@ComponentV2
struct Index {
    private LOG_TAG = '[pages/Index]';

    @Local deviceList: DeviceListViewModel = new DeviceListViewModel();
    @Local ipBannerText: string = '';
    @Local isLoading: boolean = false;

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    private promptAction = this.uiContext.getPromptAction();

    private scrollerForList: ListScroller = new ListScroller();

    pageStack: NavPathStack = new NavPathStack();

    async onPageShow(): Promise<void> {
        this.refreshIPBanner();
        await this.loadDevices();

        if(AppStorage.has('want')) {
            let want: Want | undefined = AppStorage.get('want');
            if (want) {
                this.goToSpecifyPage(want);
                AppStorage.delete('want');
            }
        }
    }

    onPageHide(): void {
        this.safeCloseSwipeActions();
        this.refreshIPBanner();
    }

    // 刷新广播地址
    private refreshIPBanner() {
        NET.refreshCurrentNetwork();
        this.ipBannerText =
            `${this.context.resourceManager.getStringByNameSync("current_broadcast_ip")}${NET.BROADCAST_IP}`;
    }

    // 加载设备列表
    private async loadDevices() {
        this.isLoading = true;
        await this.deviceList.loadDevices();
        this.isLoading = false;
    }

    private safeCloseSwipeActions(): void {
        try {
            if (this.deviceList.devices.length > 0) {
                this.scrollerForList.closeAllSwipeActions();
            }
        } catch (err) {
            Logger.debug(this.LOG_TAG, `关闭左滑菜单失败, ${err}`);
        }
    }

    // 快捷方式跳转判断
    private async goToSpecifyPage(want?: Want): Promise<void> {
        // 如果应用内已经进入其他页面，返回到主页面
        if(this.pageStack.size() > 0) this.pageStack.clear();

        let shortCutKey = want?.parameters?.shortCutKey;

        try {
            if (shortCutKey && shortCutKey === 'AddDevice') {
                this.pageStack.pushPath({
                    name: "AddDevice",
                    param: this.deviceList,
                    onPop: async (popInfo) => {
                        this.refreshIPBanner();
                        CommonUtils.returnFromSubPage(popInfo);
                    }
                });
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `快捷方式跳转失败, ${err}`);
        }
    }

    @Builder
    DeleteButton(device: DeviceViewModel) {
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
                this.deviceList.deleteDevice(device.toDevice());
            })
        }
        .margin({
            left: StyleConstants.MARGIN_THREE_PERCENT
        })
    }

    @Builder
    EditButton(device: DeviceViewModel) {
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
                this.safeCloseSwipeActions();
                this.pageStack.pushPath({
                    name: "Edit",
                    param: [this.deviceList, device],
                    onPop: async (popInfo: PopInfo) => {
                        this.refreshIPBanner();
                        CommonUtils.returnFromSubPage(popInfo);
                    }
                });
            })
        }
        .margin({
            left: StyleConstants.MARGIN_THREE_PERCENT
        })
    }

    @Builder
    LoadingContent() {
        Stack() {
            Column()
                .width(StyleConstants.FULL_PERCENT)
                .height(StyleConstants.FULL_PERCENT)
                .backgroundColor($r("app.color.background_transparent"))
                .blur(StyleConstants.PROGRESS_COLUMN_BLUR_LEVEL)
                .onClick(() => {})


            Column() {
                Progress({ value: 0, total: 100, type: ProgressType.Ring })
                    .width(StyleConstants.PROGRESS_WIDTH)
                    .color(Color.Blue)
                    .style({
                        strokeWidth: StyleConstants.PROGRESS_STROKE_WIDTH,
                        status: ProgressStatus.LOADING
                    })

                Text($r("app.string.import_waiting_message"))
                    .margin({ top: StyleConstants.MARGIN_TWENTY })
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                    .fontColor($r("app.color.text_font_color"))
            }
            .width(StyleConstants.FULL_PERCENT)
            .height(StyleConstants.FULL_PERCENT)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {})
        }
        .onClick(() => {})
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Blocking stack loaded!");
        })
    }

    @Builder
    MainContent() {
        Column() {
            if (!this.isLoading && this.deviceList.devices.length === 0) {
                Column() {
                    Text($r("app.string.no_device_message"))
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHTEEN)
                        .fontColor(Color.Gray)
                    Text($r("app.string.create_new_device_message"))
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                        .fontColor(Color.Gray)
                        .margin({ top: StyleConstants.MARGIN_TEN })
                }
                .height(StyleConstants.EIGHTY_FIVE_PERCENT)
                .justifyContent(FlexAlign.Center)
                .width(StyleConstants.FULL_PERCENT)
            } else {
                List({ scroller: this.scrollerForList }) {
                    ForEach(this.deviceList.devices, (device: DeviceViewModel) => {
                        ListItem() {
                            DeviceTile({
                                deviceMAC: $r("app.string.machine_mac_label", device.MAC),
                                deviceAlias: $r("app.string.machine_alias_label", device.Alias),
                                deviceMACAddr: device.MAC,
                                sendPacket: (macAddr: string) => {
                                    if (NET.HAS_BROADCAST_IP) {
                                        const packet = NET.buildMagicPacket(macAddr);

                                        NET.UDP.send(packet, (err: BusinessError) => {
                                            if (err) {
                                                Logger.error(this.LOG_TAG,
                                                    `Send magic packet Error. Code: ${err.code}, message: ${err.message}`);
                                                CommonUtils.alert($r("app.string.send_magic_packet_failed", err.code),
                                                    this.promptAction);
                                                return;
                                            }

                                            Logger.debug(this.LOG_TAG, 'Send magic packet OK!');
                                            CommonUtils.alert($r("app.string.send_magic_packet_success"),
                                                this.promptAction);
                                        });
                                    } else {
                                        Logger.debug(this.LOG_TAG, "No broadcast IP, abort.");
                                        CommonUtils.alert($r("app.string.no_broadcast_ip"), this.promptAction);
                                    }
                                }
                            })
                        }
                        .swipeAction({
                            end: {
                                builder: () => {
                                    this.EditButton(device);
                                    this.DeleteButton(device);
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
                        .onMove((from: number, to: number) => {
                            const success = this.deviceList.reorderDevices(from, to);
                            return success;
                        }, {
                            onLongPress: () => {
                                CommonUtils.vibrate(CommonConstants.Vibrate_Effect_ID_SOFT);
                            }
                        })
                }
                .listDirection(Axis.Vertical)
                .alignSelf(ItemAlign.Start)
                .height(StyleConstants.EIGHTY_FIVE_PERCENT)
                .width(StyleConstants.FULL_PERCENT)
            }

            Button($r("app.string.button_Add_label"))
                .width(StyleConstants.EIGHTY_PERCENT)
                .margin({
                    top: StyleConstants.MARGIN_FIVE_PERCENT
                })
                .onClick(() => {
                    this.safeCloseSwipeActions();
                    this.pageStack.pushPath({
                        name: "AddDevice",
                        param: this.deviceList,
                        onPop: async (popInfo: PopInfo) => {
                            this.refreshIPBanner();
                            CommonUtils.returnFromSubPage(popInfo);
                        }
                    });
                })
        }
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.SpaceBetween)
    }

    build() {
        Navigation(this.pageStack) {
            IPBanner({
                ipBannerText: this.ipBannerText,
                onRefresh: () => {
                    this.refreshIPBanner();
                }
            })

            Stack({ alignContent: Alignment.Top }) {
                this.MainContent();

                if(this.isLoading) this.LoadingContent();
            }
        }
        .mode(NavigationMode.Auto)
        .titleMode(NavigationTitleMode.Full)
        .title($r("app.string.title_label"))
        .menus([
            {
                value: $r("app.string.navigation_menu_refresh"),
                icon: $r("app.media.network_refresh"),
                action: () => {
                    this.refreshIPBanner();
                    CommonUtils.alert($r("app.string.network_refreshed"), this.promptAction);
                }
            },
            {
                value: $r("app.string.navigation_menu_more"),
                icon: $r("app.media.dot_grid_2x2"),
                action: () => {
                    this.safeCloseSwipeActions();
                    this.pageStack.pushPath({
                        name: "More",
                        param: this.deviceList,
                        onPop: async (popInfo: PopInfo) => {
                            this.refreshIPBanner();
                            CommonUtils.returnFromSubPage(popInfo);
                        }
                    })
                }
            }
        ])
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}
