import { wifiManager } from '@kit.ConnectivityKit';
import { connection } from '@kit.NetworkKit';
import { common } from '@kit.AbilityKit';
import { hdsMaterial, HdsNavDestination, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';

import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';
import CommonUtils from '../common/utils/CommonUtils';

@Builder
export function NetworkInfoBuilder() {
    NetworkInfo();
}

@Entry
@ComponentV2
struct NetworkInfo {
    private LOG_TAG = '[pages/NetworkInfo]';

    @Local isProcessing: boolean = false;

    @Local basicInfoList: Array<[string | Resource, string | Resource]> = [];
    @Local v4InfoList: Array<[string | Resource, string | Resource]> = [];
    @Local v6InfoList: Array<[string | Resource, string | Resource]> = [];
    @Local defaultNetInfoList: Array<[string | Resource, string | Resource]> = [];

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    private listScrollers: Array<ListScroller> = [];
    private tabController: HdsTabsController = new HdsTabsController();

    pathStack: NavPathStack | undefined = undefined;

    private capMap: Map<connection.NetCap, Resource> = new Map([
        [connection.NetCap.NET_CAPABILITY_MMS, $r("app.string.network_info_net_cap_mms")],
        [connection.NetCap.NET_CAPABILITY_NOT_METERED, $r("app.string.network_info_net_cap_not_metered")],
        [connection.NetCap.NET_CAPABILITY_INTERNET, $r("app.string.network_info_net_cap_internet")],
        [connection.NetCap.NET_CAPABILITY_NOT_VPN, $r("app.string.network_info_net_cap_not_vpn")],
        [connection.NetCap.NET_CAPABILITY_VALIDATED, $r("app.string.network_info_net_cap_validated")],
        [connection.NetCap.NET_CAPABILITY_PORTAL, $r("app.string.network_info_net_cap_portal")],
        [connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY, $r("app.string.network_info_net_cap_check_conn")]
    ]);

    private netBearerMap: Map<connection.NetBearType, Resource> = new Map([
        [connection.NetBearType.BEARER_CELLULAR, $r("app.string.network_info_default_net_bearer_cellular")],
        [connection.NetBearType.BEARER_WIFI, $r("app.string.network_info_default_net_bearer_wifi")],
        [connection.NetBearType.BEARER_BLUETOOTH, $r("app.string.network_info_default_net_bearer_bluetooth")],
        [connection.NetBearType.BEARER_ETHERNET, $r("app.string.network_info_default_net_bearer_ethernet")],
        [connection.NetBearType.BEARER_VPN, $r("app.string.network_info_default_net_bearer_vpn")]
    ]);

    aboutToAppear(): void {
        this.listScrollers = [
          new ListScroller(), new ListScroller(), new ListScroller(), new ListScroller()
        ];

        this.init();
    }

    private init() {
        this.isProcessing = true;

        this.getWifiInfo();
        this.getIPv4Info();
        this.getIPv6Info();
        this.getNetworkInfo();

        Logger.debug(this.LOG_TAG, "refreshNetwork");
        this.isProcessing = false;
    }

    private getWifiInfo() {
        try {
            let tempInfoList: Array<[string | Resource, string | Resource]> = [];

            tempInfoList.push([
              $r("app.string.network_info_is_active"),
                wifiManager.isWifiActive() ? $r("app.string.network_info_on") : $r("app.string.network_info_off")
            ]);
            tempInfoList.push([
              $r("app.string.network_info_is_connected"),
                wifiManager.isWifiActive() && wifiManager.isConnected() ? $r("app.string.network_info_yes") : $r("app.string.network_info_no")
            ]);
            tempInfoList.push([
                $r("app.string.network_info_is_hotspot"),
                wifiManager.isWifiActive() && wifiManager.isConnected() && wifiManager.isMeteredHotspot() ? $r("app.string.network_info_yes") : $r("app.string.network_info_no")
            ]);

            this.basicInfoList = tempInfoList;
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取 Wifi 信息错误, ${JSON.stringify(err)}`);
        }
    }

    private getIPv4Info() {
        try {
            let tempInfoList: Array<[string | Resource, string | Resource]> = [];

            const info = wifiManager.getIpInfo();

            tempInfoList.push([$r("app.string.network_info_v4_address"), CommonUtils.getIpStringFromNum(info.ipAddress)]);
            tempInfoList.push([$r("app.string.network_info_v4_gateway"), CommonUtils.getIpStringFromNum(info.gateway)]);
            tempInfoList.push([$r("app.string.network_info_v4_netmask"), CommonUtils.getIpStringFromNum(info.netmask)]);
            tempInfoList.push([$r("app.string.network_info_v4_primary_dns"), CommonUtils.getIpStringFromNum(info.primaryDns)]);
            tempInfoList.push([$r("app.string.network_info_v4_secondary_dns"), CommonUtils.getIpStringFromNum(info.secondDns)]);
            tempInfoList.push([$r("app.string.network_info_v4_dhcp_server"), CommonUtils.getIpStringFromNum(info.serverIp)]);
            tempInfoList.push([$r("app.string.network_info_v4_dhcp_lease"), `${info.leaseDuration} s`]);

            this.v4InfoList = tempInfoList;
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取 IPv4 信息错误, ${JSON.stringify(err)}`);
        }
    }

    private getIPv6Info() {
        try {
            let tempInfoList: Array<[string | Resource, string | Resource]> = [];

            const info = wifiManager.getIpv6Info();

            tempInfoList.push([$r("app.string.network_info_v6_link_address"), info.linkIpv6Address]);
            tempInfoList.push([$r("app.string.network_info_v6_global_address"), info.globalIpv6Address]);
            tempInfoList.push([$r("app.string.network_info_v6_random_global_address"), info.randomGlobalIpv6Address]);
            tempInfoList.push([$r("app.string.network_info_v6_unique_address"), info.uniqueIpv6Address ?? '-']);
            tempInfoList.push([$r("app.string.network_info_v6_random_unique_address"), info.randomUniqueIpv6Address ?? '-']);
            tempInfoList.push([$r("app.string.network_info_v6_gateway"), info.gateway]);
            tempInfoList.push([$r("app.string.network_info_v6_netmask"), info.netmask]);
            tempInfoList.push([$r("app.string.network_info_v6_primary_dns"), info.primaryDNS]);
            tempInfoList.push([$r("app.string.network_info_v6_secondary_dns"), info.secondDNS]);

            this.v6InfoList = tempInfoList;
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取 IPv6 信息错误, ${JSON.stringify(err)}`);
        }
    }

    private getNetworkInfo() {
        try {
            let tempInfoList: Array<[string | Resource, string | Resource]> = [];

            const defaultNet = connection.getDefaultNetSync();
            if(defaultNet.netId === 0) tempInfoList.push([$r("app.string.network_info_system_default_net"), $r("app.string.network_info_no_system_default_net")]);
            else {
                const capabilities = connection.getNetCapabilitiesSync(defaultNet);

                tempInfoList.push([
                  $r("app.string.network_info_default_net_up_speed"),
                    capabilities.linkUpBandwidthKbps === 0 ? $r("app.string.network_info_default_net_link_bandwidth_cannot_measure")  : `${capabilities.linkUpBandwidthKbps} Kbps`
                ]);
                tempInfoList.push([
                  $r("app.string.network_info_default_net_down_speed"),
                    capabilities.linkDownBandwidthKbps === 0 ? $r("app.string.network_info_default_net_link_bandwidth_cannot_measure") : `${capabilities.linkDownBandwidthKbps} Kbps`
                ]);

                tempInfoList.push([$r("app.string.network_info_default_net_cap"), capabilities.networkCap?.map(cap => this.getNetCapString(cap)).join(", ") ?? $r("app.string.network_info_default_net_link_bandwidth_cannot_measure")]);
                tempInfoList.push([$r("app.string.network_info_default_net_bearer_type"), capabilities.bearerTypes.map(bearer => this.getBearerTypeString(bearer)).join(", ")]);
            }

            this.defaultNetInfoList = tempInfoList;
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取默认网络信息失败, ${JSON.stringify(err)}`);
        }
    }

    private getNetCapString(cap: connection.NetCap): string {
        try {
            const result: Resource = this.capMap.get(cap) ?? $r("app.string.network_info_default_net_link_bandwidth_cannot_measure");
            return this.context.resourceManager.getStringSync(result.id);
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取网络能力字符串失败, ${err}`);
            return '';
        }
    }

    private getBearerTypeString(bearer: connection.NetBearType): string {
        try {
            const result: Resource = this.netBearerMap.get(bearer) ?? $r("app.string.network_info_default_net_link_bandwidth_cannot_measure");
            return this.context.resourceManager.getStringSync(result.id);
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取网络类型字符串失败, ${err}`);
            return '';
        }
    }

    @Builder
    EntryDivider() {
        Divider()
            .lineCap(LineCapStyle.Round)
            .strokeWidth(StyleConstants.DIVIDER_STOKE_WIDTH)
            .width(StyleConstants.FULL_PERCENT)
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
    ListBuilder(list: Array<[string | Resource, string | Resource]>, listScroller: ListScroller) {
        List({ scroller: listScroller }) {
            ForEach(list, (item: [string | Resource, string | Resource]) => {
                ListItem() {
                    Column() {
                        Text(item[0])
                            .width(StyleConstants.FULL_PERCENT)
                            .textAlign(TextAlign.Start)
                            .fontWeight(FontWeight.Medium)
                            .margin({
                                bottom: StyleConstants.MARGIN_THREE
                            })
                            .padding({
                                top: StyleConstants.PADDING_TWO
                            })

                        Text(item[1])
                            .width(StyleConstants.FULL_PERCENT)
                            .textAlign(TextAlign.Start)
                            .fontColor($r("sys.color.font_secondary"))
                            .textOverflow({
                                overflow: TextOverflow.MARQUEE
                            })
                    }
                    .margin({
                        top: StyleConstants.MARGIN_THREE,
                        bottom: StyleConstants.MARGIN_THREE
                    })
                }
                .width(StyleConstants.EIGHTY_FIVE_PERCENT)
                .padding({
                    left: StyleConstants.PADDING_FIVE,
                    right: StyleConstants.PADDING_FIVE
                })
                .border({
                    width: {
                        bottom: StyleConstants.BORDER_WIDTH
                    },
                    color: $r("sys.color.font_tertiary")
                })
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .alignListItem(ListItemAlign.Center)
    }

    @Builder
    MainContent() {
        HdsTabs({
            controller: this.tabController,
            barPosition: BarPosition.Start
        }) {
            TabContent() {
                this.ListBuilder(this.basicInfoList, this.listScrollers[0]);
            }.tabBar($r("app.string.network_info_basic_tab_title"))

            TabContent() {
                this.ListBuilder(this.v4InfoList, this.listScrollers[1]);
            }.tabBar($r("app.string.network_info_v4_tab_title"))

            TabContent() {
                this.ListBuilder(this.v6InfoList, this.listScrollers[2]);
            }.tabBar($r("app.string.network_info_v6_tab_title"))

            TabContent() {
                this.ListBuilder(this.defaultNetInfoList, this.listScrollers[3]);
            }.tabBar($r("app.string.network_info_default_network_tab_title"))
        }
        .barMode(BarMode.Scrollable)
        .scrollable(true)
        .barFloatingStyle({
            systemMaterialEffect:  {
                materialType: hdsMaterial.MaterialType.ADAPTIVE,
                materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
            }
        })
    }

    build() {
        HdsNavDestination() {
            Stack({ alignContent: Alignment.Top }) {
                this.MainContent();

                if (this.isProcessing) this.LoadingContent();
            }
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.network_info_title")
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
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .bindToScrollable(this.listScrollers)
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}