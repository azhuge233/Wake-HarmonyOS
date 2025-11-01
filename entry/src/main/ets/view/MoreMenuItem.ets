import StyleConstants from "../common/constants/StyleConstants";

@Component
export default struct MoreMenuItem {
    menuText: Resource = $r("app.string.empty");
    menuIcon: Resource | string = $r("app.string.empty");

    private LOG_TAG = "[view/MenuItem]";

    build() {
        Row() {
            Image(this.menuIcon)
                .width(StyleConstants.ICON_WIDTH)
                .height(StyleConstants.ICON_HEIGHT)
                .margin(StyleConstants.MARGIN_TEN)

            Text(this.menuText)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                .fontWeight(FontWeight.Medium)
                .align(Alignment.Center)
                .textAlign(TextAlign.Start)
                .height(StyleConstants.FIVE_PERCENT)
                .width(StyleConstants.EIGHTY_PERCENT)
        }
        .margin({
            top: StyleConstants.MARGIN_TWO_PERCENT,
            left: StyleConstants.MARGIN_ONE_PERCENT,
            right: StyleConstants.MARGIN_THREE_PERCENT,
            bottom: StyleConstants.MARGIN_TWO_PERCENT
        })
    }
}