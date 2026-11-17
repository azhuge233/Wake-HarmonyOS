import { StyleConstants } from '../../common/constants/StyleConstants';

/** 通用按钮：胶囊形态；primary 用强调样式，secondary 用普通样式。宽度由调用方的 .width() 决定，按钮填满该宽度 */
@ComponentV2
export struct AppButton {
    @Param label: ResourceStr = '';
    @Param isEnabled: boolean = true;
    @Param kind: string = 'primary';
    @Event onTap: () => void = () => {
    };

    build() {
        Button(this.label, { type: ButtonType.Capsule })
            .enabled(this.isEnabled)
            .buttonStyle(this.kind === 'secondary' ? ButtonStyleMode.NORMAL : ButtonStyleMode.EMPHASIZED)
            .width(StyleConstants.FULL_PERCENT)
            .fontWeight(FontWeight.Medium)
            .onClick(() => this.onTap());
    }
}