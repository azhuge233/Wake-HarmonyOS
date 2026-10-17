import { StyleConstants } from '../../common/constants/StyleConstants';
import { CommonConstants } from '../../common/constants/CommonConstants'
import { WidgetDevice } from '../model/WidgetDevice';

let storage = new LocalStorage();

@Entry(storage)
@Component
struct MultipleDevicesCard {
    @LocalStorageProp('formID') private formID: string = '';
    @LocalStorageProp('isInitialized') private isInitialized: boolean = false;
    @LocalStorageProp('isRunning') private isRunning: boolean = false;

    @LocalStorageProp('deviceList') private deviceList: Array<WidgetDevice> = [];

    @LocalStorageProp('runResult') private runResult: string = '';

    private readonly ActionTypeRouter = 'router';
    private readonly ActionTypeCall = 'call';
    private readonly ActionTypeMessage = 'message';

    private readonly EntryAbilityName: string = 'EntryAbility';
    private readonly WidgetEntryAbilityName: string = 'MultipleDevicesWidgetEntryAbility';

    private readonly FormEditPageRoute: string = 'pages/MultipleDevicesFormEdit';

    private sendMessageAction(action: string, data: number | string | null) {
        postCardAction(this, {
            action: this.ActionTypeMessage,
            params: {
                formAction: action,
                data: data
            }
        });
    }

    @Builder
    LoadingContent() {
        Column() {
            LoadingProgress()
                .height(StyleConstants.FORTY_PERCENT)
                .width(StyleConstants.FORTY_PERCENT)
                .color(Color.White)
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    DeviceOrResults() {
        Column() {
            if (this.runResult !== '') {
                Column() {
                    Blank()

                    Text(this.runResult)
                        .height(StyleConstants.EIGHTY_FIVE_PERCENT)
                        .layoutWeight(1)
                        .fontColor(Color.White)
                        .textAlign(TextAlign.Center)

                    Text($r("app.string.form_run_complete_label"))
                        .height(StyleConstants.TEN_PERCENT)
                        .width(StyleConstants.FULL_PERCENT)
                        .alignSelf(ItemAlign.Center)
                        .textAlign(TextAlign.Center)
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHT)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Color.White)
                        .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                        .textOverflow({ overflow: TextOverflow.Clip })
                }
                .height(StyleConstants.FULL_PERCENT)
                .width(StyleConstants.FULL_PERCENT)
            } else {
                List() {
                    ForEach(this.deviceList, (device: WidgetDevice) => {
                        ListItem() {
                            Row() {
                                Image($r("app.media.foreground"))
                                    .width(StyleConstants.THIRTY_PERCENT)
                                    .objectFit(ImageFit.Auto)
                                    .margin({
                                        left: StyleConstants.MARGIN_EIGHT
                                    })

                                Text(device.alias)
                                    .width(StyleConstants.SEVENTY_PERCENT)
                                    .textAlign(TextAlign.Center)
                                    .fontWeight(FontWeight.Medium)
                                    .fontColor(Color.White)
                                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                            }
                        }
                        .height(StyleConstants.FORM_ITEM_HEIGHT)
                        .width(StyleConstants.EIGHTY_FIVE_PERCENT)
                        .borderRadius(StyleConstants.BORDER_RADIUS_THIRTEEN)
                        .backgroundColor($r('app.color.multiple_devices_form_item_color'))
                        .margin({
                            top: StyleConstants.MARGIN_THREE,
                            bottom: StyleConstants.MARGIN_THREE
                        })
                        .onClick(() => {
                            if (this.isInitialized && !this.isRunning) {
                                postCardAction(this, {
                                    action: this.ActionTypeCall,
                                    abilityName: this.WidgetEntryAbilityName,
                                    params: {
                                        method: CommonConstants.FORM_CALL_RUN,
                                        formID: this.formID,
                                        deviceID: device.id,
                                        mac: device.mac,
                                        address: device.address,
                                        port: device.port,
                                        deviceList: this.deviceList
                                    }
                                });
                            }
                        })
                    }, (device: WidgetDevice) => device.id.toString())
                }
                .lanes(2)
                .layoutWeight(1)
                .alignListItem(ListItemAlign.Center)
                .height(StyleConstants.FULL_PERCENT)
                .width(StyleConstants.FULL_PERCENT)
                .margin({
                    top: StyleConstants.MARGIN_ONE_PERCENT,
                    bottom: StyleConstants.MARGIN_ONE_PERCENT
                })
            }
        }
        .width(StyleConstants.FULL_PERCENT)
        .layoutWeight(1)
    }

    @Builder
    Init() {
        Column() {
            Text($r('app.string.form_init_label'))
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
                .textAlign(TextAlign.Center)
                .height(StyleConstants.FULL_PERCENT)
                .width(StyleConstants.FULL_PERCENT)
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onAppear(() => {
            this.sendMessageAction(CommonConstants.FORM_MESSAGE_RESTORE, 'Init() Component');
        })
        .onClick(() => {
            postCardAction(this, {
                action: this.ActionTypeRouter,
                abilityName: this.EntryAbilityName,
                params: {
                    targetPage: this.FormEditPageRoute,
                    formID: this.formID
                }
            });
        })
    }

    @Builder
    RunningContent() {
        Row() {
            this.LoadingContent();
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onClick(() => {})
    }

    @Builder
    MainContent() {
        Row() {
            this.DeviceOrResults();
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onClick(() => {
            if(!this.isRunning && this.runResult !== '') {
                this.sendMessageAction(CommonConstants.FORM_MESSAGE_RESTORE, 'MainContent() Component');
            }
        })
    }

    build() {
        RelativeContainer() {
            if (!this.isInitialized) this.Init();
            else if(this.isRunning) this.RunningContent();
            else this.MainContent();
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .backgroundColor($r('app.color.multiple_devices_form_background_color'))
    }
}