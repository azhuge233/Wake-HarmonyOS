import StyleConstants from '../../common/constants/StyleConstants';
import CommonConstants from '../../common/constants/CommonConstants'

let storage = new LocalStorage();

@Entry(storage)
@Component
struct SingleDeviceCard {
    @LocalStorageProp('formID') private formID: string = '';
    @LocalStorageProp('isInitialized') private isInitialized: boolean = false;
    @LocalStorageProp('isRunning') private isRunning: boolean = false;

    @LocalStorageProp('deviceID') private deviceID: string | null = null;
    @LocalStorageProp('alias') private alias: string | null = null;
    @LocalStorageProp('mac') private mac: string | null = null;
    @LocalStorageProp('address') private address: string | null = null;
    @LocalStorageProp('port') private port: string | null = null;

    @LocalStorageProp('runResult') private runResult: string = '';

    private readonly ActionTypeRouter = 'router';
    private readonly ActionTypeCall = 'call';
    private readonly ActionTypeMessage = 'message';

    private readonly EntryAbilityName: string = 'EntryAbility';
    private readonly WidgetEntryAbilityName: string = 'SingleDeviceWidgetEntryAbility';

    private readonly FormEditPageRoute: string = 'pages/SingleDeviceFormEdit';

    private sendMessageAction(action: string, data: number | string | null) {
        postCardAction(this, {
            action: this.ActionTypeMessage,
            params: {
                formAction: action,
                data: data
            }
        });
    }

    aboutToAppear(): void {
        this.sendMessageAction(CommonConstants.FormMessage_Restore, 'aboutToAppear()');
    }

    @Builder
    Logo() {
        Column() {
            Image($r("app.media.foreground"))
                .objectFit(ImageFit.Auto)
                .margin({
                    left: StyleConstants.MARGIN_EIGHT
                })
        }
        .width(StyleConstants.THIRTY_PERCENT)
    }

    @Builder
    LoadingContent() {
        Column() {
            LoadingProgress()
                .height(StyleConstants.SIXTY_PERCENT)
                .width(StyleConstants.SIXTY_PERCENT)
        }
        .width(StyleConstants.SEVENTY_PERCENT)
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
                        .margin({
                            top: StyleConstants.MARGIN_TEN,
                            bottom: StyleConstants.MARGIN_FIVE,
                            right: StyleConstants.MARGIN_TEN
                        })

                    Text($r("app.string.form_run_complete_label"))
                        .height(StyleConstants.TEN_PERCENT)
                        .width(StyleConstants.FULL_PERCENT)
                        .alignSelf(ItemAlign.Center)
                        .textAlign(TextAlign.Center)
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHT)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Color.White)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Clip })
                        .margin({
                            bottom: StyleConstants.MARGIN_FIVE,
                            right: StyleConstants.MARGIN_TEN
                        })
                }
            } else {
                Column() {
                    Text(this.alias)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Color.White)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
            }
        }
        .width(StyleConstants.SEVENTY_PERCENT)
        .layoutWeight(1)
    }

    @Builder
    Init() {
        Row() {
            this.Logo();

            Column() {
                Text($r('app.string.form_init_label'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Color.White)
                    .margin({
                        right: StyleConstants.MARGIN_TEN
                    })
            }
            .width(StyleConstants.SEVENTY_PERCENT)
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onAppear(() => {
            this.sendMessageAction(CommonConstants.FormMessage_Restore, 'Init() Component');
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
            this.Logo();

            this.LoadingContent();
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onClick(() => {})
    }

    @Builder
    MainContent() {
        Row() {
            this.Logo();

            this.DeviceOrResults();
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onClick(() => {
            if(!this.isRunning) {
                if(this.runResult !== '') { // 如果正在显示执行结果，恢复卡片显示
                    this.sendMessageAction(CommonConstants.FormMessage_Restore, 'MainContent() Component');
                } else if (this.isInitialized) { // 正常显示状态，执行指令
                    postCardAction(this, {
                        action: this.ActionTypeCall,
                        abilityName: this.WidgetEntryAbilityName,
                        params: {
                            method: CommonConstants.FormCall_Run,
                            formID: this.formID,
                            deviceID: this.deviceID,
                            alias: this.alias,
                            mac: this.mac,
                            address: this.address,
                            port: this.port
                        }
                    });
                }
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
        .backgroundColor($r('app.color.single_device_form_background_color'))
    }
}