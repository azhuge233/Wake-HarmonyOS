import { JSON } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit';

import Logger from '../common/utils/Logger';
import MoreMenuItem from '../view/MoreMenuItem';
import StyleConstants from '../common/constants/StyleConstants';
import CommonUtils from '../common/utils/CommonUtils';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';

@Builder
export function MoreBuilder() {
    More();
}

@Entry
@ComponentV2
struct More {
    private LOG_TAG = '[pages/More]';

    @Local isProcessing: boolean = false;

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    private promptAction = this.uiContext.getPromptAction();

    pathStack: NavPathStack | undefined = undefined;

    private deviceListViewModel: DeviceListViewModel = new DeviceListViewModel();
    private newDeviceViewModel: DeviceViewModel = new DeviceViewModel();

    async export(): Promise<void> {
        try {
            const deviceListJsonObject = await this.deviceListViewModel.toDeviceJsonObjectList();

            let jsonString = JSON.stringify(deviceListJsonObject, null, 4);
            Logger.debug(this.LOG_TAG, `即将导出的设备: ${jsonString}`);

            const success = await CommonUtils.saveToFile(jsonString, this.context);

            if (success) CommonUtils.alert($r("app.string.export_success"), this.promptAction);
            else Logger.warn(this.LOG_TAG, `导出取消`);
        } catch (err) {
            Logger.error(this.LOG_TAG, `导出异常, ${err}`)
            CommonUtils.alert($r("app.string.export_failed"), this.promptAction);
        }
    }

    async import(): Promise<void> {
        try {
            const uris = await CommonUtils.pickFile(this.context);

            // set to true, blocking user actions
            this.isProcessing = true;

            if (uris.length > 0) {
                let backupFilePath: string = uris[0];
                Logger.debug(this.LOG_TAG, `backup file path: ${backupFilePath}`);

                const jsonString = await CommonUtils.readFile(backupFilePath);

                if(jsonString === undefined) throw new Error("读取文件失败");

                let deviceListJsonObject = await CommonUtils.parseData(jsonString);

                await this.deviceListViewModel.clearDevices();

                let deviceOrder = 0;

                for (let deviceJsonObject of deviceListJsonObject) {
                    this.newDeviceViewModel.MAC = deviceJsonObject.MAC;
                    this.newDeviceViewModel.Alias = deviceJsonObject.Alias;
                    this.newDeviceViewModel.Address = deviceJsonObject.Address ?? '';
                    this.newDeviceViewModel.Port = deviceJsonObject.Port ?? 9;
                    this.newDeviceViewModel.OrderIndex = deviceJsonObject.OrderIndex == -1 ? deviceOrder : deviceJsonObject.OrderIndex;

                    await this.deviceListViewModel.addDevice(this.newDeviceViewModel.toDevice());
                }

                CommonUtils.alert($r("app.string.import_success"), this.promptAction);

                this.pathStack?.pop("Import back");
            } else Logger.warn(this.LOG_TAG, "未选择备份文件");
        } catch (err) {
            Logger.error(this.LOG_TAG, `导入失败, 错误码: ${err.code}, 错误信息: ${err.message}`);
            CommonUtils.alert($r("app.string.import_failed"), this.promptAction);
        } finally {
            this.isProcessing = false;
        }
    }

    async importConfirm() {
        try {
            const result = await this.promptAction.showDialog({
                title: $r("app.string.import_title"),
                message: $r("app.string.import_message"),
                buttons: [
                    {
                        text: $r("app.string.button_confirm_label"),
                        color: $r("sys.color.font_primary")
                    },
                    {
                        text: $r("app.string.button_cancel_label"),
                        color: $r("sys.color.font_primary")
                    }
                ]
            });

            if (result.index == 0) await this.import();
            else Logger.debug(this.LOG_TAG, "导入已取消");
        } catch (err) {
            Logger.error(this.LOG_TAG, `导入弹窗失败, ${err}`);
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
        Column() {
            Column() {
                MoreMenuItem({
                    menuText: $r("app.string.page_more_export"),
                    menuIcon: $r("app.media.arrow_up_circle")
                }).onClick(async () => {
                    if (!this.isProcessing) {
                        await this.export();
                    } else CommonUtils.alert($r("app.string.import_waiting_message"), this.promptAction);
                })

                MoreMenuItem({
                    menuText: $r("app.string.page_more_import"),
                    menuIcon: $r("app.media.arrow_down_circle")
                }).onClick(async () => {
                    if (this.isProcessing) {
                        CommonUtils.alert($r("app.string.import_waiting_message"), this.promptAction);
                        return;
                    }

                    await this.importConfirm();
                })

                MoreMenuItem({
                    menuText: $r("app.string.page_more_help"),
                    menuIcon: $r("app.media.info_circle")
                }).onClick(() => {
                    if (!this.isProcessing) {
                        this.pathStack?.pushPath({ name: "Help" });
                    } else CommonUtils.alert($r("app.string.import_waiting_message"), this.promptAction);
                })
            }
            .height(StyleConstants.FULL_PERCENT)
            .width(StyleConstants.FULL_PERCENT)

            Text($r("app.string.app_version"))
                .width(StyleConstants.FULL_PERCENT)
                .fontColor(Color.Grey)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_THIRTEEN)
                .alignSelf(ItemAlign.End)
                .textAlign(TextAlign.Center)
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
    }

    build() {
        HdsNavDestination() {
            Stack({ alignContent: Alignment.Top }) {
                this.MainContent();

                if (this.isProcessing) {
                    this.LoadingContent();
                }
            }
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.more_title")
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
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
            this.deviceListViewModel = context.pathInfo.param as DeviceListViewModel;
        })
        .onBackPressed(() => {
            if(this.isProcessing) {
                CommonUtils.alert($r("app.string.import_waiting_message"), this.promptAction);
                return true;
            }
            return false;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}
