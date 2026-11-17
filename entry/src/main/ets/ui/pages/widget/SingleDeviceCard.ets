import { StyleConstants } from '../../../common/constants/StyleConstants';
import { CommonConstants } from '../../../common/constants/CommonConstants';
import { CardStateView } from '../../component/CardStateView';

let storage = new LocalStorage();

/**
 * 单设备卡片页。V1 @Component + @LocalStorageProp：数据由 FormKit 的 updateForm 注入，
 * 是平台给定的通道（见设计 §5.3）。卡片页不读数据库、不发 FormKit 的 updateForm，动作一律 postCardAction。
 */
@Entry(storage)
@Component
struct SingleDeviceCard {
    @LocalStorageProp('formID') private formID: string = '';
    @LocalStorageProp('isInitialized') private isInitialized: boolean = false;
    @LocalStorageProp('isRunning') private isRunning: boolean = false;

    @LocalStorageProp('deviceID') private deviceID: number | null = null;
    @LocalStorageProp('alias') private alias: string | null = null;
    @LocalStorageProp('mac') private mac: string | null = null;
    @LocalStorageProp('address') private address: string | null = null;
    @LocalStorageProp('port') private port: number | null = null;

    @LocalStorageProp('runResult') private runResult: string = '';

    private readonly ActionTypeRouter = 'router';
    private readonly ActionTypeCall = 'call';
    private readonly ActionTypeMessage = 'message';

    private readonly EntryAbilityName: string = 'EntryAbility';
    private readonly WidgetEntryAbilityName: string = 'SingleDeviceWidgetEntryAbility';

    private readonly FormEditPageRoute: string = 'ui/pages/form/SingleDeviceFormEdit';

    private sendMessageAction(action: string, data: number | string | null): void {
        postCardAction(this, {
            action: this.ActionTypeMessage,
            params: {
                formAction: action,
                data: data
            }
        });
    }

    @Builder
    Logo() {
        Column() {
            Image($r('app.media.foreground'))
                .objectFit(ImageFit.Auto)
                .margin({
                    left: StyleConstants.MARGIN_EIGHT
                })
        }
        .width(StyleConstants.THIRTY_PERCENT)
    }

    @Builder
    Init() {
        Row() {
            this.Logo();

            CardStateView({ state: 'unbound' })
                .width(StyleConstants.SEVENTY_PERCENT)
                .layoutWeight(1)
        }
        .height('100%')
        .width('100%')
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
            this.Logo();

            CardStateView({ state: 'running' })
                .width(StyleConstants.SEVENTY_PERCENT)
                .layoutWeight(1)
        }
        .height('100%')
        .width('100%')
        .onClick(() => {
        })
    }

    @Builder
    MainContent() {
        Row() {
            this.Logo();

            Column() {
                if (this.runResult !== '') {
                    CardStateView({ state: 'result', resultText: this.runResult })
                } else {
                    Text(this.alias ?? '')
                        .fontWeight(FontWeight.Medium)
                        .fontColor(Color.White)
                        .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
            }
            .width(StyleConstants.SEVENTY_PERCENT)
            .layoutWeight(1)
        }
        .height('100%')
        .width('100%')
        .onClick(() => {
            if (this.isRunning) return;

            if (this.runResult !== '') {
                // 正在显示执行结果，恢复卡片显示
                this.sendMessageAction(CommonConstants.FORM_MESSAGE_RESTORE, 'MainContent() Component');
            } else if (this.isInitialized) {
                postCardAction(this, {
                    action: this.ActionTypeCall,
                    abilityName: this.WidgetEntryAbilityName,
                    params: {
                        method: CommonConstants.FORM_CALL_RUN,
                        formID: this.formID,
                        deviceID: this.deviceID,
                        alias: this.alias,
                        mac: this.mac,
                        address: this.address,
                        port: this.port
                    }
                });
            }
        })
    }

    build() {
        RelativeContainer() {
            if (!this.isInitialized) {
                this.Init();
            } else if (this.isRunning) {
                this.RunningContent();
            } else {
                this.MainContent();
            }
        }
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.single_device_form_background_color'))
    }
}