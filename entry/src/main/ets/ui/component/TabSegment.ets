import { StyleConstants } from '../../common/constants/StyleConstants';

/**
 * 页签分段：`background_secondary` 圆角槽（外沿 1vp `comp_divider` 描边）+
 * `comp_background_primary` 选中块，槽两端各留 `PAGE_PADDING`，各段等宽。
 *
 * 只画页签：不持选中态、不碰 `HdsTabs`——`titles` / `activeIndex` / `onSelect` 由页面给，
 * 段数与文字随 `titles` 长度变化，点选只上报下标。原生页签栏由页面 `HdsTabs.barHeight(0)` 收起：
 * 原生 `SelectedMode.BOARD` 的底板贴住页签栏左右边缘、首尾块直接贴住屏幕左右边缘、读作通栏标签，
 * 故两页改由本组件自绘。槽底是控件自身的槽，不是页面底分层，表单页仍不铺页面底。
 */
@ComponentV2
export struct TabSegment {
    @Require @Param titles: Array<ResourceStr>;
    @Require @Param activeIndex: number;
    @Event onSelect: (index: number) => void = () => {
    };

    build() {
        Row() {
            Row() {
                ForEach(this.titles, (title: ResourceStr, index: number) => {
                    Text(title)
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                        .fontWeight(this.activeIndex === index ? FontWeight.Medium : FontWeight.Normal)
                        .fontColor(this.activeIndex === index ?
                            $r('sys.color.font_primary') : $r('sys.color.font_secondary'))
                        .textAlign(TextAlign.Center)
                        .layoutWeight(1)
                        .height(StyleConstants.FULL_PERCENT)
                        // 选中块圆角取内缩后的高度折半：槽的 1vp 描边也占内缩带，块实际高 34，圆角 18 超过半高
                        .borderRadius((StyleConstants.TAB_SEGMENT_HEIGHT -
                            2 * StyleConstants.TAB_SEGMENT_INSET) / 2)
                        .backgroundColor(this.activeIndex === index ?
                            $r('sys.color.comp_background_primary') : Color.Transparent)
                        // 原生页签栏收起后「当前选中」仍能被读屏读到
                        .accessibilitySelected(this.activeIndex === index)
                        .onClick(() => {
                            this.onSelect(index);
                        })
                }, (title: ResourceStr, index: number) => index.toString())
            }
            .layoutWeight(1)
            .height(StyleConstants.TAB_SEGMENT_HEIGHT)
            .padding(StyleConstants.TAB_SEGMENT_INSET)
            .backgroundColor($r('sys.color.background_secondary'))
            .borderRadius(StyleConstants.TAB_SEGMENT_HEIGHT / 2)
            // 槽外沿 1vp 描边：深色下槽底与页面底同色，槽形由这条边读出
            .border({
                width: StyleConstants.CARD_BORDER_WIDTH,
                color: $r('sys.color.comp_divider')
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .padding({
            top: StyleConstants.CARD_SPACE,
            bottom: StyleConstants.CARD_SPACE,
            left: StyleConstants.PAGE_PADDING,
            right: StyleConstants.PAGE_PADDING
        })
    }
}
