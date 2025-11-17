import { promptAction } from "@kit.ArkUI";
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from "@kit.BasicServicesKit";

import NET from "../common/utils/NET";
import Logger from "../common/utils/Logger";
import StyleConstants from "../common/constants/StyleConstants";

@Component
export default struct MachineTile {
    machineMAC: Resource = $r("app.string.empty");
    machineAlias: Resource = $r("app.string.empty");
    textButtonWake: Resource = $r("app.string.button_wake_label");

    machineMACAddr: string = '';

    private LOG_TAG = "[view/MachineTile]";

    alert(message: Resource) {
        promptAction.showToast({
            message: message
        });
    }

    vibrate() {
        try {
            vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
                if (err) {
                    Logger.error(this.LOG_TAG, `查询振动效果失败, 代码: ${err.code}, 错误信息: ${err.message}`);
                    return;
                }

                Logger.info(this.LOG_TAG, '设置支持 haptic.effect.hard 振动');

                if (state) {
                    try {
                        // 触发马达振动
                        vibrator.startVibration({
                            type: 'preset',
                            effectId: 'haptic.effect.hard',
                            count: 1,
                            intensity: 100,
                        }, {
                            usage: 'unknown'
                        }, (error: BusinessError) => {
                            if (error) Logger.error(this.LOG_TAG, `振动触发失败, 代码: ${error.code}, 错误信息: ${error.message}`);
                            else Logger.info(this.LOG_TAG, '成功触发振动');
                        });
                    } catch (error) {
                        Logger.error(this.LOG_TAG, `振动发生未知错误, ${error}`);
                    }
                }
            });
        } catch (error) {
            Logger.error(this.LOG_TAG, `振动发生未知错误, ${error}`);
        }
    }

    sendMagicPacket(): void {
        if(NET.HAS_BROADCAST_IP) {
            const packet = NET.buildMagicPacket(this.machineMACAddr);

            NET.UDP.send(packet, (err: BusinessError) => {
                if (err) {
                    Logger.error(this.LOG_TAG,
                        `Send magic packet Error. Code: ${err.code}, message: ${err.message}`);
                    this.alert($r("app.string.send_magic_packet_failed", err.code));
                    return;
                }

                Logger.debug(this.LOG_TAG, 'Send magic packet OK!');
                this.alert($r("app.string.send_magic_packet_success"));
            })
            return;
        } else {
            Logger.debug(this.LOG_TAG, "No broadcast IP, abort.");
            this.alert($r("app.string.no_broadcast_ip"));
            return;
        }
    }

    build() {
        Row() {
            Column() {
                Text(this.machineAlias)
                    //.fontColor($r("app.color.lighter_black"))
                    .align(Alignment.Top)
                    .textAlign(TextAlign.Start)
                Text(this.machineMAC)
                    .fontColor($r("app.color.darker_grey"))
            }
            .width(StyleConstants.EIGHTY_PERCENT)

            Column() {
                Button(this.textButtonWake)
                    .onClick(() => {
                        this.vibrate();
                        this.sendMagicPacket();
                    })
            }
            .width(StyleConstants.TWENTY_PERCENT)
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
    }
}