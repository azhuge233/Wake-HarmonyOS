import { common } from '@kit.AbilityKit';

import { StyleConstants } from '../../common/constants/StyleConstants';
import { PageScaffold } from '../component/PageScaffold';
import { SettingGroup } from '../component/SettingGroup';
import { SettingRow } from '../component/SettingRow';
import { openInSystemBrowser } from '../util/ExternalLink';
import { resourceText } from '../util/ResourceText';

@Builder
export function HelpBuilder() {
    Help();
}

/**
 * 帮助页：顶部导语 + 四张折叠卡片，文案与地址全部取自资源档，语言跟随系统。
 * 展开态是 UI 状态，页面自持四个布尔；卡面复用 SettingGroup，卡头复用 SettingRow（不带图标，右侧槽放展开指示符）。
 * 外链只给地址，打开动作与失败处理都在 ui/util/ExternalLink，页内不加载网页。
 */
@ComponentV2
struct Help {
    private LOG_TAG = '[ui/pages/Help]';

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    @Local usageExpanded: boolean = false;
    @Local addDeviceExpanded: boolean = false;
    @Local logicExpanded: boolean = false;
    @Local portExpanded: boolean = false;

    /** 打开正文外链：地址取对应资源键，语言随系统解析 */
    private openLink(url: Resource): void {
        openInSystemBrowser(this.LOG_TAG, this.context, resourceText(url, this.context));
    }

    /**
     * 列表项：项目符号 + 内容列。内容列 layoutWeight(1)，换行后从文字列起始处续行（悬挂缩进）。
     * indent 是相对卡片正文左缘的追加缩进：最外层传 0，子项传 PAGE_PADDING。
     */
    @Builder
    BulletItem(text: Resource, indent: number) {
        Row({ space: StyleConstants.PADDING_EIGHT }) {
            Text('•')
                .fontSize(StyleConstants.TEXT_FONT_SIZE_FIFTEEN)
                .fontColor($r('sys.color.font_primary'))

            Text(text)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_FIFTEEN)
                .fontColor($r('sys.color.font_primary'))
                .layoutWeight(1)
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(VerticalAlign.Top)
        .padding({ left: indent })
    }

    /** 正文块的下内边距由各自承担：卡头行之下不留外边距，卡片底缘不空 */
    @Builder
    UsageBody() {
        Text() {
            Span($r('app.string.help_usage_head'))
            Span($r('app.string.help_usage_bold'))
                .fontWeight(FontWeight.Bold)
            Span($r('app.string.help_usage_tail'))
        }
        .fontSize(StyleConstants.TEXT_FONT_SIZE_FIFTEEN)
        .fontColor($r('sys.color.font_primary'))
        .width(StyleConstants.FULL_PERCENT)
        .padding({ bottom: StyleConstants.ROW_VERTICAL_PADDING })
    }

    @Builder
    AddDeviceBody() {
        Column({ space: StyleConstants.PADDING_EIGHT }) {
            Text() {
                Span($r('app.string.help_add_head'))
                Span($r('app.string.help_link_neigh_text'))
                    .fontFamily('monospace')
                    .fontColor($r('sys.color.font_emphasize'))
                    .onClick(() => {
                        this.openLink($r('app.string.help_link_neigh_url'));
                    })
                Span($r('app.string.help_add_mid'))
                Span($r('app.string.help_link_perm_text'))
                    .fontFamily('monospace')
                    .fontColor($r('sys.color.font_emphasize'))
                    .onClick(() => {
                        this.openLink($r('app.string.help_link_perm_url'));
                    })
                Span($r('app.string.help_add_tail'))
            }
            .fontSize(StyleConstants.TEXT_FONT_SIZE_FIFTEEN)
            .fontColor($r('sys.color.font_primary'))
            .width(StyleConstants.FULL_PERCENT)

            // AppGallery 那句是小字：更小字号、次要色，左右再缩进一档
            Text() {
                Span($r('app.string.help_add_note_head'))
                Span($r('app.string.help_link_agc_text'))
                    .fontColor($r('sys.color.font_emphasize'))
                    .onClick(() => {
                        this.openLink($r('app.string.help_link_agc_url'));
                    })
                Span($r('app.string.help_add_note_tail'))
            }
            .fontSize(StyleConstants.TEXT_FONT_SIZE_THIRTEEN)
            .fontColor($r('sys.color.font_secondary'))
            .width(StyleConstants.FULL_PERCENT)
            .padding({
                left: StyleConstants.PAGE_PADDING,
                right: StyleConstants.PAGE_PADDING
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: StyleConstants.ROW_VERTICAL_PADDING })
    }

    @Builder
    AddressLogicBody() {
        Column({ space: StyleConstants.PADDING_EIGHT }) {
            this.BulletItem($r('app.string.help_logic_default'), 0)
            this.BulletItem($r('app.string.help_logic_v4v6'), 0)
            this.BulletItem($r('app.string.help_logic_domain'), 0)
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: StyleConstants.ROW_VERTICAL_PADDING })
    }

