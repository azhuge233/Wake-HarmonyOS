import { common } from '@kit.AbilityKit';
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';

import { Logger } from '../../common/log/Logger';
import {
    DefaultNetSnapshot,
    Ipv4Snapshot,
    Ipv6Snapshot,
    NetworkBearerKey,
    NetworkCapabilityKey,
    NetworkSnapshot
} from '../../common/ports/NetworkInfoPort';
import { NetworkInfoService } from '../../domain/NetworkInfoService';
import { NetworkInfoViewModel } from '../../viewmodel/NetworkInfoViewModel';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { resourceText } from '../util/ResourceText';

type InfoRow = [Resource, string | Resource];

function capabilityResource(key: NetworkCapabilityKey): Resource {
    switch (key) {
        case 'mms':
            return $r('app.string.network_info_net_cap_mms');
        case 'not-metered':
            return $r('app.string.network_info_net_cap_not_metered');
        case 'internet':
            return $r('app.string.network_info_net_cap_internet');
        case 'not-vpn':
            return $r('app.string.network_info_net_cap_not_vpn');
        case 'validated':
            return $r('app.string.network_info_net_cap_validated');
        case 'portal':
            return $r('app.string.network_info_net_cap_portal');
        case 'checking-connectivity':
            return $r('app.string.network_info_net_cap_check_conn');
        default:
            return $r('app.string.network_info_default_net_link_bandwidth_cannot_measure');
    }
}

function bearerResource(key: NetworkBearerKey): Resource {
    switch (key) {
        case 'cellular':
            return $r('app.string.network_info_default_net_bearer_cellular');
        case 'wifi':
            return $r('app.string.network_info_default_net_bearer_wifi');
        case 'bluetooth':
            return $r('app.string.network_info_default_net_bearer_bluetooth');
        case 'ethernet':
            return $r('app.string.network_info_default_net_bearer_ethernet');
        case 'vpn':
            return $r('app.string.network_info_default_net_bearer_vpn');
        default:
            return $r('app.string.network_info_default_net_link_bandwidth_cannot_measure');
    }
}

@Builder
export function NetworkInfoBuilder() {
    NetworkInfo();
}

@ComponentV2
struct NetworkInfo {
    private LOG_TAG = '[ui/pages/NetworkInfo]';

    @Local basicInfoList: Array<InfoRow> = [];
    @Local v4InfoList: Array<InfoRow> = [];
    @Local v6InfoList: Array<InfoRow> = [];
    @Local defaultNetInfoList: Array<InfoRow> = [];

    private viewModel: NetworkInfoViewModel = new NetworkInfoViewModel(NetworkInfoService.instance());

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    private listScrollers: Array<ListScroller> = [
        new ListScroller(), new ListScroller(), new ListScroller(), new ListScroller()
    ];
    private tabController: HdsTabsController = new HdsTabsController();

    pathStack: NavPathStack | undefined = undefined;

    async aboutToAppear(): Promise<void> {
        await this.viewModel.load();
        this.renderLists();
        Logger.debug(this.LOG_TAG, 'refreshNetwork');
    }

    private renderLists(): void {
        const snapshot: NetworkSnapshot | null = this.viewModel.snapshot;
        if (snapshot === null) return;

        this.basicInfoList = this.basicRows(snapshot);
        this.v4InfoList = this.ipv4Rows(snapshot.ipv4);
        this.v6InfoList = this.ipv6Rows(snapshot.ipv6);
        this.defaultNetInfoList = this.defaultNetRows(snapshot.defaultNet);
    }

    private basicRows(snapshot: NetworkSnapshot): Array<InfoRow> {
        const rows: Array<InfoRow> = [];
        rows.push([$r('app.string.network_info_is_active'),
            snapshot.wifiActive ? $r('app.string.network_info_on') : $r('app.string.network_info_off')]);
        rows.push([$r('app.string.network_info_is_connected'),
            snapshot.wifiConnected ? $r('app.string.network_info_yes') : $r('app.string.network_info_no')]);
        rows.push([$r('app.string.network_info_is_hotspot'),
            snapshot.hotspot ? $r('app.string.network_info_yes') : $r('app.string.network_info_no')]);
        return rows;
    }

    private ipv4Rows(info: Ipv4Snapshot | null): Array<InfoRow> {
        const rows: Array<InfoRow> = [];
        if (info === null) return rows;

        rows.push([$r('app.string.network_info_v4_address'), info.address]);
        rows.push([$r('app.string.network_info_v4_gateway'), info.gateway]);
        rows.push([$r('app.string.network_info_v4_netmask'), info.netmask]);
        rows.push([$r('app.string.network_info_v4_primary_dns'), info.primaryDns]);
        rows.push([$r('app.string.network_info_v4_secondary_dns'), info.secondaryDns]);
        rows.push([$r('app.string.network_info_v4_dhcp_server'), info.dhcpServer]);
        rows.push([$r('app.string.network_info_v4_dhcp_lease'), `${info.leaseSeconds} s`]);
        return rows;
    }

