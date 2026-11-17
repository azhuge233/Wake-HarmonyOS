import { StyleConstants } from '../../common/constants/StyleConstants';

/**
 * 加载蒙层：不设 visible 参数，调用点按条件创建即显示（沿用现有语义）。
 * 条件判断留在调用方的 builder 内部。
 */
@ComponentV2
export struct LoadingOverlay {
    @Param message: Resource = $r('app.string.loading_message');

    build() {
        Stack() {
            Column()
                .width(StyleConstants.FULL_PERCENT)
                .height(StyleConstants.FULL_PERCENT)
                .backgroundColor($r('app.color.background_transparent'))
                .blur(StyleConstants.PROGRESS_COLUMN_BLUR_LEVEL)
                .onClick(() => {
                })

            Column() {
                Progress({ value: 0, total: 100, type: ProgressType.Ring })
                    .width(StyleConstants.PROGRESS_WIDTH)
                    .color($r('sys.color.brand'))
                    .style({
                        strokeWidth: StyleConstants.PROGRESS_STROKE_WIDTH,
                        status: ProgressStatus.LOADING
                    })

                Text(this.message)
                    .margin({ top: StyleConstants.MARGIN_TWENTY })
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                    .fontColor($r('sys.color.font_primary'))
            }
            .width(StyleConstants.FULL_PERCENT)
            .height(StyleConstants.FULL_PERCENT)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .onClick(() => {
        })
    }
}