import StyleConstants from "../common/constants/StyleConstants";
import CommonUtils from "../common/utils/CommonUtils";
import CommonConstants from "../common/constants/CommonConstants";

@ComponentV2
export default struct DeviceTile {
    private LOG_TAG = "[view/DeviceTile]";

    @Param deviceMAC: Resource = $r("app.string.empty");
    @Param deviceAlias: Resource = $r("app.string.empty");
    @Param textButtonWake: Resource = $r("app.string.button_wake_label");
    @Param deviceMACAddr: string = '';
    @Param sendPacket: (macAddr: string) => void = () => {};

    build() {
        Row() {
            Column() {
                Text(this.deviceAlias)
                    .align(Alignment.Top)
                    .textAlign(TextAlign.Start)
                Text(this.deviceMAC)
                    .fontColor($r("app.color.darker_grey"))
            }
            .width(StyleConstants.SEVENTY_FIVE_PERCENT)

            Column() {
                Button(this.textButtonWake)
                    .onClick(() => {
                        CommonUtils.vibrate(CommonConstants.Vibrate_Effect_ID_HARD);
                        this.sendPacket(this.deviceMACAddr);
                    })
            }
            .width(StyleConstants.TWENTY_PERCENT)
            .margin({
                right: StyleConstants.MARGIN_FIVE_PERCENT
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
    }
}