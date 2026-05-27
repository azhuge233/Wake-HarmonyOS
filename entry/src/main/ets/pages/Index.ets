import { common } from '@kit.AbilityKit';
import { hdsMaterial, HdsNavigation, HdsNavigationMenuContentOptions, ScrollEffectType, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { connection } from "@kit.NetworkKit";

import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';
import Logger from '../common/utils/Logger';
import NET from '../common/utils/NET';
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
    private tabController: HdsTabsController = new HdsTabsController();

    private netConnection: connection.NetConnection | null = null;

    // HdsNavigation 新版菜单
    private menus: HdsNavigationMenuContentOptions = {
        value: [
            {
                content: {
                    label: $r("app.string.navigation_menu_refresh"),
                    icon: $r("sys.symbol.arrow_clockwise"),
                    action: async () => {
                        await this.refreshIPBanner();
                        CommonUtils.alert($r("app.string.network_refreshed"), this.promptAction);
                    }
                }
            },
            {
                content: {
                    label: $r("app.string.help_title"),
                    icon: $r("sys.symbol.info_circle"),
                    action: () => {
                        this.safeCloseSwipeActions();
                        this.pageStack.pushPath({
                            name: "Help",
                            param: this.deviceList,
                            onPop: async (popInfo: PopInfo) => {
                                await this.refreshIPBanner();
                                CommonUtils.returnFromSubPage(popInfo);
                            }
                        });
                    }
                }
            },
            {
                content: {
                    label: $r("app.string.navigation_menu_more"),
                    icon: $r("sys.symbol.dot_grid_2x2"),
                    action: () => {
                        this.safeCloseSwipeActions();
                        this.pageStack.pushPath({
                            name: "More",
                            param: this.deviceList,
                            onPop: async (popInfo: PopInfo) => {
                                await this.refreshIPBanner();
                                CommonUtils.returnFromSubPage(popInfo);
                            }
                        });
                    }
                }
            }
        ]
    };

    pageStack: NavPathStack = new NavPathStack();

    private net = new NET();

    aboutToAppear(): void {
        this.startNetListening();
    }

    aboutToDisappear(): void {
        this.stopNetListening();
    }

    async onPageShow(): Promise<void> {
        await this.refreshIPBanner();
        await this.loadDevices();

        // 处理长按快捷方式跳转
        if(AppStorage.has(CommonConstants.AppStorage_KEY_ShortcutPath)) {
            Logger.debug(this.LOG_TAG, `检测到长按快捷方式页面`);

            const path: string | undefined = AppStorage.get(CommonConstants.AppStorage_KEY_ShortcutPath);
            if (path) {
                await this.goToSpecifyPage(path);
                AppStorage.delete(CommonConstants.AppStorage_KEY_ShortcutPath);
            }
        }
    }

    async onPageHide(): Promise<void> {
        this.safeCloseSwipeActions();
        await this.refreshIPBanner();
    }

    // 启用网络监听
    // aboutToAppear 内调用
    private startNetListening() {
        // 创建网络监听器
        try {
            this.netConnection = connection.createNetConnection({
                netCapabilities: {
                    bearerTypes: [connection.NetBearType.BEARER_WIFI] // 指定监听WiFi
                }
            });
        } catch (err) {
            Logger.error(this.LOG_TAG, `创建网络监听失败: ${err}`);
            return;
        }

        // 注册网络可用的监听
        this.netConnection.on('netAvailable', (data: connection.NetHandle) => {
            Logger.info(this.LOG_TAG, `网络连接成功: ${JSON.stringify(data)}`);
            this.refreshIPBanner();
        });

        // 注册网络能力变化的监听（这是检测IP/子网变化的关键）
        this.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
            Logger.info(this.LOG_TAG, `网络能力发生变化，可能包括IP或子网: ${JSON.stringify(data)}`);
            this.refreshIPBanner();
        });

        // 注册网络丢失的监听
        this.netConnection.on('netLost', (data: connection.NetHandle) => {
            Logger.info(this.LOG_TAG, `网络连接断开: ${JSON.stringify(data)}`);
            this.refreshIPBanner();
        });

        // 开始监听
        this.netConnection.register((err: BusinessError) => {
            if (err) {
                Logger.error(this.LOG_TAG, `注册网络监听失败, ${err}`);
            }
        });
    }

    // 关闭网络监听
    // aboutToDisappear 内调用
    private stopNetListening() {
        if (this.netConnection) {
            this.netConnection.unregister((err: BusinessError) => {
                if (err) {
                    Logger.error(this.LOG_TAG, `取消注册网络监听失败，${err}`);
                }
            });
            this.netConnection = null;
        }
    }

    // 刷新广播地址
    private async refreshIPBanner() {
        await this.net.refresh();
        this.ipBannerText =
            `${CommonUtils.getStringFromResource(this.context, $r("app.string.current_broadcast_ip"))}${this.net.ipv4Broadcast}`;
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
    private async goToSpecifyPage(path: string): Promise<void> {
        // 如果应用内已经进入其他页面，返回到主页面
        if(this.pageStack.size() > 0) this.pageStack.clear();

        try {
            Logger.debug(this.LOG_TAG, `跳转至页面 ${path}`);
            this.pageStack.pushPath({
                name: path,
                param: this.deviceList,
                onPop: async (popInfo) => {
                    await this.refreshIPBanner();
                    CommonUtils.returnFromSubPage(popInfo);
                }
            });
        } catch (err) {
            Logger.error(this.LOG_TAG, `${path} 页面跳转失败, ${err}`);
        }
    }

    @Builder
    DeleteButton(device: DeviceViewModel) {
        Row() {
            Button() {
                Image($r("app.media.trash"))
                    .objectFit(ImageFit.Cover)
                    .width(StyleConstants.SIXTY_PERCENT)
                    .height(StyleConstants.SIXTY_PERCENT)
            }
            .backgroundColor(Color.Red)
            .type(ButtonType.Circle)
            .width(StyleConstants.DELETE_BUTTON_WIDTH)
            .height(StyleConstants.DELETE_BUTTON_HEIGHT)
            .onClick(() => {
                this.deviceList.deleteDevice(device.toDevice());
            })
        }
        .margin({
            left: StyleConstants.MARGIN_THREE_PERCENT,
            right: StyleConstants.MARGIN_THREE_PERCENT
        })
    }

    @Builder
    EditButton(device: DeviceViewModel) {
        Row() {
            Button() {
                Image($r("app.media.square_and_pencil"))
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
                        await this.refreshIPBanner();
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
    TabBuilder(symbol: Resource, text: Resource | string, onClick: () => void) {
        Column() {
            SymbolGlyph(symbol)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_TWENTY_TWO)
                .fontColor([$r("sys.color.font_primary")])

            Text(text)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
                .fontColor($r("sys.color.font_primary"))
        }
        .width(StyleConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.Center)
        .margin({
            left: StyleConstants.MARGIN_TWO_PERCENT,
            right: StyleConstants.MARGIN_TWO_PERCENT
        })
        .onClick(onClick)
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
                    .fontColor($r("sys.color.font_primary"))
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
        }else {
            List({ scroller: this.scrollerForList }) {
                ForEach(this.deviceList.devices, (device: DeviceViewModel) => {
                    ListItem() {
                        DeviceTile({
                            deviceMAC: device.MAC,
                            deviceAlias: device.Alias,
                            deviceAddress: device.Address,
                            devicePort: device.Port,
                            sendPacket: async (mac: string, targetAddr: string, targetPort: number) => {
                                const result = await this.net.send(mac, targetAddr, targetPort);

                                if (typeof (result) === 'boolean') CommonUtils.alert($r("app.string.send_magic_packet_success"), this.promptAction);
                                else if (typeof (result) === 'string') CommonUtils.alert($r("app.string.send_magic_packet_failed", result), this.promptAction);
                                else CommonUtils.alert($r("app.string.send_magic_packet_failed", CommonUtils.getStringFromResource(this.context, result)), this.promptAction);
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
                        right: StyleConstants.MARGIN_ONE_PERCENT,
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
            .height(StyleConstants.FULL_PERCENT)
            .width(StyleConstants.FULL_PERCENT)
        }
    }

    build() {
        HdsNavigation(this.pageStack) {
            HdsTabs({ controller: this.tabController }) {
                TabContent() {
                    Stack({ alignContent: Alignment.Top }) {
                        this.MainContent();

                        if(this.isLoading) this.LoadingContent();
                    }
                }
                .tabBar(this.TabBuilder(
                    $r("sys.symbol.plus"),
                    $r("app.string.button_Add_label"),
                    () => {
                        this.safeCloseSwipeActions();
                        this.pageStack.pushPath({
                            name: "AddDevice",
                            param: this.deviceList,
                            onPop: async (popInfo: PopInfo) => {
                                await this.refreshIPBanner();
                                CommonUtils.returnFromSubPage(popInfo);
                            }
                        });
                    }
                ))
            }
            .barPosition(BarPosition.End)
            .scrollable(false)
            .barOverlap(true)
            .barFloatingStyle({
                barBottomMargin: StyleConstants.BAR_BOTTOM_MARGIN,
                systemMaterialEffect:  {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                }
            })
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.title_label"),
                    subTitle: this.ipBannerText
                },
                menu: this.menus,
            },
            style: {
                scrollEffectOpts: { // 设置滚动特效
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                },
                systemMaterialEffect: { // 设置沉浸光感
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                },
            },
            enableComponentSafeArea: true // 启用标题栏占位
        })
        .bindToScrollable([this.scrollerForList])
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}
