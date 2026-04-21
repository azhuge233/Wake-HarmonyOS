import { hdsMaterial, HdsNavDestination } from '@kit.UIDesignKit';

import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';

@Builder
export function HelpBuilder() {
    Help();
}

@Entry
@ComponentV2
struct Help {
    pathStack: NavPathStack | undefined = undefined;

    private LOG_TAG = '[pages/Help]';

    build() {
        HdsNavDestination() {
            Column() {
                Scroll() {
                    Text() {
                        Span($r("app.string.help_info_span1"))
                        Span($r("app.string.help_info_span4"))
                        Span($r("app.string.help_info_span2"))
                        Span($r("app.string.help_info_span3"))
                    }
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_SEVENTEEN)
                    .margin(StyleConstants.MARGIN_TWENTY_EIGHT)
                    .copyOption(CopyOptions.None)
                    .wordBreak(WordBreak.BREAK_ALL)
                }
                .scrollBar(BarState.Off)
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