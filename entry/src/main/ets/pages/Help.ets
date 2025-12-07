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
        NavDestination() {
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
        .title($r("app.string.help_title"))
        .onReady((context: NavDestinationContext) => {
            this.pathStack = context.pathStack;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })

    }
}