import { StyleConstants } from '../../common/constants/StyleConstants';

/** 设置行：图标 + 标题 + 描述行（空则不渲染）+ 值 / 单选标记 */
@ComponentV2
export struct SettingRow {
    @Param icon: ResourceStr | null = null;
    @Param title: ResourceStr = '';
    @Param desc: ResourceStr = '';
    @Param value: ResourceStr = '';
    @Param checked: boolean = false;
    @Param showRadio: boolean = false;
    @Event onTap: () => void = () => {
    };

    build() {
        Row() {
            if (this.icon !== null) {
                Image(this.icon)
                    .width(StyleConstants.ICON_WIDTH)
                    .height(StyleConstants.ICON_HEIGHT)
                    .margin(StyleConstants.MARGIN_TEN)
            }

            Column() {
                Text(this.title)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                    .fontWeight(FontWeight.Medium)
                    .textAlign(TextAlign.Start)
                    .width(StyleConstants.EIGHTY_PERCENT)

                if (this.desc !== '') {
                    Text(this.desc)
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
                        .fontColor($r('sys.color.font_tertiary'))
                        .fontWeight(FontWeight.Normal)
                        .textAlign(TextAlign.Start)
                        .width(StyleConstants.EIGHTY_PERCENT)
                }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            if (this.value !== '') {
                Text(this.value)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                    .fontColor($r('sys.color.font_secondary'))
            }

            if (this.showRadio) {
                Radio({ value: this.title.toString(), group: 'settingRow' })
                    .checked(this.checked)
                    .height(StyleConstants.RADIO_SIZE)
                    .width(StyleConstants.RADIO_SIZE)
                    .hitTestBehavior(HitTestMode.None)
                    .margin({
                        right: StyleConstants.PADDING_FIFTEEN
                    })
            }
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(VerticalAlign.Center)
        .padding({
            top: StyleConstants.PADDING_FIVE,
            left: StyleConstants.PADDING_FIVE,
            right: StyleConstants.PADDING_FIVE,
            bottom: StyleConstants.PADDING_FIVE
        })
        .onClick(() => this.onTap())
    }
}