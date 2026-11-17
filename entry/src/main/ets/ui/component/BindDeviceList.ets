import { StyleConstants } from '../../common/constants/StyleConstants';
import { isStringNullOrEmpty } from '../../common/util/Strings';
import { DeviceViewModel } from '../../viewmodel/DeviceViewModel';

/**
 * 绑定页的设备网格：单选与多选只差调用方传一个还是多个 ID。
 * scroller 由页面持有，页面还要把它交给 HdsNavigation.bindToScrollable。
 */
@ComponentV2
export struct BindDeviceList {
    @Param devices: DeviceViewModel[] = [];
    @Param selectedIDs: number[] = [];
    @Param scroller: ListScroller = new ListScroller();
    @Event onToggle: (id: number) => void = (id: number) => {
    };

    build() {
        List({ scroller: this.scroller }) {
            ForEach(this.devices, (item: DeviceViewModel) => {
                ListItem() {
                    Row() {
                        Column() {
                            Text(item.Alias)
                                .fontWeight(FontWeight.Medium)
                                .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                                .fontColor(this.selectedIDs.includes(item.ID) ?
                                    $r('sys.color.interactive_active') : $r('sys.color.font_primary'))

                            Text(item.MAC)
                                .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                                .textOverflow({ overflow: TextOverflow.MARQUEE })
                                .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                                .fontColor(this.selectedIDs.includes(item.ID) ?
                                    $r('sys.color.interactive_active') : $r('sys.color.font_secondary'))

                            if (!isStringNullOrEmpty(item.Address)) {
                                Text(`${item.Address}:${item.Port}`)
                                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                                    .textOverflow({ overflow: TextOverflow.MARQUEE })
                                    .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                                    .fontColor(this.selectedIDs.includes(item.ID) ?
                                        $r('sys.color.interactive_active') : $r('sys.color.font_secondary'))
                            }
                        }
                        .width(StyleConstants.EIGHTY_PERCENT)
                        .alignItems(HorizontalAlign.Center)
                        .padding({
                            left: StyleConstants.PADDING_TWO,
                            right: StyleConstants.PADDING_TWO
                        })

                        Column() {
                            Checkbox()
                                .select(this.selectedIDs.includes(item.ID))
                                .hitTestBehavior(HitTestMode.None)
                        }
                        .width(StyleConstants.TWENTY_PERCENT)
                        .alignItems(HorizontalAlign.Center)
                    }
                    .height(StyleConstants.TEN_PERCENT)
                    .width(StyleConstants.FULL_PERCENT)
                    .borderStyle(BorderStyle.Solid)
                    .onClick(() => {
                        this.onToggle(item.ID);
                    })
                }
                .margin({
                    top: StyleConstants.FIVE_PERCENT,
                    left: StyleConstants.TWO_PERCENT,
                    right: StyleConstants.TWO_PERCENT,
                    bottom: StyleConstants.FIVE_PERCENT
                })
            }, (item: DeviceViewModel) => item.ID.toString())
        }
        .lanes(2)
        .alignListItem(ListItemAlign.Center)
        .padding(StyleConstants.PADDING_EIGHT)
        .layoutWeight(1)
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
    }
}