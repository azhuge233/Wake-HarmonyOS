import { StyleConstants } from '../../common/constants/StyleConstants';

/**
 * 设置行：图标 +「标题 / 描述」列 + 右侧尾随槽（箭头 → 控件）。
 *
 * `showArrow` / `interactive` 必填：漏传在编译期报错，不静默渲染成另一种行。
 * 左右内边距由卡片承担（`CARD_PADDING`），本件只给上下内边距（`ROW_VERTICAL_PADDING`）。
 * `interactive` 为假时不挂任何点击回调：挂空回调会把整行变成点击目标，点击区随之变大。
 */
@ComponentV2
export struct SettingRow {
    // 收窄为 Resource：图标只能由 SymbolGlyph 渲染，字符串形态没有渲染路径，误传挡在编译期
    @Param icon: Resource | null = null;
    @Param title: ResourceStr = '';
    @Param desc: ResourceStr = '';
    @Require @Param showArrow: boolean;
    @Require @Param interactive: boolean;
    @Event onTap: () => void = () => {
    };

    @Builder
    emptyTrailing() {
    }

    @BuilderParam trailing: () => void = this.emptyTrailing;

    @Builder
    RowContent() {
        if (this.icon !== null) {
            // 图标盒宽固定 32、图标 28 居中：括号内左右各 2，文字列左缘由盒子钉住，不再随图标尺寸漂移
            Row() {
                SymbolGlyph(this.icon)
                    .fontSize(StyleConstants.ICON_WIDTH)
                    .fontColor([$r('sys.color.font_primary')])
            }
            .width(StyleConstants.ICON_BOX_WIDTH)
            .justifyContent(FlexAlign.Center)
        }

        Column() {
            Text(this.title)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                .fontWeight(FontWeight.Medium)
                .textAlign(TextAlign.Start)
                .width(StyleConstants.FULL_PERCENT)

            if (this.desc !== '') {
                Text(this.desc)
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
                    .fontColor($r('sys.color.font_tertiary'))
                    .fontWeight(FontWeight.Normal)
                    .textAlign(TextAlign.Start)
                    .width(StyleConstants.FULL_PERCENT)
            }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        // 文字列到图标盒的距离：无图标时不留这段空白
        .margin({ left: this.icon !== null ? StyleConstants.ICON_TEXT_GAP : 0 })

        if (this.showArrow) {
            SymbolGlyph($r('sys.symbol.chevron_right'))
                .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                .fontColor([$r('sys.color.font_secondary')])
        }

        this.trailing()
    }

    build() {
        if (this.interactive) {
            Row() {
                this.RowContent();
            }
            .width(StyleConstants.FULL_PERCENT)
            .alignItems(VerticalAlign.Center)
            .padding({
                top: StyleConstants.ROW_VERTICAL_PADDING,
                bottom: StyleConstants.ROW_VERTICAL_PADDING
            })
            .onClick(() => this.onTap())
        } else {
            Row() {
                this.RowContent();
            }
            .width(StyleConstants.FULL_PERCENT)
            .alignItems(VerticalAlign.Center)
            .padding({
                top: StyleConstants.ROW_VERTICAL_PADDING,
                bottom: StyleConstants.ROW_VERTICAL_PADDING
            })
        }
    }
}