    private ipv6Rows(info: Ipv6Snapshot | null): Array<InfoRow> {
        const rows: Array<InfoRow> = [];
        if (info === null) return rows;

        rows.push([$r('app.string.network_info_v6_link_address'), info.link]);
        rows.push([$r('app.string.network_info_v6_global_address'), info.global]);
        rows.push([$r('app.string.network_info_v6_random_global_address'), info.randomGlobal]);
        rows.push([$r('app.string.network_info_v6_unique_address'), info.unique]);
        rows.push([$r('app.string.network_info_v6_random_unique_address'), info.randomUnique]);
        rows.push([$r('app.string.network_info_v6_gateway'), info.gateway]);
        rows.push([$r('app.string.network_info_v6_netmask'), info.netmask]);
        rows.push([$r('app.string.network_info_v6_primary_dns'), info.primaryDns]);
        rows.push([$r('app.string.network_info_v6_secondary_dns'), info.secondaryDns]);
        return rows;
    }

    private defaultNetRows(info: DefaultNetSnapshot | null): Array<InfoRow> {
        const rows: Array<InfoRow> = [];
        if (info === null) {
            rows.push([$r('app.string.network_info_system_default_net'),
                $r('app.string.network_info_no_system_default_net')]);
            return rows;
        }

        const cannotMeasure: Resource = $r('app.string.network_info_default_net_link_bandwidth_cannot_measure');
        rows.push([$r('app.string.network_info_default_net_up_speed'),
            info.upKbps === 0 ? cannotMeasure : `${info.upKbps} Kbps`]);
        rows.push([$r('app.string.network_info_default_net_down_speed'),
            info.downKbps === 0 ? cannotMeasure : `${info.downKbps} Kbps`]);

        const caps: string = info.capabilities
            .map((key: NetworkCapabilityKey) => resourceText(capabilityResource(key), this.context))
            .join(', ');
        rows.push([$r('app.string.network_info_default_net_cap'), caps === '' ? cannotMeasure : caps]);

        const bearers: string = info.bearers
            .map((key: NetworkBearerKey) => resourceText(bearerResource(key), this.context))
            .join(', ');
        rows.push([$r('app.string.network_info_default_net_bearer_type'), bearers]);

        return rows;
    }

    @Builder
    ListBuilder(list: Array<InfoRow>, listScroller: ListScroller) {
        List({ scroller: listScroller }) {
            ForEach(list, (item: InfoRow) => {
                ListItem() {
                    Column() {
                        Text(item[0])
                            .width('100%')
                            .textAlign(TextAlign.Start)
                            .fontWeight(FontWeight.Medium)
                            .margin({
                                bottom: 3
                            })
                            .padding({
                                top: 2
                            })

                        Text(item[1])
                            .width('100%')
                            .textAlign(TextAlign.Start)
                            .fontColor($r('sys.color.font_secondary'))
                            .textOverflow({
                                overflow: TextOverflow.MARQUEE
                            })
                    }
                    .margin({
                        top: 3,
                        bottom: 3
                    })
                }
                .width('85%')
                .padding({
                    left: 5,
                    right: 5
                })
                .border({
                    width: {
                        bottom: 0.5
                    },
                    color: $r('sys.color.font_tertiary')
                })
            }, (item: InfoRow, index: number) => index.toString())
        }
        .width('100%')
        .height('100%')
        .alignListItem(ListItemAlign.Center)
    }

    @Builder
    PageContent() {
        HdsTabs({
            controller: this.tabController,
            barPosition: BarPosition.Start
        }) {
            TabContent() {
                this.ListBuilder(this.basicInfoList, this.listScrollers[0]);
            }.tabBar($r('app.string.network_info_basic_tab_title'))

            TabContent() {
                this.ListBuilder(this.v4InfoList, this.listScrollers[1]);
            }.tabBar($r('app.string.network_info_v4_tab_title'))

            TabContent() {
                this.ListBuilder(this.v6InfoList, this.listScrollers[2]);
            }.tabBar($r('app.string.network_info_v6_tab_title'))

            TabContent() {
                this.ListBuilder(this.defaultNetInfoList, this.listScrollers[3]);
            }.tabBar($r('app.string.network_info_default_network_tab_title'))
        }
        .barMode(BarMode.Scrollable)
        .scrollable(true)
        .barFloatingStyle({
            systemMaterialEffect: {
                materialType: hdsMaterial.MaterialType.ADAPTIVE,
                materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
            }
        })
    }

    @Builder
    PageOverlay() {
    }

    build() {
        PageScaffold({
            title: $r('app.string.network_info_title'),
            logTag: this.LOG_TAG,
            fillSize: true,
            bindScrollables: this.listScrollers as Scroller[],
            content: (): void => {
                this.PageContent();
            },
            overlayContent: (): void => {
                this.PageOverlay();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            }
        })
    }
}