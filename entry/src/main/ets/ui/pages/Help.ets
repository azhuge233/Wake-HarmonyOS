import { common, Want } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';

import { Logger } from '../../common/log/Logger';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';

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

    private openInSystemBrowser(url: string): void {
        const want: Want = {
            'action': 'ohos.want.action.viewData',
            'entities': ['entity.system.browsable'],
            'uri': url
        };

        this.context.startAbility(want)
            .then(() => {
                Logger.info(this.LOG_TAG, `成功在系统浏览器中打开: ${url}`);
            })
            .catch((err: BusinessError) => {
                Logger.error(this.LOG_TAG, `打开系统浏览器失败: ${JSON.stringify(err)}`);
            });
    }

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
                        this.openInSystemBrowser(url);
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