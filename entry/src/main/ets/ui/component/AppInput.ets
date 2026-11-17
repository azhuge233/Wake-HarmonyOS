import { StyleConstants } from '../../common/constants/StyleConstants';

/** 受控输入框：值由调用方持有，本组件只显示与回传 */
@ComponentV2
export struct AppInput {
    @Param value: string = '';
    @Param maxLength: number = StyleConstants.TEXT_INPUT_DEFAULT_MAX_LENGTH;
    @Param numeric: boolean = false;
    @Param placeholder: Resource = $r('app.string.empty');
    @Param inputId: string = '';
    @Param isDefaultFocus: boolean = false;
    @Param error: string = '';
    @Event onValueChange: (value: string) => void = (value: string) => {
    };

    build() {
        Column() {
            TextInput({ placeholder: this.placeholder, text: this.value })
                .id(this.inputId)
                .defaultFocus(this.isDefaultFocus)
                .width(StyleConstants.FULL_PERCENT)
                .placeholderColor($r('sys.color.font_tertiary'))
                .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                .maxLength(this.maxLength)
                .type(this.numeric ? InputType.Number : InputType.Normal)
                // 输入区与页面底之间留一条边界；底透明，不叠第二层底色
                .border({
                    width: StyleConstants.CARD_BORDER_WIDTH,
                    color: $r('sys.color.comp_divider')
                })
                .borderRadius(StyleConstants.INPUT_BORDER_RADIUS)
                .backgroundColor(Color.Transparent)
                .onChange((value: string) => {
                    this.onValueChange(value);
                });

            if (this.error !== '') {
                Text(this.error)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
                    .fontColor($r('sys.color.warning'))
                    .width(StyleConstants.EIGHTY_PERCENT)
            }
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
    }
}