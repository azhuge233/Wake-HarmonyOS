import { StyleConstants } from '../../common/constants/StyleConstants';

/** 设置分组：可选标题 + 行集合 */
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
    }
}