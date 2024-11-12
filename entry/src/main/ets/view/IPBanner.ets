@Component
export default struct IPBanner {
    @Link ipBannerText: string;

    build() {
        Text(this.ipBannerText)
            .maxLines(1)
            .fontSize(15)
            .fontWeight(5)
            .backgroundColor($r("app.color.grey"))
            .width('100%')
            .textAlign(TextAlign.Center)
    }
}