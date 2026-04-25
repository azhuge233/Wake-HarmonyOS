import StyleConstants from "../common/constants/StyleConstants";
import CommonUtils from "../common/utils/CommonUtils";
import CommonConstants from "../common/constants/CommonConstants";

@ComponentV2
export default struct DeviceTile {
    private LOG_TAG = "[view/DeviceTile]";

    @Param deviceMAC: string = '';
    @Param deviceAlias: string = '';
    @Param deviceAddress: string = '';
    @Param devicePort: number = 9;
    @Param sendPacket: (mac: string, targetAddr: string, targetPort: number) => void = () => {};

    build() {
        Row() {
            Column() {
                Text(this.deviceAlias)
                    .fontColor($r("sys.color.font_primary"))

                Text(`MAC: ${this.deviceMAC}`)
                    .fontColor($r("sys.color.font_tertiary"))

                if(!CommonUtils.isStringNullOrEmpty(this.deviceAddress)) {
                    Text(`${this.deviceAddress}:${this.devicePort}`)
                        .fontColor($r("sys.color.font_tertiary"))
                        .textOverflow({
                            overflow: TextOverflow.MARQUEE
                        })
                        .padding({
                            left: StyleConstants.PADDING_TEN,
                            right: StyleConstants.PADDING_TEN
                        })
                }
            }
            .width(StyleConstants.SIXTY_FIVE_PERCENT)
            .alignItems(HorizontalAlign.Center)

            Column() {
                Button($r("app.string.button_wake_label"))
                    .onClick(() => {
                        CommonUtils.vibrate(CommonConstants.Vibrate_Effect_ID_HARD);
                        this.sendPacket(this.deviceMAC, this.deviceAddress, this.devicePort);
                    })
            }
            .width(StyleConstants.TWENTY_PERCENT)
            .alignItems(HorizontalAlign.Center)
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.DEVICE_TILE_HEIGHT)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
    }
}