import StyleConstants from "../common/constants/StyleConstants";

export enum INPUT_TYPE {
    NONE = 0,
    MAC = 1,
    ALIAS = 2
}

@Component
export default struct TextItem {
    @Link text: string;
    textResource: Resource = $r("app.string.empty");
    placeholderResource: Resource = $r("app.string.empty");

    inputType: INPUT_TYPE = INPUT_TYPE.NONE;

    private maxLength: number = StyleConstants.TEXT_INPUT_DEFAULT_MAX_LENGTH;

    aboutToAppear(): void {
        if(this.inputType == INPUT_TYPE.MAC) this.maxLength = StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH;
        else this.maxLength = StyleConstants.TEXT_INPUT_ALIAS_MAX_LENGTH;
    }

    build() {
        Row() {
            Text(this.textResource)
                .margin({
                    right: StyleConstants.MARGIN_FIVE_PERCENT,
                    bottom: StyleConstants.MARGIN_SEVEN_PERCENT
                })

            TextInput({
                placeholder: this.placeholderResource,
                text: this.text
            })
                .width(StyleConstants.EIGHTY_PERCENT)
                .placeholderColor($r("app.color.grey"))
                .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                .showCounter(true, {
                    thresholdPercentage: undefined
                })
                .maxLength(this.maxLength)
                .type(InputType.Normal)
                .onChange((value: string) => {
                    this.text = value;
                })
        }
        .alignItems(VerticalAlign.Center)
        .margin({
            top: StyleConstants.MARGIN_TWO_PERCENT,
            bottom: StyleConstants.MARGIN_TWO_PERCENT
        })
    }
}