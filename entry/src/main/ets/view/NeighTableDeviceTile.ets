import { StyleConstants } from "../common/constants/StyleConstants";

@ComponentV2
export default struct NeighTableDeviceTile {
    private LOG_TAG = "[view/NeighTableDeviceTile]";

    @Param deviceMAC: string = '';
    @Param deviceAddress: string = '';
    @Param deviceInterface: string = '';
    @Event addDevice: () => void = () => {};

    build() {
        Row() {
            Column() {
                Text(this.deviceAddress)
                    .fontColor($r("sys.color.font_primary"))
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({
                        overflow: TextOverflow.MARQUEE
                    })

                Text(this.deviceMAC)
                    .fontColor($r("sys.color.font_secondary"))
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({
                        overflow: TextOverflow.MARQUEE
                    })

                Text($r("app.string.neigh_table_device_tile_interface_label", this.deviceInterface))
                    .fontColor($r("sys.color.font_tertiary"))
                    .fontSize(StyleConstants.TEXT_FONT_SIZE_THIRTEEN)
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({
                        overflow: TextOverflow.MARQUEE
                    })
            }
            .width(StyleConstants.SIXTY_FIVE_PERCENT)
            .alignItems(HorizontalAlign.Center)
            .padding({
                left: StyleConstants.PADDING_TWO,
                right: StyleConstants.PADDING_TWO
            })

            Column() {
                Button($r("app.string.button_add_machine_confirm"))
                    .onClick(() => this.addDevice());
            }
            .width(StyleConstants.TWENTY_PERCENT)
            .alignItems(HorizontalAlign.Center)
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.DEVICE_TILE_HEIGHT)
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.Center)
    }
}