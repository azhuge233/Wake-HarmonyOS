import { common } from '@kit.AbilityKit';
import { formProvider } from '@kit.FormKit';
import { hdsMaterial, HdsNavigation, ScrollEffectType, HdsNavigationTitleMode } from '@kit.UIDesignKit';

import StyleConstants from '../common/constants/StyleConstants';
import Logger from '../common/utils/Logger';
import { PM } from '../common/utils/PM';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';
import SingleDeviceFormData from '../singledevicewidget/model/SingleDeviceFormData';
import CommonConstants from '../common/constants/CommonConstants';
import CommonUtils from '../common/utils/CommonUtils';
import Device from '../model/Device';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';

@Entry
@ComponentV2
struct SingleDeviceFormEdit {
    private LOG_TAG = "[pages/SingleDeviceFormEdit]";

    @Local listViewModel: DeviceListViewModel = new DeviceListViewModel();

    @Local isLoading: boolean = true;

    @Local isDBInitialized: boolean = true;

    @Local selectedID: number | null = null;
    @Local isUpdating: boolean = false;

    private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    private pm = PM.getInstance();

    private scrollerForList: ListScroller = new ListScroller();

    private formID: string = '';

    async onPageShow(): Promise<void> {
        await this.listViewModel.loadDevices();

        this.handleParamsFromForm();

        this.isLoading = false;
    }

    onPageHide(): void {
        CommonUtils.closeApplication(this.LOG_TAG, this.context);
    }

    private handleParamsFromForm(): void {
        if(AppStorage.has(CommonConstants.AppStorage_KEY_FormID)) {
            const formIDParam: string | undefined = AppStorage.get(CommonConstants.AppStorage_KEY_FormID);
            if(formIDParam) {
                this.formID = formIDParam as string;
                Logger.debug(this.LOG_TAG, `传入 formID: ${formIDParam}`);
                AppStorage.delete(CommonConstants.AppStorage_KEY_FormID);
            }
        }

        // if(AppStorage.has(CommonConstants.AppStorage_KEY_FormDimensions)) {
        //     const formDimensionsParam: number | undefined = AppStorage.get(CommonConstants.AppStorage_KEY_FormDimensions);
        //     if(formDimensionsParam) {
        //         this.formDimensions = formDimensionsParam as number;
        //         Logger.debug(this.LOG_TAG, `传入 formDimensions: ${formDimensionsParam}`);
        //         AppStorage.delete(CommonConstants.AppStorage_KEY_FormDimensions);
        //     }
        // }
    }

    private handleCheckboxChange(itemId: number, isChecked: boolean): void {
        if (isChecked) {
            // 选中当前条目，清空之前的选择
            this.selectedID = itemId;
        } else if (this.selectedID === itemId) {
            // 取消选中当前已选中的条目
            this.selectedID = null;
        }
    }

    private async handleConfirmClick(): Promise<void> {
        if (!this.selectedID || this.isUpdating || !this.formID) return;

        // 查找选中的条目
        const selectedItem = this.listViewModel.devices.find(
            (item: DeviceViewModel) => item.ID === this.selectedID
        );

        if (!selectedItem) {
            Logger.error(this.LOG_TAG, '未找到选中的条目');
            return;
        }

        try {
            this.isUpdating = true;

            const formData: SingleDeviceFormData = new SingleDeviceFormData(this.formID, true);

            formData.deviceID = selectedItem.ID;
            formData.alias = selectedItem.Alias;
            formData.mac = selectedItem.MAC;

            // 持久化存储卡片绑定信息
            await this.pm.bindSingle(this.formID, formData);

            // 创建表单绑定数据
            const formInfo = CommonUtils.createSingleDeviceFormBindingData(formData);
            // 更新卡片
            await formProvider.updateForm(this.formID as string, formInfo);

            Logger.debug(this.LOG_TAG, `卡片更新成功: formID: ${this.formID}, formInfo: ${JSON.stringify(formInfo)}`);

            // 更新成功后关闭页面
            CommonUtils.closeApplication(this.LOG_TAG, this.context);
        } catch (error) {
            Logger.error(this.LOG_TAG, `卡片更新失败: ${error}`);
        } finally {
            this.isUpdating = false;
        }
    }

