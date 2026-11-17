import { StyleConstants } from '../../common/constants/StyleConstants';

/**
 * 可折叠分组头：标签两侧各一段 1vp 线，标签下方不画线、也不盖任何底色。
 *
 * 断口用分段绘制消除：在整条线上盖一块页面底色就必须写死一个颜色，页面底换一档就露色块；
 * 分段后页面底自然透出，组件不需要知道页面底色。
 * 展开状态由页面持有：本组件只按 `expanded` 画箭头方向，并在整行被点时回调 `onToggle`。
 */
@ComponentV2
export struct CollapsibleDivider {
    @Require @Param label: ResourceStr;
    @Require @Param expanded: boolean;
    @Event onToggle: () => void = () => {
    };

    build() {
        Row() {
            Divider()
                .strokeWidth(StyleConstants.DIVIDER_STOKE_WIDTH)
                .color($r('sys.color.comp_divider'))
                .layoutWeight(1)

            Text(this.label)
                .fontSize(StyleConstants.DIVIDER_FONT_SIZE)
                .fontColor($r('sys.color.font_secondary'))
                .margin({
                    left: StyleConstants.MARGIN_TEN,
                    right: StyleConstants.MARGIN_TEN
                })

            SymbolGlyph($r('sys.symbol.chevron_up'))
                .fontSize(StyleConstants.DIVIDER_SYMBOL_SIZE)
                .fontColor([$r('sys.color.font_secondary')])
                .rotate({
                    angle: this.expanded ? 0 : 180
                })
                .animation({
                    duration: 200
                })

            Divider()
                .strokeWidth(StyleConstants.DIVIDER_STOKE_WIDTH)
                .color($r('sys.color.comp_divider'))
                .layoutWeight(1)
        }
        .width(StyleConstants.FULL_PERCENT)
        // 整行高 40：点击区覆盖整条线，不只是标签
        .height(40)
        .alignItems(VerticalAlign.Center)
        .onClick(() => this.onToggle())
    }
}
