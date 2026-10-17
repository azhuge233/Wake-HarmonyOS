import { StyleConstants } from "../common/constants/StyleConstants";

export enum INPUT_TYPE {
    NONE = 0,
    MAC = 1,
    ALIAS = 2,
    ADDRESS = 3,
    PORT = 4
}

/**
 * 受控输入项：值由父组件持有（value），本组件只负责显示和回传输入。
 * 父组件更新 value 时 TextInput 同步刷新；不要在本组件内保存输入副本。
 */
@ComponentV2
export default struct TextItem {
    @Param value: string = '';
    @Param inputType: INPUT_TYPE = INPUT_TYPE.NONE;
    @Param inputId: string = '';
    @Param isDefaultFocus: boolean = false;
    @Param label: Resource = $r("app.string.empty");
    @Param placeholder: Resource = $r("app.string.empty");

    @Event onChange: (value: string) => void = (value: string) => {};

    private maxLength: number = StyleConstants.TEXT_INPUT_DEFAULT_MAX_LENGTH;

    aboutToAppear(): void {
        if(this.inputType === INPUT_TYPE.MAC) this.maxLength = StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH;
        else if(this.inputType === INPUT_TYPE.ALIAS) this.maxLength = StyleConstants.TEXT_INPUT_ALIAS_MAX_LENGTH;
        else if(this.inputType === INPUT_TYPE.PORT) this.maxLength = StyleConstants.TEXT_INPUT_PORT_MAX_LENGTH;
    }

    build() {
        Column() {
            Row() {
                Text(this.label)
                    .alignSelf(ItemAlign.Center)
                    .margin({
                        right: StyleConstants.MARGIN_FIVE,
                    })

                TextInput({
                    placeholder: this.placeholder,
                    text: this.value
                })
                    .id(this.inputId)
                    .defaultFocus(this.isDefaultFocus)
                    .width(StyleConstants.EIGHTY_PERCENT)
                    .placeholderColor($r("sys.color.font_tertiary"))
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .maxLength(this.maxLength)
                    .type(this.inputType === INPUT_TYPE.PORT ? InputType.Number : InputType.Normal)
                    .onChange((value: string) => {
                        this.onChange(value);
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
