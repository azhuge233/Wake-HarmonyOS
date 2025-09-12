import { JSON } from '@kit.ArkTS';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
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
            `${this.uiContext.getHostContext()?.resourceManager.getStringByNameSync("current_broadcast_ip")}${NET.BROADCAST_IP}`;
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

    getDate(): string {
        let date = new Date(systemDateTime.getTime());

        const formattedTime = `${date.getTime().toString()}`;
        Logger.debug(this.LOG_TAG, formattedTime);

        return formattedTime;
    }

    async saveToFile(json: string): Promise<void> {
        let jsonFilename = `Wake-backup-${this.getDate()}.json`;

        const documentSaveOptions = new picker.DocumentSaveOptions();
        documentSaveOptions.newFileNames = [jsonFilename];
        documentSaveOptions.fileSuffixChoices = [".json"];

        const documentViewPicker = new picker.DocumentViewPicker(this.context);

        try {
            const uris = await documentViewPicker.save(documentSaveOptions);
            Logger.debug(this.LOG_TAG, `Pick save path succeed: ${uris}`);

            if (uris.length > 0) {
                let savePath: string = uris[0];

                let jsonFile = fs.openSync(savePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

                let writeLen = fs.writeSync(jsonFile.fd, json);
                Logger.debug(this.LOG_TAG, `config saved, path: ${jsonFile.path}, written length: ${writeLen}`);

                fs.closeSync(jsonFile);
            } else Logger.error(this.LOG_TAG, "No path selected");
        } catch (err) {
            Logger.error(this.LOG_TAG, `Save failed, code is ${err.code}, message is ${err.message}`);
        }
    }

    async export(): Promise<void> {
        await this.db.waitForReady();
        this.db.getMachineList().then((list) => {
            if (list === undefined) {
                Logger.info(this.LOG_TAG, 'No Machine found!');
                return;
            }

            // formatting data to json
            let jsonString = JSON.stringify(this.machines, null, 4);
            Logger.debug(this.LOG_TAG, `Machines found: ${jsonString}`);

            this.saveToFile(jsonString);
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `Query failed. Code: ${err.code}, message: ${err.message}`)
        })
    }

    async parseData(jsonStr: string): Promise<Array<Machine>> {
        let machines = new Array<Machine>();

        try {
            const parsedData = JSON.parse(jsonStr);

            if (Array.isArray(parsedData)) {
                machines = parsedData.map((item: Record<string, Object>) => {
                    const id = Number(Reflect.get(item, 'ID')) | 0;
                    const mac = String(Reflect.get(item, 'MAC'));
                    const alias = String(Reflect.get(item, 'Alias'));

                    return new Machine(id, mac, alias);
                });
                Logger.debug(this.LOG_TAG, `Data parsing succeed, count: ${machines.length}`);
            } else {
                Logger.error(this.LOG_TAG, `Parsed data is not an array`);
                this.alert($r("app.string.parse_json_data_failed"));
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `Parse json data failed, code is ${err.code}, message is ${err.message}`);
            this.alert($r("app.string.parse_json_data_failed"));
            throw new Error("Json date parse error");
        }

        return machines;
    }

    async import(): Promise<void> {
        const documentSelectOptions = new picker.DocumentSelectOptions();
        documentSelectOptions.maxSelectNumber = 1;
        documentSelectOptions.fileSuffixFilters = [".json"];

        const documentViewPicker = new picker.DocumentViewPicker(this.context);

        try {
            const uris = await documentViewPicker.select(documentSelectOptions);
            Logger.debug(this.LOG_TAG, `Pick file succeed: ${uris}`);

            if(uris.length > 0) {
                let backupFilePath: string = uris[0];
                Logger.debug(this.LOG_TAG, `backup file path: ${backupFilePath}`);

                // open file
                let file = fs.openSync(backupFilePath, fs.OpenMode.READ_ONLY);

                // read file
                // cannot use readText(Sync), throws 13900002 error(No such file or directory)
                let arrayBuffer = new ArrayBuffer(4096);
                let readLen = fs.readSync(file.fd, arrayBuffer);
                let jsonString = buffer.from(arrayBuffer, 0, readLen).toString();
                Logger.debug(this.LOG_TAG, `read succeed, content: ${jsonString}`);

                // close file
                fs.closeSync(file);

                let machines = await this.parseData(jsonString);

                await this.db.clearTable();

                for(let machine of machines) {
                    await this.db.addMachine(machine.MAC, machine.Alias).then(id => {
                        Logger.debug(this.LOG_TAG, `Added machine - ID: ${id}, MAC: ${machine.MAC}, Alias: ${machine.Alias}`);
                    }).catch((err: BusinessError) => {
                        Logger.error(this.LOG_TAG, `Add Error! Code: ${err.code}, message: ${err.message}`);
                    })
                }

                await this.getMachineList();

                this.alert($r("app.string.import_success"));
            } else Logger.error(this.LOG_TAG, "No backup file selected");
        } catch (err) {
            Logger.error(this.LOG_TAG, `Import failed, code: ${err.code}, message: ${err.message}`);
            this.alert($r("app.string.import_failed"))
        }
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
            left: StyleConstants.MARGIN_TEN_PERCENT
        })
    }

    build() {
        Navigation() {
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
                        this.uiContext.getRouter().pushUrl({
                            url: "pages/AddMachine"
                        })
                    })
            }
            .alignItems(HorizontalAlign.Center)
            .justifyContent(FlexAlign.SpaceBetween)
        }
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
                value: $r("app.string.navigation_menu_about"),
                icon: "./media/icon/info_circle.png",
                action: () => {
                    this.uiContext.getPromptAction().showDialog({
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
            },
            {
                value: $r("app.string.navigation_menu_import"),
                icon: "./media/icon/arrow_down_circle.png",
                action: () => {
                }
            },
            {
                value: $r("app.string.navigation_menu_export"),
                icon: "./media/icon/arrow_up_circle.png",
                action: async () => {
                    await this.export();
                }
            }
        ])
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}
