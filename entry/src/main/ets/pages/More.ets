import { JSON } from '@kit.ArkTS';
import { BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { buffer } from '@kit.ArkTS';

import Machine from '../model/Machine';
import Logger from '../common/utils/Logger';
import { DB } from '../common/utils/DB';
import MoreMenuItem from '../view/MoreMenuItem';
import StyleConstants from '../common/constants/StyleConstants';

@Builder
export function MoreBuilder() {
    More();
}

@Entry
@Component
struct More {
    pathStack: NavPathStack | undefined = undefined;

    private LOG_TAG = '[pages/More]';

    private db = DB.getInstance();

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    // private promptAction = this.uiContext.getPromptAction();

    @State isProcessing: boolean = false;

    alert(message: Resource) {
        promptAction.showToast({
            message: message
        })
    }

    getDate(): string {
        let date = new Date(systemDateTime.getTime());

        const formattedTime = `${date.getTime().toString()}`;
        Logger.debug(this.LOG_TAG, formattedTime);

        return formattedTime;
    }

    async saveToFile(json: string): Promise<boolean> {
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

                return true;
            }

            Logger.warn(this.LOG_TAG, "No path selected");
            return false;
        } catch (err) {
            Logger.error(this.LOG_TAG, `Save failed, code is ${err.code}, message is ${err.message}`);
            throw new Error("Save backup to file failed");
        }
    }

    async export(): Promise<void> {
        await this.db.waitForReady();
        this.db.getMachineList().then(async (list) => {
            if (list === undefined) {
                Logger.info(this.LOG_TAG, 'No Machine found!');
                return;
            }

            // formatting data to json
            let jsonString = JSON.stringify(await this.db.getMachineList(), null, 4);
            Logger.debug(this.LOG_TAG, `Machines found: ${jsonString}`);

            let result = await this.saveToFile(jsonString);

            if(result) this.alert($r("app.string.export_success"));
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
        try {
            const documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.maxSelectNumber = 1;
            documentSelectOptions.fileSuffixFilters = [".json"];

            const documentViewPicker = new picker.DocumentViewPicker(this.context);
            const uris = await documentViewPicker.select(documentSelectOptions);

            Logger.debug(this.LOG_TAG, `Pick file succeed: ${uris}`);

            // set to true, blocking user actions
            this.isProcessing = true;

            if (uris.length > 0) {
                let backupFilePath: string = uris[0];
                Logger.debug(this.LOG_TAG, `backup file path: ${backupFilePath}`);

                // open file
                let file = fs.openSync(backupFilePath, fs.OpenMode.READ_ONLY);

                try {
                    // get file size
                    let fileStat = fs.statSync(file.fd);
                    let fileSize = fileStat.size;
                    Logger.debug(this.LOG_TAG, `File size: ${fileSize} bytes`);

                    // read file
                    // cannot use readText(Sync), throws 13900002 error(No such file or directory)
                    let arrayBuffer = new ArrayBuffer(fileSize);
                    let readLen = fs.readSync(file.fd, arrayBuffer);

                    Logger.debug(this.LOG_TAG, `Read ${readLen} bytes from file`);
                    if (readLen !== fileSize) Logger.warn(this.LOG_TAG, `Expected to read ${fileSize} bytes, but got ${readLen}`);

                    let jsonString = buffer.from(arrayBuffer, 0, readLen).toString();
                    Logger.debug(this.LOG_TAG, `Read succeed, content length: ${jsonString.length}`);

                    let machines = await this.parseData(jsonString);

                    await this.db.clearTable();

                    for (let machine of machines) {
                        await this.db.addMachine(machine.MAC, machine.Alias).then(id => {
                            Logger.debug(this.LOG_TAG,
                                `Added machine - ID: ${id}, MAC: ${machine.MAC}, Alias: ${machine.Alias}`);
                        }).catch((err: BusinessError) => {
                            Logger.error(this.LOG_TAG, `Add Error! Code: ${err.code}, message: ${err.message}`);
                        })
                    }

                    this.alert($r("app.string.import_success"));
                } finally {
                    // close file
                    fs.closeSync(file);
                }
            } else Logger.error(this.LOG_TAG, "No backup file selected");
        } catch (err) {
            Logger.error(this.LOG_TAG, `Import failed, code: ${err.code}, message: ${err.message}`);
            this.alert($r("app.string.import_failed"));
        } finally {
            this.isProcessing = false;
        }
    }

    async onPageShow(): Promise<void> {}

    onPageHide(): void {}

    onBackPress(): boolean | void {
        if (this.isProcessing) {
            promptAction.showToast({
                message: $r("app.string.import_waiting_message")
            })
            return true;
        }
        return false;
    }

    build() {
        Stack() {
            NavDestination() {
                Column() {
                    MoreMenuItem({
                        menuText: $r("app.string.page_more_export"),
                        menuIcon: "./media/icon/arrow_up_circle.png"
                    }).onClick(async () => {
                        if (!this.isProcessing) {
                            await this.export();
                        }
                    })

                    MoreMenuItem({
                        menuText: $r("app.string.page_more_import"),
                        menuIcon: "./media/icon/arrow_down_circle.png"
                    }).onClick(async () => {
                        if (this.isProcessing) return;

                        this.uiContext.getPromptAction().showDialog({
                            title: $r("app.string.import_title"),
                            message: $r("app.string.import_message"),
                            buttons: [
                                {
                                    text: $r("app.string.button_confirm_label"),
                                    color: $r("app.color.black")
                                },
                                {
                                    text: $r("app.string.button_cancel_label"),
                                    color: $r("app.color.black")
                                }
                            ]
                        }).then(async (result) => {
                            if (result.index == 0) await this.import();
                            else Logger.debug(this.LOG_TAG, "Import canceled");
                        })
                    })

                    MoreMenuItem({
                        menuText: $r("app.string.page_more_help"),
                        menuIcon: "./media/icon/info_circle.png"
                    }).onClick(() => {
                        if (!this.isProcessing) {
                            this.pathStack?.pushPath({ name: "Help" });
                        }
                    })
                }
            }
            .title($r("app.string.more_title"))
            .onReady((context: NavDestinationContext) => {
                this.pathStack = context.pathStack;
            })
            .onAppear(() => {
                Logger.debug(this.LOG_TAG, "Main menu loaded!");
            })

            if(this.isProcessing) {
                Column() {
                    Progress({ value: 0, total: 100, type: ProgressType.Ring })
                        .width(StyleConstants.PROGRESS_WIDTH)
                        .color(Color.Blue)
                        .style({ strokeWidth: 18, status: ProgressStatus.LOADING })

                    Text($r("app.string.import_waiting_message"))
                        .margin({ top: StyleConstants.MARGIN_TWENTY })
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                        .fontColor(Color.White)
                }
                .width(StyleConstants.FULL_PERCENT)
                .height(StyleConstants.FULL_PERCENT)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(StyleConstants.TRANSPARENT_BACKGROUND)
                .blur(StyleConstants.PROGRESS_COLUMN_BLUR_LEVEL)
                .onClick(() => {})
                .onAppear(() => {
                    Logger.debug(this.LOG_TAG, "Blocking progress loaded!");
                })
            }
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}
