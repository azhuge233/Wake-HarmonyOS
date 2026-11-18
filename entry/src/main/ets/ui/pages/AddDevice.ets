import {
    HdsNavigationMenuContentOptions,
    HdsTabs,
    HdsTabsController
} from '@kit.UIDesignKit';

import { CommonConstants } from '../../common/constants/CommonConstants';
import { StyleConstants } from '../../common/constants/StyleConstants';
import { Logger } from '../../common/log/Logger';
import { PortInput } from '../../common/util/PortInput';
import { isStringNullOrEmpty } from '../../common/util/Strings';
import { DeviceService } from '../../domain/DeviceService';
import { NeighborCandidate, NeighborService } from '../../domain/NeighborService';
import { DeviceAddViewModel, DraftIssue } from '../../viewmodel/DeviceAddViewModel';
import { AppButton } from '../component/AppButton';
import { AppEmptyState } from '../component/AppEmptyState';
import { CollapsibleDivider } from '../component/CollapsibleDivider';
import { LoadingOverlay } from '../component/LoadingOverlay';
import { NeighTableDeviceTile } from '../component/NeighTableDeviceTile';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { TabSegment } from '../component/TabSegment';
import TextItem, { INPUT_TYPE } from '../component/TextItem';
import { showToast } from '../feedback/Feedback';
import { DialogData } from './InputDialog';
import { logPopResult } from '../util/PageResult';

@Builder
export function AddDeviceBuilder() {
    AddDevice();
}

@ComponentV2
struct AddDevice {
    private LOG_TAG = '[ui/pages/AddDevice]';

    @Local showAdvanced: boolean = false;
    // 页签下标：自绘分段与内容区滑动双向联动共用的唯一状态
    @Local activeTab: number = 0;

    private viewModel: DeviceAddViewModel = new DeviceAddViewModel(DeviceService.instance(),
        NeighborService.instance());

    private uiContext = this.getUIContext();
    private promptAction = this.uiContext.getPromptAction();
    private focusController = this.uiContext.getFocusController();
    private tabController: HdsTabsController = new HdsTabsController();

    pathStack: NavPathStack | undefined = undefined;

    private menus: HdsNavigationMenuContentOptions = {
        value: [
            {
                content: {
                    label: $r('app.string.help_title'),
                    icon: $r('sys.symbol.questionmark_circle'),
                    action: () => {
                        this.pathStack?.pushPath({
                            name: 'Help',
                            param: this.pathStack,
                            onPop: (popInfo: PopInfo) => {
                                logPopResult(this.LOG_TAG, popInfo);
                            }
                        });
                    }
                }
            }
        ]
    };

    async aboutToAppear(): Promise<void> {
        await this.viewModel.loadNeighbors();
    }

    private issueText(issue: DraftIssue): Resource {
        if (issue === 'empty') return $r('app.string.input_cannot_be_null_or_empty');
        if (issue === 'port') return $r('app.string.port_invalid');
        if (issue === 'mac-short') return $r('app.string.validate_mac_too_short');
        if (issue === 'mac-format') return $r('app.string.validate_mac_regex_fail');
        return $r('app.string.input_cannot_be_null_or_empty');
    }

    private focusForIssue(issue: DraftIssue): void {
        try {
            if (issue === 'empty') {
                if (isStringNullOrEmpty(this.viewModel.draft.MAC.trim())) {
                    this.focusController.requestFocus(CommonConstants.MAC_INPUT_ID);
                } else {
                    this.focusController.requestFocus(CommonConstants.ALIAS_INPUT_ID);
                }
            } else if (issue === 'port') {
                this.focusController.requestFocus(CommonConstants.PORT_INPUT_ID);
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `移动输入焦点失败, ${err}`);
        }
    }

    private clearInput(): void {
        this.viewModel.resetDraft();
    }

    /** 点自绘页签：先移高亮再切内容，两向由同一个下标驱动 */
    private selectTab(index: number): void {
        this.activeTab = index;
        this.tabController.changeIndex(index);
    }

    private async saveDeviceManual(): Promise<void> {
        const issue: DraftIssue = this.viewModel.validate();
        if (issue !== 'none') {
            showToast(this.promptAction, this.issueText(issue));
            this.focusForIssue(issue);
            return;
        }

        const alias: string = this.viewModel.draft.Alias.trim();
        const added = await this.viewModel.add();
        if (added) {
            showToast(this.promptAction, $r('app.string.add_machine_success', alias));
            this.clearInput();
        } else {
            showToast(this.promptAction, $r('app.string.add_machine_failed', alias));
        }
    }

