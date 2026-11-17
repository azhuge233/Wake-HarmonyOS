import { StyleConstants } from '../../common/constants/StyleConstants';

/** 绑定页底部确认栏 */
@ComponentV2
export struct BindConfirmBar {
    @Param label: ResourceStr = $r('app.string.button_confirm_label');
    @Param isEnabled: boolean = false;
    @Event onConfirm: () => void = () => {
    };

    build() {
        Row() {
            Button(this.label, { type: ButtonType.Capsule })
                .width(StyleConstants.EIGHTY_PERCENT)
                .fontWeight(FontWeight.Medium)
                .enabled(this.isEnabled)
                .onClick(() => this.onConfirm())
        }
        .width(StyleConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.Center)
        .padding({
            top: StyleConstants.PADDING_SIXTEEN,
            bottom: StyleConstants.PADDING_SIXTEEN
        })
    }
}