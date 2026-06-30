import { hdsMaterial, HdsNavDestination, HdsNavigationMenuContentOptions, HdsTabs,
    HdsTabsController } from '@kit.UIDesignKit';
import { connection } from '@kit.NetworkKit';

import Logger from '../common/utils/Logger';
import TextItem, { INPUT_TYPE } from '../view/TextItem';
import StyleConstants from '../common/constants/StyleConstants';
import CommonConstants from '../common/constants/CommonConstants';
import CommonUtils from '../common/utils/CommonUtils';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';
import NET from '../common/utils/NET';
import NeighTableDeviceTile from '../view/NeighTableDeviceTile';
import { DialogData } from '../view/InputDialog';

@Builder
export function AddDeviceBuilder() {
    AddDevice();
}

@Entry
@ComponentV2
struct AddDevice {
    private LOG_TAG = '[pages/AddDevice]'

    @Local newDevice: DeviceViewModel = new DeviceViewModel();
    @Local neighTableDevices: connection.NetIpMacInfo[] | null = null;

    @Local showAdvanced: boolean = false;
    @Local isLoadingNeighTable: boolean = false;

    private uiContext = this.getUIContext();
    private promptAction = this.uiContext.getPromptAction();
    private focusController = this.uiContext.getFocusController();
    private tabController: HdsTabsController = new HdsTabsController();

    private deviceList: DeviceListViewModel = new DeviceListViewModel();

    private menus: HdsNavigationMenuContentOptions = {
        value: [
            {
                content: {
                    label: $r("app.string.help_title"),
                    icon: $r("sys.symbol.info_circle"),
                    action: () => {
                        this.pageStack?.pushPath({
                            name: "Help",
                            param: this.deviceList,
                            onPop: async (popInfo: PopInfo) => {
                                CommonUtils.returnFromSubPage(popInfo);
                            }
                        });
                    }
                }
            }
        ]
    };

    private net = new NET();

    pageStack: NavPathStack | undefined = undefined;

    async aboutToAppear(): Promise<void> {
        await this.loadNeighTable();
    }

    private clearInput() {
        this.newDevice.MAC = '';
        this.newDevice.Alias = '';
        this.newDevice.Address = '';
        this.newDevice.Port = 9;
    }

    private async saveDeviceManual() {
        const mac = this.newDevice.MAC.trim();
        const alias = this.newDevice.Alias.trim();
        const address = this.newDevice.Address.trim();
        const port = this.newDevice.Port;

        try {
            if (CommonUtils.isStringNullOrEmpty(mac)) {
                CommonUtils.alert($r("app.string.input_cannot_be_null_or_empty"), this.promptAction);
                this.focusController.requestFocus(CommonConstants.MAC_INPUT_ID);
                return;
            }

            if (CommonUtils.isStringNullOrEmpty(alias)) {
                CommonUtils.alert($r("app.string.input_cannot_be_null_or_empty"), this.promptAction);
                this.focusController.requestFocus(CommonConstants.ALIAS_INPUT_ID);
                return;
            }

            if (!CommonUtils.isStringNullOrEmpty(port.toString())) {
                if (port < 1 || port > 65535) {
                    CommonUtils.alert($r("app.string.port_invalid"), this.promptAction);
                    this.focusController.requestFocus(CommonConstants.PORT_INPUT_ID);
                    return;
                }
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `移动输入焦点失败, ${err}`);
        }

        const validateResult = CommonUtils.macValidate(mac);

        if (validateResult != '') {
            CommonUtils.alert(validateResult, this.promptAction);
            return;
        }

        try {
            const success = await this.deviceList.addDevice(this.newDevice.toDevice());
            if(success) {
                Logger.debug(this.LOG_TAG, `设备已添加 - MAC: ${mac}, Alias: ${alias}, Address: ${address}, Port: ${port}`);
                this.clearInput();
                CommonUtils.alert($r("app.string.add_machine_success", alias), this.promptAction);
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `保存设备失败: ${JSON.stringify(err)}`);
            CommonUtils.alert($r("app.string.add_machine_failed", alias), this.promptAction);
        }
    }

    private async loadNeighTable() {
        this.isLoadingNeighTable = true;

        try {
            const table = await this.net.getIPNeighTable();

            if (!table) CommonUtils.alert($r("app.string.neigh_table_empty"), this.promptAction);
            else this.neighTableDevices = table;
        } catch (err) {
            CommonUtils.alert($r("app.string.load_neigh_table_failed"), this.promptAction);
        }

        this.isLoadingNeighTable = false;
    }

    private isNeighTableEmpty(): boolean {
        return this.neighTableDevices === null || this.neighTableDevices.length === 0;
    }

    private async inputPopup(): Promise<DialogData | string> {
        return new Promise((resolve) => {
            this.pageStack?.pushPath({
                name: "InputDialog",
                onPop: (popInfo) => {
                    CommonUtils.returnFromSubPage(popInfo);
                    resolve(popInfo.result as DialogData);
                }
            });
        });
    }

