import { StyleConstants } from '../../common/constants/StyleConstants';

/**
 * 设置分组卡：卡面四件套（底色 / 描边 / 圆角 / 裁剪）+ 左右内边距，行由调用方经 rows 传入。
 * 上下内边距不自带：卡片自带会让首尾行比组内其余行多出一截，改由每行承担（ROW_VERTICAL_PADDING）。
 */
@ComponentV2
export struct SettingGroup {
    @Param title: ResourceStr = '';
    @BuilderParam rows: () => void;

    build() {
        Column() {
            if (this.title !== '') {
                Text(this.title)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                    .fontColor($r('sys.color.font_secondary'))
                    .width(StyleConstants.FULL_PERCENT)
                    .padding({
                        top: StyleConstants.PADDING_FIVE,
                        bottom: StyleConstants.PADDING_FIVE
                    })
            }

            this.rows();
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .backgroundColor($r('sys.color.comp_background_primary'))
        .border({
            width: StyleConstants.CARD_BORDER_WIDTH,
            color: $r('sys.color.comp_divider')
        })
        .borderRadius(StyleConstants.CARD_RADIUS)
        .padding({
            left: StyleConstants.CARD_PADDING,
            right: StyleConstants.CARD_PADDING
        })
        .clip(true)
    }
}
