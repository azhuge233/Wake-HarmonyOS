import StyleConstants from "../common/constants/StyleConstants";

export enum INPUT_TYPE {
    NONE = 0,
    MAC = 1,
    ALIAS = 2
}

@ComponentV2
export default struct TextItem {
    @Param text: string = '';
    @Param inputType: INPUT_TYPE = INPUT_TYPE.NONE;
    @Param inputId: string = '';
    @Param isDefaultFocus: boolean = false;
    @Param textResource: Resource = $r("app.string.empty");
    @Param placeholderResource: Resource = $r("app.string.empty");

    @Event onInputChange: (value: string) => void = (value: string) => {};

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
                    bottom: StyleConstants.MARGIN_SIX_PERCENT
                })

            TextInput({
                placeholder: this.placeholderResource,
                text: this.text
            })
                .id(this.inputId)
                .defaultFocus(this.isDefaultFocus)
                .width(StyleConstants.EIGHTY_PERCENT)
                .placeholderColor($r("app.color.input_placeholder_grey"))
                .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                .showCounter(true, {
                    thresholdPercentage: undefined
                })
                .maxLength(this.maxLength)
                .type(InputType.Normal)
                .onChange((value: string) => {
                    this.onInputChange(value);
                })
        }
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({
            top: StyleConstants.MARGIN_TWO_PERCENT,
            bottom: StyleConstants.MARGIN_TWO_PERCENT
        })
    }
}