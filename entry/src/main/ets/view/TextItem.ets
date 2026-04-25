import StyleConstants from "../common/constants/StyleConstants";

export enum INPUT_TYPE {
    NONE = 0,
    MAC = 1,
    ALIAS = 2,
    ADDRESS = 3,
    PORT = 4
}

@ComponentV2
export default struct TextItem {
    @Param text: string | number = '';
    @Param inputType: INPUT_TYPE = INPUT_TYPE.NONE;
    @Param inputId: string = '';
    @Param isDefaultFocus: boolean = false;
    @Param textResource: Resource = $r("app.string.empty");
    @Param placeholderResource: Resource = $r("app.string.empty");

    @Event onInputChange: (value: string | number) => void = (value: string | number) => {};

    private maxLength: number = StyleConstants.TEXT_INPUT_DEFAULT_MAX_LENGTH;

    aboutToAppear(): void {
        if(this.inputType === INPUT_TYPE.MAC) this.maxLength = StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH;
        else if(this.inputType === INPUT_TYPE.ALIAS) this.maxLength = StyleConstants.TEXT_INPUT_ALIAS_MAX_LENGTH;
        else if(this.inputType === INPUT_TYPE.PORT) this.maxLength = StyleConstants.TEXT_INPUT_PORT_MAX_LENGTH;
    }

    build() {
        Column() {
            Row() {
                Text(this.textResource)
                    .alignSelf(ItemAlign.Center)
                    .margin({
                        right: StyleConstants.MARGIN_FIVE,
                    })

                TextInput({
                    placeholder: this.placeholderResource,
                    text: `${this.text}`
                })
                    .id(this.inputId)
                    .defaultFocus(this.isDefaultFocus)
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .placeholderColor($r("app.color.input_placeholder_grey"))
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .maxLength(this.maxLength)
                    .type(this.inputType === INPUT_TYPE.PORT ? InputType.Number : InputType.Normal)
                    .onChange((value: string) => {
                        this.onInputChange(value);
                    })
            }
            .width(StyleConstants.FULL_PERCENT)
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .margin({
            top: StyleConstants.MARGIN_TWO_PERCENT,
            bottom: StyleConstants.MARGIN_TWO_PERCENT
        })
    }
}