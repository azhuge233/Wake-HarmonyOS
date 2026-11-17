import { StyleConstants } from '../../common/constants/StyleConstants';

/** 多设备卡片里的一台设备（V1）：图标 + 别名 */
@Component
export struct DeviceCard {
    @Prop name: string = '';
    @Prop mac: string = '';
    onTap: () => void = () => {
    };

    build() {
        Row() {
            Image($r('app.media.foreground'))
                .width(StyleConstants.THIRTY_PERCENT)
                .objectFit(ImageFit.Auto)
                .margin({
                    left: StyleConstants.MARGIN_EIGHT
                })

            Text(this.name)
                .width(StyleConstants.SEVENTY_PERCENT)
                .textAlign(TextAlign.Center)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
                .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .height(StyleConstants.FORM_ITEM_HEIGHT)
        .width(StyleConstants.EIGHTY_FIVE_PERCENT)
        .borderRadius(StyleConstants.BORDER_RADIUS_THIRTEEN)
        .backgroundColor($r('app.color.multiple_devices_form_item_color'))
        .margin({
            top: StyleConstants.MARGIN_THREE,
            bottom: StyleConstants.MARGIN_THREE
        })
        .onClick(() => this.onTap())
    }
}