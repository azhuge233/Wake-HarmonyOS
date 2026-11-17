import {
    hdsMaterial,
    HdsNavDestination,
    HdsNavigationTitleBarOptions,
    ScrollEffectType,
    TitleBarContentOptions,
    TitleBarStyleOptions
} from '@kit.UIDesignKit';

import { CommonConstants } from '../../common/constants/CommonConstants';
import { StyleConstants } from '../../common/constants/StyleConstants';
import { isStringNullOrEmpty } from '../../common/util/Strings';
import { AppButton } from '../component/AppButton';
import { AppInput } from '../component/AppInput';

/** 弹窗交回的结果：别名 + 是否忽略 IP */
@ObservedV2
export class DialogData {
    @Trace deviceAlias: string = '';
    @Trace ignoreIP: boolean = true;
}

@Builder
export function InputDialogBuilder() {
    InputDialog();
}

/**
 * 单输入弹窗：标题、初值、确认回调由路由参数与调用方给出，没有业务状态，因此没有 ViewModel。
 * 保留自己的 .titleBar 与 .onBackPressed：抽出的弹窗外壳没有第二个消费方，套进 PageScaffold 会多一层导航壳。
 */
@ComponentV2
export struct InputDialog {
    pathStack: NavPathStack = new NavPathStack();

    @Local data: DialogData = new DialogData();

    private titleBarOptions(): HdsNavigationTitleBarOptions {
        const content: TitleBarContentOptions = { title: { mainTitle: $r('app.string.add_neigh_table_device_dialog_title') } };
        const style: TitleBarStyleOptions = {
            scrollEffectOpts: {
                enableScrollEffect: true,
                scrollEffectType: ScrollEffectType.GRADIENT_BLUR
            },
            systemMaterialEffect: {
                materialType: hdsMaterial.MaterialType.ADAPTIVE,
                materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
            }
        };
        const options: HdsNavigationTitleBarOptions = {
            content: content,
            style: style,
            enableComponentSafeArea: true
        };
        return options;
    }

    @Builder
    MainContent() {
        Column() {
            Text($r('app.string.add_neigh_table_device_dialog_title'))
                .fontWeight(FontWeight.Bold)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_TWENTY_TWO)
                .margin({
                    top: '5%',
                    bottom: '10%'
                })

            Row() {
                Text($r('app.string.add_alias_input_label'))
                    .alignSelf(ItemAlign.Center)
                    .margin({
                        right: StyleConstants.MARGIN_FIVE
                    })

                AppInput({
                    value: this.data.deviceAlias,
                    maxLength: StyleConstants.TEXT_INPUT_ALIAS_MAX_LENGTH,
                    placeholder: $r('app.string.add_alias_input_placeholder'),
                    inputId: CommonConstants.ALIAS_INPUT_ID,
                    onValueChange: (value: string) => {
                        this.data.deviceAlias = value;
                    }
                })
                    .width('80%')
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .justifyContent(FlexAlign.SpaceEvenly)
            .margin({
                bottom: '2%'
            })

            Row() {
                Toggle({ type: ToggleType.Checkbox, isOn: this.data.ignoreIP })
                    .onChange((value: boolean) => {
                        this.data.ignoreIP = value;
                    })

                Column() {
                    Text($r('app.string.add_neigh_table_device_dialog_ignore_ip'))

                    Text($r('app.string.add_neigh_table_device_dialog_ignore_ip_desc'))
                        .fontSize(StyleConstants.TEXT_FONT_SIZE_THIRTEEN)
                        .fontColor($r('sys.color.font_secondary'))
                }
                .width('85%')
                .alignItems(HorizontalAlign.Start)
                .padding({
                    left: StyleConstants.PADDING_FIFTEEN
                })
            }
            .width('80%')
            .padding({
                left: StyleConstants.PADDING_EIGHT,
                right: StyleConstants.PADDING_TWO
            })

            AppButton({
                label: $r('app.string.button_confirm_label'),
                isEnabled: !isStringNullOrEmpty(this.data.deviceAlias.trim()),
                onTap: () => {
                    this.pathStack.pop({
                        deviceAlias: this.data.deviceAlias,
                        ignoreIP: this.data.ignoreIP
                    });
                }
            })
                .width('70%')
                .margin({
                    top: '8%'
                })
        }
        .width('100%')
        .height('100%')
    }

    build() {
        HdsNavDestination() {
            this.MainContent();
        }
        .titleBar(this.titleBarOptions())
        .mode(NavDestinationMode.DIALOG)
        .backgroundColor($r('sys.color.background_primary'))
        .onBackPressed(() => {
            this.pathStack.pop();
            return true;
        })
        .onReady((context: NavDestinationContext) => {
            const passedStack: NavPathStack | undefined = context.pathInfo.param as NavPathStack | undefined;
            this.pathStack = passedStack ?? context.pathStack;
        })
    }
}