    private async deleteAddedDevice(mac: string, ip: string) {
        try {
            const index = this.neighTableDevices?.findIndex((item: connection.NetIpMacInfo) => item.macAddress === mac && item.ipAddress.address === ip);

            Logger.debug(this.LOG_TAG, `待删除设备下标: ${index}`);

            if (index !== undefined && index !== -1) this.neighTableDevices?.splice(index, 1);

            Logger.debug(this.LOG_TAG, `已从邻居表中删除设备 - MAC: ${mac}, IP: ${ip}`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `从邻居表中删除设备失败, ${JSON.stringify(err)}`);
        }
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

                Text($r("app.string.neigh_table_loading_message"))
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
    NeighTableDeviceList() {
        if (!this.isNeighTableEmpty()) {
             List() {
                ForEach(this.neighTableDevices, (item: connection.NetIpMacInfo) => {
                    ListItem() {
                        NeighTableDeviceTile({
                            deviceMAC: item.macAddress,
                            deviceAddress: item.ipAddress.address,
                            deviceInterface: item.iface,
                            addDevice: async () => {
                                this.clearInput();
                                const dialogData = await this.inputPopup();

                                if(typeof(dialogData) === "string") Logger.warn(this.LOG_TAG, `取消添加设备`);
                                else {
                                    this.newDevice.MAC = item.macAddress;
                                    this.newDevice.Alias = dialogData.deviceAlias;

                                    if(!dialogData.ignoreIP) this.newDevice.Address = item.ipAddress.address;

                                    const success = await this.deviceList.addDevice(this.newDevice.toDevice());

                                    try {
                                        if(success) {
                                            CommonUtils.alert($r("app.string.add_machine_success", this.newDevice.Alias), this.promptAction);
                                            this.deleteAddedDevice(this.newDevice.MAC, item.ipAddress.address);
                                        } else {
                                            Logger.debug(this.LOG_TAG, `设备已添加 - MAC: ${this.newDevice.MAC}, Alias: ${this.newDevice.Alias}, Address: ${this.newDevice.Address}, Port: ${this.newDevice.Port}`);
                                            CommonUtils.alert($r("app.string.add_machine_failed", dialogData.deviceAlias), this.promptAction);
                                        }
                                    } catch (err) {
                                        Logger.error(this.LOG_TAG, `保存设备失败: ${JSON.stringify(err)}`);
                                        CommonUtils.alert($r("app.string.add_machine_failed", this.newDevice.Alias), this.promptAction);
                                    } finally {
                                        this.clearInput();
                                    }
                                }
                            }
                        })
                            .margin({
                                top: StyleConstants.MARGIN_TWO_PERCENT,
                                bottom: StyleConstants.MARGIN_TWO_PERCENT
                            })
                    }
                })
            }
            .width(StyleConstants.FULL_PERCENT)
            .height(StyleConstants.FULL_PERCENT)
            .padding({
                top: StyleConstants.PADDING_TWO
            })
        } else {
            Text($r("app.string.neigh_table_press_load_label"))
                .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHTEEN)
                .fontColor($r("sys.color.font_tertiary"))
                .width(StyleConstants.FULL_PERCENT)
                .height(StyleConstants.FULL_PERCENT)
                .align(Alignment.Center)
                .textAlign(TextAlign.Center)
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
                    textResource: $r("app.string.add_mac_input_label"),
                    placeholderResource: $r("app.string.add_mac_input_placeholder"),
                    text: this.newDevice.MAC,
                    onInputChange: (value: string | number) => { this.newDevice.MAC = String(value) }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)

                TextItem({
                    inputType: INPUT_TYPE.ALIAS,
                    inputId: CommonConstants.ALIAS_INPUT_ID,
                    isDefaultFocus: false,
                    textResource: $r("app.string.add_alias_input_label"),
                    placeholderResource: $r("app.string.add_alias_input_placeholder"),
                    text: this.newDevice.Alias,
                    onInputChange: (value: string | number) => { this.newDevice.Alias = String(value) }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)

                Column() {
                    Stack() {
                        Divider()
                            .strokeWidth(StyleConstants.DIVIDER_STOKE_WIDTH)
                            .width(StyleConstants.EIGHTY_PERCENT)
                            .color($r("sys.color.background_emphasize"))

                        Row() {
                            Text($r("app.string.divider_label"))
                                .fontColor($r("sys.color.font_emphasize"))
                                .fontSize(StyleConstants.DIVIDER_FONT_SIZE)
                                .margin({
                                    right: StyleConstants.MARGIN_ONE_PERCENT
                                })

                            SymbolGlyph($r("sys.symbol.chevron_up"))
                                .width(StyleConstants.DIVIDER_SYMBOL_SIZE)
                                .height(StyleConstants.DIVIDER_SYMBOL_SIZE)
                                .fontColor([$r("sys.color.font_emphasize")])
                                .margin({
                                    left: StyleConstants.MARGIN_ONE_PERCENT
                                })
                                .rotate({
                                    angle: this.showAdvanced ? 0 : 180
                                })
                        }
                        .width(StyleConstants.TWENTY_PERCENT)
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)
                        .backgroundColor($r("sys.color.background_primary"))
                        .margin({
                            left: StyleConstants.ONE_PERCENT
                        })
                        .onClick(() => {
                            this.showAdvanced = !this.showAdvanced;
                        })
                    }
                    .alignContent(Alignment.Start)
                    .margin({
                        top: StyleConstants.MARGIN_TWO_PERCENT
                    })

                    if(this.showAdvanced) {
                        TextItem({
                            inputType: INPUT_TYPE.ADDRESS,
                            inputId: CommonConstants.ADDRESS_INPUT_ID,
                            isDefaultFocus: false,
                            textResource: $r("app.string.add_address_input_label"),
                            placeholderResource: $r("app.string.add_address_input_placeholder"),
                            text: this.newDevice.Address,
                            onInputChange: (value: string | number) => { this.newDevice.Address = String(value) }
                        })
                            .width(StyleConstants.EIGHTY_PERCENT)

                        TextItem({
                            inputType: INPUT_TYPE.PORT,
                            inputId: CommonConstants.PORT_INPUT_ID,
                            isDefaultFocus: false,
                            textResource: $r("app.string.add_port_input_label"),
                            placeholderResource: $r("app.string.add_port_input_placeholder"),
                            text: this.newDevice.Port,
                            onInputChange: (value: string | number) => { this.newDevice.Port = Number(value) }
                        })
                            .width(StyleConstants.EIGHTY_PERCENT)
                    }
                }
                .alignItems(HorizontalAlign.Center)

                Button($r("app.string.button_add_machine_confirm"))
                    .enabled(!CommonUtils.isStringNullOrEmpty(this.newDevice.MAC.trim()) && !CommonUtils.isStringNullOrEmpty(this.newDevice.Alias.trim()))
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .margin({
                        top: StyleConstants.MARGIN_TEN_PERCENT
                    })
                    .onClick(async () => {
                        await this.saveDeviceManual();
                    })

                Blank()
                    .layoutWeight(1)
            }
        }
        .width(StyleConstants.FULL_PERCENT)
    }

    @Builder
    NeighTableAdd() {
        Column() {
            Row() {
                Blank().layoutWeight(1)

                Text($r("app.string.neigh_table_device_total_label", this.neighTableDevices?.length ?? 0))
                    .fontColor($r("sys.color.font_tertiary"))
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
            }
            .width(StyleConstants.FULL_PERCENT)
            .height(StyleConstants.THREE_PERCENT)
            .padding({
                right: StyleConstants.PADDING_THIRTY
            })

            Stack() {
                this.NeighTableDeviceList();

                if(this.isLoadingNeighTable) this.LoadingContent();
            }
            .width(StyleConstants.FULL_PERCENT)
            .height(StyleConstants.EIGHTY_FIVE_PERCENT)

            Column() {
                Blank()
                    .layoutWeight(1)

                Button(!this.isNeighTableEmpty() ? $r("app.string.neigh_table_reload_button_label") : $r("app.string.neigh_table_load_button_label"))
                    .enabled(!this.isLoadingNeighTable)
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .onClick(async () => {
                        await this.loadNeighTable();
                    })

                Blank()
                    .layoutWeight(1)
            }
            .width(StyleConstants.FULL_PERCENT)
            .height(StyleConstants.TEN_PERCENT)
        }
        .width(StyleConstants.FULL_PERCENT)
    }

    @Builder
    MainContent() {
        HdsTabs({
            controller: this.tabController,
            barPosition: BarPosition.Start
        }) {
            TabContent() {
                this.ManualAdd();
            }.tabBar($r("app.string.manual_add_device_tab_title"))

            TabContent() {
                this.NeighTableAdd();
            }.tabBar($r("app.string.neigh_table_add_device_tab_title"))
        }
    }

    build() {
        HdsNavDestination() {
            this.MainContent();
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.add_machine_title")
                },
                menu: this.menus
            },
            style: {
                systemMaterialEffect: { // 设置沉浸光感
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                },
            },
            enableComponentSafeArea: true // 启用标题栏占位
        })
        .alignSelf(ItemAlign.Center)
        .align(Alignment.Center)
        .onReady((context: NavDestinationContext) => {
            this.pageStack = context.pathStack;
            this.deviceList = context.pathInfo.param as DeviceListViewModel;
        })
        .onBackPressed(() => {
            this.pageStack?.pop("Back pressed");
            return true;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}
