import NET from "../common/utils/NET";
import { promptAction } from "@kit.ArkUI";
import Logger from "../common/utils/Logger";
import { BusinessError } from "@kit.BasicServicesKit";

@Component
export default struct MachineTile {
    machineMAC: Resource = $r("app.string.empty");
    machineAlias: Resource = $r("app.string.empty");

    textButtonWake: Resource = $r("app.string.button_wake_label");

    machineMACAddr: string = '';

    private LOG_TAG = "[view/MachineTile]";

    sendMagicPacket(): void {
        if(NET.HAS_BROADCAST_IP) {
            const packet = NET.buildMagicPacket(this.machineMACAddr);

            NET.UDP.send(packet, (err: BusinessError) => {
                if (err) {
                    Logger.error(this.LOG_TAG,
                        `Send magic packet Error. Code: ${err.code}, message: ${err.message}`);
                    promptAction.showToast({
                        message: $r("app.string.send_magic_packet_failed", err.code)
                    });
                    return;
                }

                Logger.debug(this.LOG_TAG, 'Send magic packet OK!');
                promptAction.showToast({
                    message: $r("app.string.send_magic_packet_success")
                });
            })
            return;
        } else {
            Logger.debug(this.LOG_TAG, "No broadcast IP, abort.");
            promptAction.showToast({
                message: $r("app.string.no_broadcast_ip")
            });
            return;
        }
    }

    build() {
        Row() {
            Column() {
                Row() {
                    Text(this.machineAlias)
                        .fontColor('#111111')
                        .align(Alignment.Top)
                        .textAlign(TextAlign.Start)
                }
                Row() {
                    Text(this.machineMAC)
                        .fontColor('#888888')
                }
            }
            .width('80%')

            Column() {
                Button(this.textButtonWake)
                    .backgroundColor('#936dc0')
                    .foregroundColor('#a7ff60')
                    .onClick(() => {
                        this.sendMagicPacket();
                    })
            }
            .width('20%')
        }
    }
}