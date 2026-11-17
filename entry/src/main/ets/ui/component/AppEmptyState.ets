import { StyleConstants } from '../../common/constants/StyleConstants';

/** 空态：主文案 + 提示文案（可选）+ 重试入口（可选） */
@ComponentV2
export struct AppEmptyState {
    @Param text: ResourceStr = '';
    @Param hint: ResourceStr = '';
    @Param retryLabel: ResourceStr = '';
    @Param icon: Resource | null = null;
    @Event onRetry: () => void = () => {
    };

    build() {
        Column() {
            if (this.icon !== null) {
                Image(this.icon)
                    .width(StyleConstants.ICON_WIDTH)
                    .height(StyleConstants.ICON_HEIGHT)
                    .margin({
                        bottom: StyleConstants.MARGIN_TEN
                    })
            }

            Text(this.text)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHTEEN)
                .fontColor($r('sys.color.font_secondary'))
                .textAlign(TextAlign.Center)

            if (this.hint !== '') {
                Text(this.hint)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                    .fontColor($r('sys.color.font_secondary'))
                    .textAlign(TextAlign.Center)
                    .margin({
                        top: StyleConstants.MARGIN_TEN
                    })
            }

            if (this.retryLabel !== '') {
                Button(this.retryLabel, { type: ButtonType.Capsule })
                    .width(StyleConstants.SEVENTY_PERCENT)
                    .margin({
                        top: StyleConstants.MARGIN_TWENTY
                    })
                    .onClick(() => this.onRetry());
            }
        }
        .justifyContent(FlexAlign.Center)
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.EIGHTY_FIVE_PERCENT)
    }
}