import { common } from '@kit.AbilityKit';

import { CommonConstants } from '../../common/constants/CommonConstants';
import { StyleConstants } from '../../common/constants/StyleConstants';
import { AboutViewModel } from '../../viewmodel/AboutViewModel';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { openInSystemBrowser } from '../util/ExternalLink';

@Builder
export function AboutBuilder() {
    About();
}

/**
 * 关于子页：版本号、作者、开源地址三项；版本号只在关于页，设置页不再有版本行。
 * 三项是信息展示行（不是操作行）：小字标签在上、值在下，不带箭头；只有地址那一行可点。
 * 卡面在页内装配、不复用 SettingGroup：SettingGroup 自带左右内边距 CARD_PADDING，
 * 与行自身的左右 CARD_PADDING 会叠成 32；卡面仍取同一组常量。
 */
@ComponentV2
struct About {
    private LOG_TAG = '[ui/pages/About]';

    private viewModel: AboutViewModel = new AboutViewModel();

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    pathStack: NavPathStack | undefined = undefined;

    aboutToAppear(): void {
        this.viewModel.loadVersion();
    }

    /** 打开外链：实现与失败处理都在 ui/util/ExternalLink，本页只给日志标签、上下文与地址 */
    private openSource(): void {
        openInSystemBrowser(this.LOG_TAG, this.context, CommonConstants.OPEN_SOURCE_URL);
    }

    @Builder
    InfoText(label: ResourceStr, value: ResourceStr, valueColor: ResourceColor) {
        Column({ space: StyleConstants.PADDING_TWO }) {
            Text(label)
                .width(StyleConstants.FULL_PERCENT)
                .textAlign(TextAlign.Start)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
                .fontColor($r('sys.color.font_tertiary'))
                .fontWeight(FontWeight.Normal)

            Text(value)
                .width(StyleConstants.FULL_PERCENT)
                .textAlign(TextAlign.Start)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                .fontColor(valueColor)
                .fontWeight(FontWeight.Normal)
        }
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Start)
        .padding({
            top: StyleConstants.ROW_VERTICAL_PADDING,
            bottom: StyleConstants.ROW_VERTICAL_PADDING
        })
    }

    @Builder
    VersionRow() {
        this.InfoText($r('app.string.about_version'),
            `${this.viewModel.versionName} (${this.viewModel.versionCode})`, $r('sys.color.font_primary'))
    }

    @Builder
    AuthorRow() {
        this.InfoText($r('app.string.about_author'), CommonConstants.OPEN_SOURCE_AUTHOR, $r('sys.color.font_primary'))
    }

    @Builder
    OpenSourceRow() {
        Column() {
            this.InfoText($r('app.string.about_open_source'), CommonConstants.OPEN_SOURCE_URL,
                $r('sys.color.font_emphasize'))
        }
        .width(StyleConstants.FULL_PERCENT)
        .onClick(() => {
            this.openSource();
        })
    }

    @Builder
    PageContent() {
        Column() {
            Column() {
                this.VersionRow();
                this.AuthorRow();
                this.OpenSourceRow();
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
        .width(StyleConstants.FULL_PERCENT)
        .padding({
            top: StyleConstants.PAGE_PADDING,
            bottom: StyleConstants.PAGE_PADDING,
            left: StyleConstants.PAGE_PADDING,
            right: StyleConstants.PAGE_PADDING
        })
    }

    build() {
        PageScaffold({
            title: $r('app.string.about_title'),
            logTag: this.LOG_TAG,
            scrollable: true,
            pageBackground: $r('sys.color.background_secondary'),
            content: (): void => {
                this.PageContent();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            }
        })
    }
}
