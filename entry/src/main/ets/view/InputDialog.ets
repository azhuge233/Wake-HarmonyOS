import { hdsMaterial, HdsNavDestination, ScrollEffectType } from "@kit.UIDesignKit";

import CommonConstants from "../common/constants/CommonConstants";
import StyleConstants from "../common/constants/StyleConstants";
import CommonUtils from "../common/utils/CommonUtils";
import TextItem, { INPUT_TYPE } from '../view/TextItem';

@ObservedV2
export class DialogData {
    @Trace deviceAlias: string = "";
    @Trace ignoreIP: boolean = true;
}

@Builder
export function InputDialogBuilder() {
    InputDialog();
}

@ComponentV2
export struct InputDialog {
    pathStack: NavPathStack = new NavPathStack();

    @Local data: DialogData = new DialogData();

    @Builder
    MainContent() {
        Column() {
            Text($r("app.string.add_neigh_table_device_dialog_title"))
                .fontWeight(FontWeight.Bold)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_TWENTY_TWO)
                .margin({
                    top: StyleConstants.MARGIN_FIVE_PERCENT,
                    bottom: StyleConstants.MARGIN_TEN_PERCENT
                })

            TextItem({
                inputType: INPUT_TYPE.ALIAS,
                inputId: CommonConstants.ALIAS_INPUT_ID,
                isDefaultFocus: false,
                textResource: $r("app.string.add_alias_input_label"),
                placeholderResource: $r("app.string.add_alias_input_placeholder"),
                text: this.data.deviceAlias,
                onInputChange: (value: string | number) => { this.data.deviceAlias = String(value) }
            })
                .width(StyleConstants.EIGHTY_PERCENT)
                .margin({
                    bottom: StyleConstants.MARGIN_TWO_PERCENT
                })

            Row() {
                Toggle({ type: ToggleType.Checkbox, isOn: this.data.ignoreIP })
                    .onChange(
                        (value: boolean) => {
                            this.data.ignoreIP = value;
                        }
                    )

                Column() {
                    Text($r("app.string.add_neigh_table_device_dialog_ignore_ip"))

                    Text($r("app.string.add_neigh_table_device_dialog_ignore_ip_desc"))
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_THIRTEEN)
                        .fontColor($r("sys.color.font_secondary"))
                }
                .width(StyleConstants.EIGHTY_FIVE_PERCENT)
                .alignItems(HorizontalAlign.Start)
                .padding({
                    left: StyleConstants.PADDING_FIFTEEN
                })
            }
            .width(StyleConstants.EIGHTY_PERCENT)
            .padding({
                left: StyleConstants.PADDING_EIGHT,
                right: StyleConstants.PADDING_TWO
            })

            Button($r("app.string.button_confirm_label"))
                .enabled(!CommonUtils.isStringNullOrEmpty(this.data.deviceAlias.trim()))
                .width(StyleConstants.SEVENTY_PERCENT)
                .margin({
                    top: StyleConstants.MARGIN_EIGHT_PERCENT
                })
                .onClick(() => {
                    this.pathStack.pop(this.data);
                })
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
    }

    build() {
        HdsNavDestination() {
            this.MainContent();
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r("app.string.app_shortcut_label_add_device")
                }
            },
            style: {
                scrollEffectOpts: { // 设置滚动特效
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                },
                systemMaterialEffect: { // 设置沉浸光感
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                },
            },
            enableComponentSafeArea: true // 启用标题栏占位
        })
        .mode(NavDestinationMode.DIALOG)
        .backgroundColor($r("sys.color.background_primary"))
        .onBackPressed(() => {
            this.pathStack.pop("");
            return true;
        })
        .onReady((context) => {
            this.pathStack = context.pathStack;
        });
    }
}