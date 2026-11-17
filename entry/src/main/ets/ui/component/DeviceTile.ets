import { StyleConstants } from '../../common/constants/StyleConstants';
import { CommonConstants } from '../../common/constants/CommonConstants';
import { isStringNullOrEmpty } from '../../common/util/Strings';
import { vibrate } from '../feedback/Feedback';
import { DeviceViewModel } from '../../viewmodel/DeviceViewModel';

/** 设备条目：别名 / MAC / 可选地址端口 + 唤醒按钮 */
@ComponentV2
export struct DeviceTile {
    @Param device: DeviceViewModel = new DeviceViewModel();
    @Event onWake: () => void = () => {
    };

    build() {
        Row() {
            Column() {
                Text(this.device.Alias)
                    .fontColor($r('sys.color.font_primary'))

                Text(`MAC: ${this.device.MAC}`)
                    .fontColor($r('sys.color.font_tertiary'))

                if (!isStringNullOrEmpty(this.device.Address)) {
                    Text(`${this.device.Address}:${this.device.Port}`)
                        .fontColor($r('sys.color.font_tertiary'))
                        .textOverflow({
                            overflow: TextOverflow.MARQUEE
                        })
                        .padding({
                            left: StyleConstants.PADDING_TEN,
                            right: StyleConstants.PADDING_TEN
                        })
                }
            }
            .width(StyleConstants.SEVENTY_TWO_PERCENT)
            .alignItems(HorizontalAlign.Center)

            Column() {
                Button($r('app.string.button_wake_label'))
                    .onClick(() => {
                        vibrate(CommonConstants.VIBRATE_EFFECT_ID_HARD);
                        this.onWake();
                    })
            }
            .width(StyleConstants.TWENTY_TWO_PERCENT)
            .alignItems(HorizontalAlign.Center)
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.DEVICE_TILE_HEIGHT)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .border({
            width: StyleConstants.CARD_BORDER_WIDTH,
            color: $r('sys.color.comp_divider')
        })
        .borderRadius(StyleConstants.CARD_RADIUS)
        .clip(true)
    }
}