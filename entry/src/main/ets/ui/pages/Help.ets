import { common } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';

import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { openInSystemBrowser } from '../util/ExternalLink';

@Builder
export function HelpBuilder() {
    Help();
}

@ComponentV2
struct Help {
    private LOG_TAG = '[ui/pages/Help]';

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    private webController: webview.WebviewController = new webview.WebviewController();

    pathStack: NavPathStack | undefined = undefined;

    @Builder
    PageContent() {
        Column() {
            Web({
                src: $rawfile('help.html'),
                controller: this.webController
            })
                .darkMode(WebDarkMode.Auto)
                .onLoadIntercept((event) => {
                    if (!event || !event.data) return false;

                    const url = event.data.getRequestUrl();

                    if (url.startsWith('http://') || url.startsWith('https://')) {
                        // 打开外链的唯一实现在 ui/util/ExternalLink；日志标签仍用本页的
                        openInSystemBrowser(this.LOG_TAG, this.context, url);
                        return true;
                    }

                    return false;
                });
        }
    }

    @Builder
    PageOverlay() {
    }

    build() {
        PageScaffold({
            title: $r('app.string.help_title'),
            logTag: this.LOG_TAG,
            content: (): void => {
                this.PageContent();
            },
            overlayContent: (): void => {
                this.PageOverlay();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            }
        })
    }
}