    @Builder
    LoadingContent() {
        Column() {
            LoadingProgress()
                .width(StyleConstants.LOADING_WIDTH)
                .layoutWeight(1)
        }
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .alignItems(HorizontalAlign.Center)
    }

    @Builder
    NoDeviceNotice() {
        Column() {
            Text($r("app.string.no_device_message"))
                .fontSize(StyleConstants.TEXT_FONT_SIZE_EIGHTEEN)
                .fontColor(Color.Gray)
            Text($r("app.string.form_edit_create_new_device_message"))
                .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                .fontColor(Color.Gray)
                .margin({ top: StyleConstants.MARGIN_TEN })
        }
        .justifyContent(FlexAlign.Center)
        .layoutWeight(1)
        .width(StyleConstants.FULL_PERCENT)
    }

    @Builder
    ConfirmButton() {
        Row() {
            Button($r('app.string.button_confirm_label'), { type: ButtonType.Capsule })
                .width(StyleConstants.EIGHTY_PERCENT)
                .fontWeight(FontWeight.Medium)
                .enabled(this.selectedID !== null && !this.isUpdating)
                .onClick(async () => {
                    await this.handleConfirmClick();
                })
        }
        .width(StyleConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.Center)
        .padding({
            top: StyleConstants.PADDING_SIXTEEN,
            bottom: StyleConstants.PADDING_SIXTEEN
        })
    }

    @Builder
    MainContent() {
        if(this.listViewModel.devices.length === 0) this.NoDeviceNotice();
        else {
            Column() {
                List({ scroller: this.scrollerForList }) {
                    ForEach(this.listViewModel.devices, (item: Device) => {
                        ListItem() {
                            Row() {
                                Column() {
                                    Text(item.Alias)
                                        .fontWeight(FontWeight.Medium)
                                        .maxLines(1)
                                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                                        .fontColor(this.selectedID === item.ID ?
                                            $r('sys.color.interactive_active') : $r('sys.color.font_primary'))

                                    Text(item.MAC)
                                        .maxLines(1)
                                        .textOverflow({ overflow: TextOverflow.MARQUEE })
                                        .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                                        .fontColor(this.selectedID === item.ID ?
                                            $r('sys.color.interactive_active') : $r('sys.color.font_secondary'))
                                }
                                .width(StyleConstants.EIGHTY_PERCENT)
                                .alignItems(HorizontalAlign.Center)
                                .padding({
                                    left: StyleConstants.PADDING_TWO,
                                    right: StyleConstants.PADDING_TWO
                                })

                                Column() {
                                    Checkbox()
                                        .select(this.selectedID === item.ID)
                                        .onChange((isChecked: boolean) => {
                                            this.handleCheckboxChange(item.ID, isChecked);
                                        })

                                }
                                .width(StyleConstants.TWENTY_PERCENT)
                                .alignItems(HorizontalAlign.Center)
                            }
                            .height(StyleConstants.TEN_PERCENT)
                            .width(StyleConstants.FULL_PERCENT)
                            .borderStyle(BorderStyle.Solid)
                        }
                        .margin({
                            top: StyleConstants.FIVE_PERCENT,
                            left: StyleConstants.TWO_PERCENT,
                            right: StyleConstants.TWO_PERCENT,
                            bottom: StyleConstants.FIVE_PERCENT
                        })
                    })
                }
                .lanes(2)
                .alignListItem(ListItemAlign.Center)
                .padding(StyleConstants.PADDING_EIGHT)
                .layoutWeight(1)
                .height(StyleConstants.FULL_PERCENT)
                .width(StyleConstants.FULL_PERCENT)

                this.ConfirmButton();
            }
            .height(StyleConstants.FULL_PERCENT)
            .width(StyleConstants.FULL_PERCENT)
        }
    }

    build() {
        HdsNavigation() {
            if(this.isLoading) this.LoadingContent();
            else this.MainContent();
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r('app.string.form_edit_title')
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
        .titleMode(HdsNavigationTitleMode.MINI)
        .bindToScrollable([this.scrollerForList])
        .hideBackButton(false)
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, 'Loaded!');
        })
    }
}