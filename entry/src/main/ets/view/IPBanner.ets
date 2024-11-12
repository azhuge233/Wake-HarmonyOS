import StyleConstants from "../common/constants/StyleConstants";

@Component
export default struct IPBanner {
    @Link ipBannerText: string;

    build() {
        Text(this.ipBannerText)
            .maxLines(StyleConstants.BANNER_MAX_LINE)
            .fontSize(StyleConstants.BANNER_FONT_SIZE)
            .fontWeight(StyleConstants.BANNER_FONT_WEIGHT)
            .backgroundColor($r("app.color.grey"))
            .width(StyleConstants.FULL_PERCENT)
            .textAlign(TextAlign.Center)
    }
}