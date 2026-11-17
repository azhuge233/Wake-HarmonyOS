import { UIContext } from '@kit.ArkUI';

import { CommonConstants } from '../../common/constants/CommonConstants';
import { Logger } from '../../common/log/Logger';
import { isStringNullOrEmpty } from '../../common/util/Strings';
import { CardBindingService } from '../../domain/CardBindingService';
import { DeviceService } from '../../domain/DeviceService';
import { DraftIssue } from '../../viewmodel/DeviceAddViewModel';
import { DeviceEditViewModel } from '../../viewmodel/DeviceEditViewModel';
import { DeviceViewModel } from '../../viewmodel/DeviceViewModel';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import TextItem, { INPUT_TYPE } from '../component/TextItem';
import { showToast } from '../feedback/Feedback';

@Builder
export function EditBuilder() {
    Edit();
}

@ComponentV2
struct Edit {
    private LOG_TAG = '[ui/pages/Edit]';

    @Local showAdvanced: boolean = false;

    private viewModel: DeviceEditViewModel = new DeviceEditViewModel(DeviceService.instance(),
        CardBindingService.instance());

    private uiContext: UIContext = this.getUIContext();
    private promptAction = this.uiContext.getPromptAction();
    private focusController = this.uiContext.getFocusController();

    pathStack: NavPathStack | undefined = undefined;

    /** 校验结果 → 提示文案；'none' 不该走到这里 */
    private issueText(issue: DraftIssue): Resource {
        if (issue === 'empty') return $r('app.string.input_cannot_be_null_or_empty');
        if (issue === 'port') return $r('app.string.port_invalid');
        if (issue === 'mac-short') return $r('app.string.validate_mac_too_short');
        if (issue === 'mac-format') return $r('app.string.validate_mac_regex_fail');
        return $r('app.string.input_cannot_be_null_or_empty');
    }

    private focusForIssue(issue: DraftIssue): void {
        try {
            if (issue === 'empty') {
                if (isStringNullOrEmpty(this.viewModel.draft.MAC.trim())) {
                    this.focusController.requestFocus(CommonConstants.MAC_INPUT_ID);
                } else {
                    this.focusController.requestFocus(CommonConstants.ALIAS_INPUT_ID);
                }
            } else if (issue === 'port') {
                this.focusController.requestFocus(CommonConstants.PORT_INPUT_ID);
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `移动输入焦点失败, ${err}`);
        }
    }

    async updateDevice(): Promise<void> {
        const issue: DraftIssue = this.viewModel.validate();
        if (issue !== 'none') {
            showToast(this.promptAction, this.issueText(issue));
            this.focusForIssue(issue);
            return;
        }

        const saved = await this.viewModel.save();
        if (!saved) {
            // 走到这里只有更新失败：校验与端口在 save() 的前段就返回 false，卡片发布在更新成功之后才发生
            showToast(this.promptAction, $r('app.string.update_machine_failed', this.viewModel.draft.Alias));
            return;
        }

        // 保存已成功，卡片刷新失败另作一次提示：先报更新成功，再让卡片失败停在最后一句上
        showToast(this.promptAction, $r('app.string.update_machine_success', this.viewModel.draft.Alias));
        const refreshError = this.viewModel.consumeCardRefreshError();
        if (refreshError !== '') showToast(this.promptAction, $r('app.string.card_refresh_failed'));
        this.pathStack?.pop('Button pressed');
    }

