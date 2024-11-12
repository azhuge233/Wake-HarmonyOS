import StyleConstants from "../common/constants/StyleConstants";

@Component
export default struct TextItem {
    @Link text: string;
    textResource: Resource = $r("app.string.empty");
    placeholderResource: Resource = $r("app.string.empty");

    build() {
        Row() {
            Text(this.textResource)
                .margin({
                    right: StyleConstants.MARGIN_FIVE_PERCENT
                })

            TextInput({
                placeholder: this.placeholderResource,
                text: this.text
            })
                .width(StyleConstants.EIGHTY_PERCENT)
                .placeholderColor($r("app.color.grey"))
                .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                .type(InputType.Normal)
                .onChange((value: string) => {
                    this.text = value;
                })
        }
        .margin({
            top: StyleConstants.MARGIN_TWO_PERCENT,
            bottom: StyleConstants.MARGIN_TWO_PERCENT
        })
    }
}