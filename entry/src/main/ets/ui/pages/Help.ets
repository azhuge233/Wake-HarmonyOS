import { common } from '@kit.AbilityKit';

import { StyleConstants } from '../../common/constants/StyleConstants';
import { CollapsibleDivider } from '../component/CollapsibleDivider';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { openInSystemBrowser } from '../util/ExternalLink';
import { resourceText } from '../util/ResourceText';

@Builder
export function HelpBuilder() {
    Help();
}

/**
 * 帮助页：顶部导语 + 四节折叠正文 + 项目地址行，文案与地址全部取自资源档，语言跟随系统。
 * 展开态是 UI 状态，页面自持四个布尔；分组头复用 CollapsibleDivider，组件不持展开态。
 * 外链只给地址，打开动作与失败处理都在 ui/util/ExternalLink，页内不加载网页。
 */
@ComponentV2
struct Help {
    private LOG_TAG = '[ui/pages/Help]';

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    pathStack: NavPathStack | undefined = undefined;

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
     * indent 是相对整行左内边距 PAGE_PADDING 的追加缩进，子项传 PAGE_PADDING。
     */
    @Builder
    BulletItem(text: Resource, indent: number) {
        Row({ space: StyleConstants.PADDING_EIGHT }) {
            Text('•')
                .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                .fontColor($r('sys.color.font_primary'))

            Text(text)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                .fontColor($r('sys.color.font_primary'))
                .layoutWeight(1)
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(VerticalAlign.Top)
        .padding({ left: StyleConstants.PAGE_PADDING + indent })
    }

    @Builder
    UsageBody() {
        Text() {
            Span($r('app.string.help_usage_head'))
            Span($r('app.string.help_usage_bold'))
                .fontWeight(FontWeight.Bold)
            Span($r('app.string.help_usage_tail'))
        }
        .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
        .fontColor($r('sys.color.font_primary'))
        .width(StyleConstants.FULL_PERCENT)
        .margin({ top: StyleConstants.PADDING_EIGHT })
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
            .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
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
            .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
            .fontColor($r('sys.color.font_secondary'))
            .width(StyleConstants.FULL_PERCENT)
            .padding({
                left: StyleConstants.PAGE_PADDING,
                right: StyleConstants.PAGE_PADDING
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .margin({ top: StyleConstants.PADDING_EIGHT })
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
        .margin({ top: StyleConstants.PADDING_EIGHT })
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
        .margin({ top: StyleConstants.PADDING_EIGHT })
    }

    /** 四节之后一行：整行加粗，仓库名可点 */
    @Builder
    ProjectRow() {
        Text() {
            Span($r('app.string.help_project_label'))
            Span($r('app.string.help_link_repo_text'))
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(() => {
                    this.openLink($r('app.string.help_link_repo_url'));
                })
        }
        .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
        .fontColor($r('sys.color.font_primary'))
        .fontWeight(FontWeight.Bold)
        .width(StyleConstants.FULL_PERCENT)
    }

    @Builder
    PageContent() {
        Column() {
            // 导语在四个分组之上，不进任何一节
            Text($r('app.string.help_intro'))
                .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                .fontColor($r('sys.color.font_primary'))
                .width(StyleConstants.FULL_PERCENT)
                .margin({ bottom: StyleConstants.PAGE_PADDING })

            Column() {
                CollapsibleDivider({
                    label: $r('app.string.help_group_usage'),
                    expanded: this.usageExpanded,
                    onToggle: () => {
                        this.usageExpanded = !this.usageExpanded;
                    }
                })

                if (this.usageExpanded) {
                    this.UsageBody()
                }
            }
            .width(StyleConstants.FULL_PERCENT)
            .margin({ bottom: StyleConstants.PAGE_PADDING })

            Column() {
                CollapsibleDivider({
                    label: $r('app.string.help_group_add_device'),
                    expanded: this.addDeviceExpanded,
                    onToggle: () => {
                        this.addDeviceExpanded = !this.addDeviceExpanded;
                    }
                })

                if (this.addDeviceExpanded) {
                    this.AddDeviceBody()
                }
            }
            .width(StyleConstants.FULL_PERCENT)
            .margin({ bottom: StyleConstants.PAGE_PADDING })

            Column() {
                CollapsibleDivider({
                    label: $r('app.string.help_group_address_logic'),
                    expanded: this.logicExpanded,
                    onToggle: () => {
                        this.logicExpanded = !this.logicExpanded;
                    }
                })

                if (this.logicExpanded) {
                    this.AddressLogicBody()
                }
            }
            .width(StyleConstants.FULL_PERCENT)
            .margin({ bottom: StyleConstants.PAGE_PADDING })

            Column() {
                CollapsibleDivider({
                    label: $r('app.string.help_group_address_port'),
                    expanded: this.portExpanded,
                    onToggle: () => {
                        this.portExpanded = !this.portExpanded;
                    }
                })

                if (this.portExpanded) {
                    this.AddressPortBody()
                }
            }
            .width(StyleConstants.FULL_PERCENT)
            .margin({ bottom: StyleConstants.PAGE_PADDING })

            this.ProjectRow()
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
            content: (): void => {
                this.PageContent();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            }
        })
    }
}
