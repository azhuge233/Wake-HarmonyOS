import { StyleConstants } from '../../common/constants/StyleConstants';

/**
 * 卡片三态骨架（V1）：未绑定 / 运行中 / 结果。
 * 两张卡片页共用这一份，同一个三态不再写两遍。
 */
@Component
export struct CardStateView {
    @Prop state: string = 'unbound';
    @Prop resultText: string = '';

    build() {
        Column() {
            if (this.state === 'running') {
                LoadingProgress()
                    .height(StyleConstants.SIXTY_PERCENT)
                    .width(StyleConstants.SIXTY_PERCENT)
                    .color(Color.White)
            } else if (this.state === 'result') {
                Blank()

                Text(this.resultText)
                    .height(StyleConstants.EIGHTY_FIVE_PERCENT)
                    .layoutWeight(1)
                    .fontColor(Color.White)
                    .textAlign(TextAlign.Center)

                Text($r('app.string.form_run_complete_label'))
                    .height(StyleConstants.TEN_PERCENT)
                    .width(StyleConstants.FULL_PERCENT)
                    .alignSelf(ItemAlign.Center)
                    .textAlign(TextAlign.Center)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHT)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Color.White)
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({ overflow: TextOverflow.Clip })
            } else {
                Text($r('app.string.form_init_label'))
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Color.White)
                    .textAlign(TextAlign.Center)
            }
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.Center)
    }
}