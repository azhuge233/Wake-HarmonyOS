import StyleConstants from "../common/constants/StyleConstants";

@ComponentV2
export default struct MoreMenuItem {
    private LOG_TAG = "[view/MenuItem]";

    @Param menuText: Resource = $r("app.string.empty");
    @Param menuIcon: Resource | string = $r("app.string.empty");

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
        .padding({
            top: StyleConstants.PADDING_FIVE,
            left: StyleConstants.PADDING_FIVE,
            right: StyleConstants.PADDING_FIVE,
            bottom: StyleConstants.PADDING_FIVE
        })
    }
}