    @Builder
    PageContent() {
        Scroll() {
            Column() {
                Blank()
                    .layoutWeight(1)

                TextItem({
                    inputType: INPUT_TYPE.MAC,
                    inputId: CommonConstants.MAC_INPUT_ID,
                    isDefaultFocus: true,
                    label: $r('app.string.add_mac_input_label'),
                    placeholder: $r('app.string.add_mac_input_placeholder'),
                    value: this.viewModel.draft.MAC,
                    onValueChange: (value: string) => {
                        this.viewModel.draft.MAC = value;
                    }
                })
                    .width('80%')

                TextItem({
                    inputType: INPUT_TYPE.ALIAS,
                    inputId: CommonConstants.ALIAS_INPUT_ID,
                    label: $r('app.string.add_alias_input_label'),
                    placeholder: $r('app.string.add_alias_input_placeholder'),
                    value: this.viewModel.draft.Alias,
                    onValueChange: (value: string) => {
                        this.viewModel.draft.Alias = value;
                    }
                })
                    .width('80%')

                Column() {
                    Stack() {
                        Divider()
                            .strokeWidth(2)
                            .width('80%')
                            .color($r('sys.color.background_emphasize'))

                        Row() {
                            Text($r('app.string.divider_label'))
                                .fontColor($r('sys.color.font_emphasize'))
                                .fontSize(12)
                                .margin({
                                    right: '1%'
                                })

                            SymbolGlyph($r('sys.symbol.chevron_up'))
                                .width(15)
                                .height(15)
                                .fontColor([$r('sys.color.font_emphasize')])
                                .margin({
                                    left: '1%'
                                })
                                .rotate({
                                    angle: this.showAdvanced ? 0 : 180
                                })
                        }
                        .width('20%')
                        .justifyContent(FlexAlign.Center)
                        .alignItems(VerticalAlign.Center)
                        .backgroundColor($r('sys.color.background_primary'))
                        .margin({
                            left: '1%'
                        })
                        .onClick(() => {
                            this.showAdvanced = !this.showAdvanced;
                        })
                    }
                    .alignContent(Alignment.Start)
                    .margin({
                        top: '2%'
                    })

                    if (this.showAdvanced) {
                        TextItem({
                            inputType: INPUT_TYPE.ADDRESS,
                            inputId: CommonConstants.ADDRESS_INPUT_ID,
                            label: $r('app.string.add_address_input_label'),
                            placeholder: $r('app.string.add_address_input_placeholder'),
                            value: this.viewModel.draft.Address,
                            onValueChange: (value: string) => {
                                this.viewModel.draft.Address = value;
                            }
                        })
                            .width('80%')

                        TextItem({
                            inputType: INPUT_TYPE.PORT,
                            inputId: CommonConstants.PORT_INPUT_ID,
                            label: $r('app.string.add_port_input_label'),
                            placeholder: $r('app.string.add_port_input_placeholder'),
                            value: this.viewModel.portText,
                            onValueChange: (value: string) => {
                                this.viewModel.portText = value;
                            }
                        })
                            .width('80%')
                    }
                }
                .alignItems(HorizontalAlign.Center)

                Button($r('app.string.button_edit_confirm'))
                    .enabled(!isStringNullOrEmpty(this.viewModel.draft.MAC.trim()) &&
                        !isStringNullOrEmpty(this.viewModel.draft.Alias.trim()))
                    .width('70%')
                    .margin({
                        top: '10%'
                    })
                    .onClick(async () => {
                        await this.updateDevice();
                    })

                Blank()
                    .layoutWeight(1)
            }
        }
        .width('100%')
    }

    @Builder
    PageOverlay() {
    }

    build() {
        PageScaffold({
            title: $r('app.string.edit_title'),
            logTag: this.LOG_TAG,
            scrollable: true,
            centered: true,
            content: (): void => {
                this.PageContent();
            },
            overlayContent: (): void => {
                this.PageOverlay();
            },
            onReady: (ctx: PageReadyContext) => {
                const params = ctx.param as Array<object> | undefined;
                const passedStack: NavPathStack | undefined = params !== undefined && params.length > 2 ?
                    params[2] as NavPathStack : undefined;
                this.pathStack = passedStack ?? ctx.pathStack;
                if (params !== undefined && params.length > 1) {
                    const source = params[1] as DeviceViewModel;
                    this.viewModel.loadFrom(source);
                }
            },
            onBack: () => {
                this.pathStack?.pop('Back pressed');
                return true;
            }
        })
    }
}