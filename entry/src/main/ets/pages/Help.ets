import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit';
import { webview } from '@kit.ArkWeb';
import { Want } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';

import { Logger } from '../common/utils/Logger';

@Builder
export function HelpBuilder() {
    Help();
}

@Entry
@ComponentV2
struct Help {
    private LOG_TAG = '[pages/Help]';

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;

    private webController: webview.WebviewController = new webview.WebviewController();

    pathStack: NavPathStack | undefined = undefined;

    private openInSystemBrowser(url: string) {
        let want: Want = {
            'action': 'ohos.want.action.viewData',
            'entities': ['entity.system.browsable'],
            'uri': url
        };

        this.context.startAbility(want)
            .then(() => {
                Logger.info(`成功在系统浏览器中打开: ${url}`);
            })
            .catch((err: BusinessError) => {
                Logger.error(`打开系统浏览器失败: ${JSON.stringify(err)}`);
            });
    }

    build() {
        HdsNavDestination() {
            Column() {
                Web({
                    src: $rawfile("help.html"),
                    controller: this.webController
                })
                    .darkMode(WebDarkMode.Auto)
                    .onLoadIntercept((event) => {
                        if (!event || !event.data) return false; // true表示拦截，false表示放行

                        const url = event.data.getRequestUrl();

                        if (url.startsWith('http://') || url.startsWith('https://')) {
                            this.openInSystemBrowser(url);
                            return true;
                        }

                        return false;
                    });
            }
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.help_title")
                }
            },
            style: {
                systemMaterialEffect: { // 设置沉浸光感
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                },
            },
            enableComponentSafeArea: true // 启用标题栏占位
        })
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })
    }
}