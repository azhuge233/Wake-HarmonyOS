import { StyleConstants } from '../../common/constants/StyleConstants';
import { NeighborCandidate } from '../../domain/NeighborService';

/** 邻居表条目：IP / MAC / 接口 + 添加按钮 */
@ComponentV2
export struct NeighTableDeviceTile {
    @Param entry: NeighborCandidate = { ip: '', mac: '', iface: '' };
    @Event onAdd: () => void = () => {
    };

    build() {
        Row() {
            Column() {
                Text(this.entry.ip)
                    .fontColor($r('sys.color.font_primary'))
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({
                        overflow: TextOverflow.MARQUEE
                    })

                Text(this.entry.mac)
                    .fontColor($r('sys.color.font_secondary'))
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({
                        overflow: TextOverflow.MARQUEE
                    })

                Text($r('app.string.neigh_table_device_tile_interface_label', this.entry.iface))
                    .fontColor($r('sys.color.font_tertiary'))
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_THIRTEEN)
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({
                        overflow: TextOverflow.MARQUEE
                    })
            }
            .width(StyleConstants.SEVENTY_TWO_PERCENT)
            .alignItems(HorizontalAlign.Center)
            .padding({
                left: StyleConstants.PADDING_TWO,
                right: StyleConstants.PADDING_TWO
            })

            Column() {
                Button($r('app.string.button_add_machine_confirm'))
                    .onClick(() => this.onAdd());
            }
            .width(StyleConstants.TWENTY_TWO_PERCENT)
            .alignItems(HorizontalAlign.Center)
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.DEVICE_TILE_HEIGHT)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
        // 卡面四件套与设备条目同一组常量：两处条目同形，取值只有一处来源
        .backgroundColor($r('sys.color.comp_background_primary'))
        .border({
            width: StyleConstants.CARD_BORDER_WIDTH,
            color: $r('sys.color.comp_divider')
        })
        .borderRadius(StyleConstants.CARD_RADIUS)
        .clip(true)
    }
}