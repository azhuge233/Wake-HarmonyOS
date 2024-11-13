import NET from "../common/utils/NET";
import { promptAction } from "@kit.ArkUI";
import Logger from "../common/utils/Logger";
import { BusinessError } from "@kit.BasicServicesKit";
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
                        this.sendMagicPacket();
                    })
            }
            .width(StyleConstants.TWENTY_PERCENT)
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
    }
}