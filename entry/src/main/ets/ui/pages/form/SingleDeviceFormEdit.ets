import { common } from '@kit.AbilityKit';
import { hdsMaterial, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit';

import { CommonConstants } from '../../../common/constants/CommonConstants';
import { StyleConstants } from '../../../common/constants/StyleConstants';
import { Logger } from '../../../common/log/Logger';
import { CardBindingService } from '../../../domain/CardBindingService';
import { DeviceService } from '../../../domain/DeviceService';
import { SingleCardBindViewModel } from '../../../viewmodel/SingleCardBindViewModel';
import { AppEmptyState } from '../../component/AppEmptyState';
import { BindConfirmBar } from '../../component/BindConfirmBar';
import { BindDeviceList } from '../../component/BindDeviceList';
import { showToast } from '../../feedback/Feedback';
import { closeApplication } from '../../util/AppExit';

/**
 * 单设备卡片绑定页。根容器是 HdsNavigation，不是 HdsNavDestination，
 * 因此不进 PageScaffold：只共享内容区的设备网格与确认栏。
 */
@Entry
@ComponentV2
struct SingleDeviceFormEdit {
    private LOG_TAG = '[ui/pages/form/SingleDeviceFormEdit]';

    @Local isLoading: boolean = true;

    private viewModel: SingleCardBindViewModel = new SingleCardBindViewModel(DeviceService.instance(),
        CardBindingService.instance());

    private context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    private promptAction = this.getUIContext().getPromptAction();

    private scrollerForList: ListScroller = new ListScroller();

    async onPageShow(): Promise<void> {
        await this.viewModel.load();
        this.handleParamsFromForm();
        this.isLoading = false;
    }

    onPageHide(): void {
        closeApplication(this.LOG_TAG, this.context);
    }

    /** 窗口参数：每 Ability 实例一份 LocalStorage，键名集中在 CommonConstants */
    private handleParamsFromForm(): void {
        const formID: string | undefined =
            this.getUIContext().getSharedLocalStorage()?.get<string>(CommonConstants.WINDOW_PARAM_FORM_ID);
        if (formID === undefined || formID === '') {
            Logger.warn(this.LOG_TAG, '没有从窗口参数取到 formID');
            return;
        }

        this.viewModel.setFormID(formID);
        Logger.debug(this.LOG_TAG, `传入 formID: ${formID}`);
    }

    private async handleConfirmClick(): Promise<void> {
        const ok = await this.viewModel.confirm();

        if (!ok) {
            if (this.viewModel.bindError !== '') showToast(this.promptAction, $r('app.string.card_bind_failed'));
            return;
        }

        // 写成功但发布失败：给一次提示，页面照常关闭
        if (this.viewModel.bindError !== '') showToast(this.promptAction, $r('app.string.card_refresh_failed'));

        closeApplication(this.LOG_TAG, this.context);
    }

    @Builder
    LoadingContent() {
        Column() {
            LoadingProgress()
                .width(StyleConstants.LOADING_WIDTH)
                .layoutWeight(1)
        }
        .height('100%')
        .width('100%')
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    NoDeviceNotice() {
        AppEmptyState({
            text: $r('app.string.no_device_message'),
            hint: $r('app.string.form_edit_create_new_device_message')
        })
    }

    @Builder
    MainContent() {
        Column() {
            BindDeviceList({
                devices: this.viewModel.devices,
                selectedIDs: this.viewModel.selectedID === null ? [] : [this.viewModel.selectedID],
                scroller: this.scrollerForList,
                onToggle: (id: number) => {
                    this.viewModel.toggle(id);
                }
            })

            BindConfirmBar({
                label: $r('app.string.button_confirm_label'),
                isEnabled: this.viewModel.selectedID !== null && !this.viewModel.isUpdating,
                onConfirm: () => {
                    this.handleConfirmClick().catch((err: Error) => {
                        Logger.error(this.LOG_TAG, `绑定卡片失败, ${err}`);
                    });
                }
            })
        }
        .height('100%')
        .width('100%')
    }

    build() {
        HdsNavigation() {
            if (this.isLoading) {
                this.LoadingContent();
            } else if (this.viewModel.devices.length === 0) {
                this.NoDeviceNotice();
            } else {
                this.MainContent();
            }
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r('app.string.form_edit_title')
                }
            },
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR
                },
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                }
            },
            enableComponentSafeArea: true
        })
        .titleMode(HdsNavigationTitleMode.MINI)
        .bindToScrollable([this.scrollerForList])
        .hideBackButton(false)
        .height('100%')
        .width('100%')
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, 'Loaded!');
        })
    }
}