    private async inputPopup(): Promise<DialogData | undefined> {
        return new Promise((resolve) => {
            this.pathStack?.pushPath({
                name: 'InputDialog',
                param: this.pathStack,
                onPop: (popInfo: PopInfo) => {
                    logPopResult(this.LOG_TAG, popInfo);
                    resolve(popInfo.result as DialogData | undefined);
                }
            });
        });
    }

    private async addFromNeighbor(entry: NeighborCandidate): Promise<void> {
        this.clearInput();

        const dialogData = await this.inputPopup();
        if (dialogData === undefined) {
            Logger.warn(this.LOG_TAG, '取消添加设备');
            return;
        }

        const address: string = dialogData.ignoreIP ? '' : entry.ip;
        const added = await this.viewModel.addWith(entry.mac, dialogData.deviceAlias, address,
            PortInput.DEFAULT_PORT);

        if (added) {
            showToast(this.promptAction, $r('app.string.add_machine_success', dialogData.deviceAlias));
            this.viewModel.removeNeighbor(entry.ip, entry.mac);
        } else {
            showToast(this.promptAction, $r('app.string.add_machine_failed', dialogData.deviceAlias));
        }

        this.clearInput();
    }

    @Builder
    NeighTableDeviceList() {
        if (this.viewModel.neighbors.length === 0) {
            AppEmptyState({
                text: $r('app.string.neigh_table_press_load_label')
            })
        } else {
            List() {
                ForEach(this.viewModel.neighbors, (item: NeighborCandidate) => {
                    ListItem() {
                        NeighTableDeviceTile({
                            entry: item,
                            onAdd: () => {
                                this.addFromNeighbor(item).catch((err: Error) => {
                                    Logger.error(this.LOG_TAG, `从邻居表添加设备失败, ${err}`);
                                });
                            }
                        })
                            .margin({
                                top: StyleConstants.CARD_SPACE,
                                bottom: StyleConstants.CARD_SPACE
                            })
                    }
                }, (item: NeighborCandidate) => item.mac + item.ip)
            }
            .width('100%')
            .height('100%')
            .padding({
                top: 2,
                // 卡片横向内缩：与主界面设备列表同档，纵向间距由 ListItem 的 CARD_SPACE 承担
                left: StyleConstants.PAGE_PADDING,
                right: StyleConstants.PAGE_PADDING
            })
        }
    }

    @Builder
    ManualAdd() {
        Scroll() {
            Column() {
                Blank()
                    .layoutWeight(1)

                TextItem({
                    inputType: INPUT_TYPE.MAC,
                    inputId: CommonConstants.MAC_INPUT_ID,
                    isDefaultFocus: true,
                    label: $r('app.string.add_mac_input_label'),
                    placeholder: $r('app.string.add_mac_input_placeholder'),
                    value: this.viewModel.draft.MAC,
                    onValueChange: (value: string) => {
                        this.viewModel.draft.MAC = value;
                    }
                })
                    .width('80%')

                TextItem({
                    inputType: INPUT_TYPE.ALIAS,
                    inputId: CommonConstants.ALIAS_INPUT_ID,
                    label: $r('app.string.add_alias_input_label'),
                    placeholder: $r('app.string.add_alias_input_placeholder'),
                    value: this.viewModel.draft.Alias,
                    onValueChange: (value: string) => {
                        this.viewModel.draft.Alias = value;
                    }
                })
                    .width('80%')

                Column() {
                    CollapsibleDivider({
                        label: $r('app.string.divider_label'),
                        expanded: this.showAdvanced,
                        onToggle: () => {
                            this.showAdvanced = !this.showAdvanced;
                        }
                    })

                    if (this.showAdvanced) {
                        TextItem({
                            inputType: INPUT_TYPE.ADDRESS,
                            inputId: CommonConstants.ADDRESS_INPUT_ID,
                            label: $r('app.string.add_address_input_label'),
                            placeholder: $r('app.string.add_address_input_placeholder'),
                            value: this.viewModel.draft.Address,
                            onValueChange: (value: string) => {
                                this.viewModel.draft.Address = value;
                            }
                        })
                            .width('80%')

                        TextItem({
                            inputType: INPUT_TYPE.PORT,
                            inputId: CommonConstants.PORT_INPUT_ID,
                            label: $r('app.string.add_port_input_label'),
                            placeholder: $r('app.string.add_port_input_placeholder'),
                            value: this.viewModel.portText,
                            onValueChange: (value: string) => {
                                this.viewModel.portText = value;
                            }
                        })
                            .width('80%')
                    }
                }
                .alignItems(HorizontalAlign.Center)

                AppButton({
                    label: $r('app.string.button_add_machine_confirm'),
                    isEnabled: !isStringNullOrEmpty(this.viewModel.draft.MAC.trim()) &&
                        !isStringNullOrEmpty(this.viewModel.draft.Alias.trim()),
                    onTap: () => {
                        this.saveDeviceManual().catch((err: Error) => {
                            Logger.error(this.LOG_TAG, `保存设备失败, ${err}`);
                        });
                    }
                })
                    .width('70%')
                    .margin({
                        top: '10%'
                    })

                Blank()
                    .layoutWeight(1)
            }
            .width('100%')
        }
        .width('100%')
    }

