import Logger from '../common/utils/Logger';
import StyleConstants from '../common/constants/StyleConstants';

@Entry
@Component
struct Help {
    private LOG_TAG = '[pages/Help]';

    build() {
        Navigation() {
            Column() {
                Scroll() {
                    Text() {
                        Span($r("app.string.help_info_span1"))
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
        .titleMode(NavigationTitleMode.Mini)
        .title($r("app.string.help_title"))
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, "Loaded!");
        })

    }
}