    @Builder
    AddressPortBody() {
        Column({ space: StyleConstants.PADDING_EIGHT }) {
            this.BulletItem($r('app.string.help_port_no_address'), 0)
            this.BulletItem($r('app.string.help_port_v4'), 0)
            this.BulletItem($r('app.string.help_port_v6'), 0)
            this.BulletItem($r('app.string.help_port_domain'), 0)

            // 末条下挂两个子项：在列表项基础上再缩进一档
            Column({ space: StyleConstants.PADDING_EIGHT }) {
                this.BulletItem($r('app.string.help_port_sub_validate'), StyleConstants.PAGE_PADDING)
                this.BulletItem($r('app.string.help_port_sub_fallback'), StyleConstants.PAGE_PADDING)
            }
            .width(StyleConstants.FULL_PERCENT)
            .alignItems(HorizontalAlign.Start)
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .padding({ bottom: StyleConstants.ROW_VERTICAL_PADDING })
    }

    /**
     * 展开指示符：收起时旋转 180° 指下、展开时指上，200ms 动画，与 CollapsibleDivider 同一形态。
     * 展开态的状态语义落在指示符上：SettingRow 的契约本批不改，可见形态与设计一致。
     * 每张卡各一个无参 builder：闭包内直接读本卡的展开态，不经函数参数传值。
     */
    @Builder
    UsageIndicator() {
        SymbolGlyph($r('sys.symbol.chevron_up'))
            .fontSize(StyleConstants.DIVIDER_SYMBOL_SIZE)
            .fontColor([$r('sys.color.font_secondary')])
            .accessibilitySelected(this.usageExpanded)
            .rotate({
                angle: this.usageExpanded ? 0 : 180
            })
            .animation({
                duration: 200
            })
    }

    @Builder
    AddDeviceIndicator() {
        SymbolGlyph($r('sys.symbol.chevron_up'))
            .fontSize(StyleConstants.DIVIDER_SYMBOL_SIZE)
            .fontColor([$r('sys.color.font_secondary')])
            .accessibilitySelected(this.addDeviceExpanded)
            .rotate({
                angle: this.addDeviceExpanded ? 0 : 180
            })
            .animation({
                duration: 200
            })
    }

    @Builder
    LogicIndicator() {
        SymbolGlyph($r('sys.symbol.chevron_up'))
            .fontSize(StyleConstants.DIVIDER_SYMBOL_SIZE)
            .fontColor([$r('sys.color.font_secondary')])
            .accessibilitySelected(this.logicExpanded)
            .rotate({
                angle: this.logicExpanded ? 0 : 180
            })
            .animation({
                duration: 200
            })
    }

    @Builder
    PortIndicator() {
        SymbolGlyph($r('sys.symbol.chevron_up'))
            .fontSize(StyleConstants.DIVIDER_SYMBOL_SIZE)
            .fontColor([$r('sys.color.font_secondary')])
            .accessibilitySelected(this.portExpanded)
            .rotate({
                angle: this.portExpanded ? 0 : 180
            })
            .animation({
                duration: 200
            })
    }

    /** 一张卡的内容：卡头行 + 条件渲染的正文，由 SettingGroup 的卡面包住 */
    @Builder
    UsageCard() {
        SettingRow({
            title: $r('app.string.help_group_usage'),
            showArrow: false,
            interactive: true,
            titleColor: $r('sys.color.font_primary'),
            onTap: () => {
                this.usageExpanded = !this.usageExpanded;
            },
            trailing: (): void => {
                this.UsageIndicator();
            }
        })

        if (this.usageExpanded) {
            this.UsageBody();
        }
    }

    @Builder
    AddDeviceCard() {
        SettingRow({
            title: $r('app.string.help_group_add_device'),
            showArrow: false,
            interactive: true,
            titleColor: $r('sys.color.font_primary'),
            onTap: () => {
                this.addDeviceExpanded = !this.addDeviceExpanded;
            },
            trailing: (): void => {
                this.AddDeviceIndicator();
            }
        })

        if (this.addDeviceExpanded) {
            this.AddDeviceBody();
        }
    }

    @Builder
    LogicCard() {
        SettingRow({
            title: $r('app.string.help_group_address_logic'),
            showArrow: false,
            interactive: true,
            titleColor: $r('sys.color.font_primary'),
            onTap: () => {
                this.logicExpanded = !this.logicExpanded;
            },
            trailing: (): void => {
                this.LogicIndicator();
            }
        })

        if (this.logicExpanded) {
            this.AddressLogicBody();
        }
    }

    @Builder
    PortCard() {
        SettingRow({
            title: $r('app.string.help_group_address_port'),
            showArrow: false,
            interactive: true,
            titleColor: $r('sys.color.font_primary'),
            onTap: () => {
                this.portExpanded = !this.portExpanded;
            },
            trailing: (): void => {
                this.PortIndicator();
            }
        })

        if (this.portExpanded) {
            this.AddressPortBody();
        }
    }

    @Builder
    PageContent() {
        Column({ space: StyleConstants.CARD_SPACE }) {
            // 导语在四张卡之上、不进任何一张卡；左右内边距让它与卡头标题落在同一列
            Text($r('app.string.help_intro'))
                .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHTEEN)
                .fontColor($r('sys.color.font_primary'))
                .width(StyleConstants.FULL_PERCENT)
                .padding({
                    left: StyleConstants.CARD_PADDING,
                    right: StyleConstants.CARD_PADDING
                })

            SettingGroup({
                rows: (): void => {
                    this.UsageCard();
                }
            })

            SettingGroup({
                rows: (): void => {
                    this.AddDeviceCard();
                }
            })

            SettingGroup({
                rows: (): void => {
                    this.LogicCard();
                }
            })

            SettingGroup({
                rows: (): void => {
                    this.PortCard();
                }
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .padding({
            top: StyleConstants.PAGE_PADDING,
            bottom: StyleConstants.PAGE_PADDING,
            left: StyleConstants.PAGE_PADDING,
            right: StyleConstants.PAGE_PADDING
        })
    }

    build() {
        PageScaffold({
            title: $r('app.string.help_title'),
            logTag: this.LOG_TAG,
            scrollable: true,
            pageBackground: $r('sys.color.background_secondary'),
            content: (): void => {
                this.PageContent();
            }
        })
    }
}