    @Builder
    NeighTableAdd() {
        Column() {
            Row() {
                Blank().layoutWeight(1)

                Text($r('app.string.neigh_table_device_total_label', this.viewModel.neighbors.length))
                    .fontColor($r('sys.color.font_tertiary'))
                    .fontSize(14)
            }
            .width('100%')
            .height('3%')
            .padding({
                right: 30
            })

            Stack() {
                this.NeighTableDeviceList();

                if (this.viewModel.isNeighborPermissionDenied) {
                    Text($r('app.string.neigh_table_permission_denied'))
                        .width('100%')
                        .textAlign(TextAlign.Center)
                        .fontSize(13)
                        .fontColor($r('sys.color.font_secondary'))
                        .padding({
                            left: 30,
                            right: 30
                        })
                }

                if (this.viewModel.isLoadingNeighbors) {
                    LoadingOverlay({ message: $r('app.string.neigh_table_loading_message') })
                }
            }
            .width('100%')
            .height('85%')

            Column() {
                Blank()
                    .layoutWeight(1)

                AppButton({
                    label: this.viewModel.neighbors.length !== 0 ?
                        $r('app.string.neigh_table_reload_button_label') : $r('app.string.neigh_table_load_button_label'),
                    isEnabled: !this.viewModel.isLoadingNeighbors,
                    onTap: () => {
                        this.viewModel.loadNeighbors().catch((err: Error) => {
                            Logger.error(this.LOG_TAG, `加载邻居表失败, ${err}`);
                        });
                    }
                })
                    .width('70%')

                Blank()
                    .layoutWeight(1)
            }
            .width('100%')
            .height('10%')
        }
        .width('100%')
    }

    @Builder
    PageContent() {
        Column() {
            TabSegment({
                titles: [
                    $r('app.string.manual_add_device_tab_title'),
                    $r('app.string.neigh_table_add_device_tab_title')
                ],
                activeIndex: this.activeTab,
                onSelect: (index: number) => {
                    this.selectTab(index);
                }
            })

            HdsTabs({
                controller: this.tabController,
                barPosition: BarPosition.Start
            }) {
                TabContent() {
                    this.ManualAdd();
                }

                TabContent() {
                    this.NeighTableAdd();
                }
            }
            // 原生页签栏收起：0 是 SDK 的合法取值，只有负值与超界值才回落默认高
            .barHeight(0)
            .layoutWeight(1)
            .width(StyleConstants.FULL_PERCENT)
            // 左右滑动切换页签：与网络信息页同一行，两页写法一致
            .scrollable(true)
            // 滑动内容区时高亮跟随：动画开始即移到目标段，切换完成再校正一次
            .onAnimationStart((index: number, targetIndex: number) => {
                this.activeTab = targetIndex;
            })
            .onChange((index: number) => {
                this.activeTab = index;
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
    }

    @Builder
    PageOverlay() {
    }

    build() {
        PageScaffold({
            title: $r('app.string.add_machine_title'),
            logTag: this.LOG_TAG,
            centered: true,
            menuOptions: this.menus,
            content: (): void => {
                this.PageContent();
            },
            overlayContent: (): void => {
                this.PageOverlay();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            },
            onBack: () => {
                this.pathStack?.pop('Back pressed');
                return true;
            }
        })
    }
}