import { StyleConstants } from '../../../common/constants/StyleConstants';
import { CommonConstants } from '../../../common/constants/CommonConstants';
import { WidgetDevice } from '../../../common/model/CardBindingData';
import { CardFrame } from '../../component/CardFrame';
import { CardStateView } from '../../component/CardStateView';
import { DeviceCard } from '../../component/DeviceCard';

let storage = new LocalStorage();

/**
 * 多设备卡片页。V1 @Component + @LocalStorageProp，与单设备卡片同一条平台边界；
 * 三态骨架由 CardFrame + CardStateView 承载，单台设备由 DeviceCard 渲染。
 */
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

    private readonly FormEditPageRoute: string = 'ui/pages/form/MultipleDevicesFormEdit';

    private sendMessageAction(action: string, data: number | string | null): void {
        postCardAction(this, {
            action: this.ActionTypeMessage,
            params: {
                formAction: action,
                data: data
            }
        });
    }

    private runDevice(device: WidgetDevice): void {
        if (!this.isInitialized || this.isRunning) return;

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

    @Builder
    InitBody() {
        CardStateView({ state: 'unbound' })
    }

    @Builder
    RunningBody() {
        CardStateView({ state: 'running' })
    }

    @Builder
    ResultBody() {
        CardStateView({ state: 'result', resultText: this.runResult })
    }

    @Builder
    DeviceListBody() {
        List() {
            ForEach(this.deviceList, (device: WidgetDevice) => {
                ListItem() {
                    DeviceCard({
                        name: device.alias,
                        mac: device.mac,
                        onTap: () => {
                            this.runDevice(device);
                        }
                    })
                }
            }, (device: WidgetDevice) => device.id.toString())
        }
        .lanes(2, StyleConstants.MARGIN_TEN)
        .scrollBar(BarState.Off)
        .padding({
            left: StyleConstants.MARGIN_TEN,
            right: StyleConstants.MARGIN_TEN
        })
        .layoutWeight(1)
        .height('100%')
        .width('100%')
        .margin({
            top: '1%',
            bottom: '1%'
        })
    }

    build() {
        RelativeContainer() {
            if (!this.isInitialized) {
                CardFrame({
                    onTap: () => {
                        postCardAction(this, {
                            action: this.ActionTypeRouter,
                            abilityName: this.EntryAbilityName,
                            params: {
                                targetPage: this.FormEditPageRoute,
                                formID: this.formID
                            }
                        });
                    },
                    body: (): void => {
                        this.InitBody();
                    }
                })
                    .height('100%')
                    .width('100%')
                    .onAppear(() => {
                        this.sendMessageAction(CommonConstants.FORM_MESSAGE_RESTORE, 'Init() Component');
                    })
            } else if (this.isRunning) {
                CardFrame({
                    onTap: () => {
                    },
                    body: (): void => {
                        this.RunningBody();
                    }
                })
                    .height('100%')
                    .width('100%')
            } else if (this.runResult !== '') {
                CardFrame({
                    onTap: () => {
                        this.sendMessageAction(CommonConstants.FORM_MESSAGE_RESTORE, 'MainContent() Component');
                    },
                    body: (): void => {
                        this.ResultBody();
                    }
                })
                    .height('100%')
                    .width('100%')
            } else {
                CardFrame({
                    onTap: () => {
                    },
                    body: (): void => {
                        this.DeviceListBody();
                    }
                })
                    .height('100%')
                    .width('100%')
            }
        }
        .height('100%')
        .width('100%')
        .backgroundColor($r('app.color.multiple_devices_form_background_color'))
    }
}