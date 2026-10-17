import { StyleConstants } from "../common/constants/StyleConstants";

@ComponentV2
export default struct MoreMenuItem {
    private LOG_TAG = "[view/MenuItem]";

    @Param menuTitleText: Resource | string = $r("app.string.empty");
    @Param menuDescText: Resource | string | null = null;
    @Param menuIcon: Resource | string = $r("app.media.icon");

    build() {
        Row() {
            Image(this.menuIcon)
                .width(StyleConstants.ICON_WIDTH)
                .height(StyleConstants.ICON_HEIGHT)
                .margin(StyleConstants.MARGIN_TEN)

            Column() {
                Text(this.menuTitleText)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                    .fontWeight(FontWeight.Medium)
                    .textAlign(TextAlign.Start)
                    .width(StyleConstants.EIGHTY_PERCENT)

                if(this.menuDescText) {
                    Text(this.menuDescText)
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
                        .fontColor($r("sys.color.font_tertiary"))
                        .fontWeight(FontWeight.Normal)
                        .align(Alignment.Center)
                        .textAlign(TextAlign.Start)
                        .width(StyleConstants.EIGHTY_PERCENT)
                }
            }
        }
        .padding({
            top: StyleConstants.PADDING_FIVE,
            left: StyleConstants.PADDING_FIVE,
            right: StyleConstants.PADDING_FIVE,
            bottom: StyleConstants.PADDING_FIVE
        })
    }
}