import { StyleConstants } from '../../common/constants/StyleConstants';
import { AppInput } from './AppInput';

export enum INPUT_TYPE {
    NONE = 0,
    MAC = 1,
    ALIAS = 2,
    ADDRESS = 3,
    PORT = 4
}

/**
 * 受控输入项：标签 + 输入框。值由父组件持有（value），本组件只负责显示和回传输入。
 * 父组件更新 value 时输入框同步刷新；不要在本组件内保存输入副本。
 */
@ComponentV2
export default struct TextItem {
    @Param value: string = '';
    @Param inputType: INPUT_TYPE = INPUT_TYPE.NONE;
    @Param inputId: string = '';
    @Param isDefaultFocus: boolean = false;
    @Param label: Resource = $r('app.string.empty');
    @Param placeholder: Resource = $r('app.string.empty');
    @Param error: string = '';

    @Event onValueChange: (value: string) => void = (value: string) => {
    };

    private maxLength: number = StyleConstants.TEXT_INPUT_DEFAULT_MAX_LENGTH;

    aboutToAppear(): void {
        if (this.inputType === INPUT_TYPE.MAC) this.maxLength = StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH;
        else if (this.inputType === INPUT_TYPE.ALIAS) this.maxLength = StyleConstants.TEXT_INPUT_ALIAS_MAX_LENGTH;
        else if (this.inputType === INPUT_TYPE.PORT) this.maxLength = StyleConstants.TEXT_INPUT_PORT_MAX_LENGTH;
    }

    build() {
        Column() {
            Row() {
                Text(this.label)
                    .alignSelf(ItemAlign.Center)
                    .margin({
                        right: StyleConstants.MARGIN_FIVE
                    })

                AppInput({
                    value: this.value,
                    maxLength: this.maxLength,
                    numeric: this.inputType === INPUT_TYPE.PORT,
                    placeholder: this.placeholder,
                    inputId: this.inputId,
                    isDefaultFocus: this.isDefaultFocus,
                    error: this.error,
                    onValueChange: (value: string) => {
                        this.onValueChange(value);
                    }
                })
                    .width(StyleConstants.EIGHTY_PERCENT)
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