import { common } from '@kit.AbilityKit';
import { formProvider } from '@kit.FormKit';

import StyleConstants from '../common/constants/StyleConstants';
import Logger from '../common/utils/Logger';
import { PM } from '../common/utils/PM';
import DeviceListViewModel from '../viewmodel/DeviceListViewModel';
import CommonConstants from '../common/constants/CommonConstants';
import CommonUtils from '../common/utils/CommonUtils';
import Device from '../model/Device';
import { DeviceViewModel } from '../viewmodel/DeviceViewModel';
import MultipleDevicesFormData from '../multipledeviceswidget/model/MultipleDevicesFormData';
import WidgetDevice from '../multipledeviceswidget/model/WidgetDevice';

@Entry
@ComponentV2
struct MultipleDevicesFormEdit {
    private LOG_TAG = "[pages/MultipleDevicesFormEdit]";

    @Local listViewModel: DeviceListViewModel = new DeviceListViewModel();

    @Local isLoading: boolean = true;

    @Local isDBInitialized: boolean = true;

    @Local selectedIDs: Array<number> = [];
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
    }

    private handleCheckboxChange(itemId: number, isChecked: boolean): void {
        if (isChecked) {
            // 选中当前条目，添加到数组
            if(!this.selectedIDs.includes(itemId)) this.selectedIDs.push(itemId);
        } else {
            // 取消选中，从数组中移除
            const index = this.selectedIDs.indexOf(itemId);
            if (index >= 0) this.selectedIDs.splice(index, 1);
        }
    }

    private async handleConfirmClick(): Promise<void> {
        if (this.selectedIDs.length === 0 || this.isUpdating || !this.formID) return;

        // 查找选中的条目
        const selectedItems = this.listViewModel.devices.filter(
            (item: DeviceViewModel) => this.selectedIDs.includes(item.ID)
        );

        if (!selectedItems) {
            Logger.error(this.LOG_TAG, '未找到选中的条目');
            return;
        }

        try {
            this.isUpdating = true;

            const formData: MultipleDevicesFormData = new MultipleDevicesFormData(this.formID, true);

            formData.deviceList =selectedItems.map(item => new WidgetDevice(item.ID, item.Alias, item.MAC))

            // 持久化存储卡片绑定信息
            await this.pm.bindMultiple(this.formID, formData);

            // 创建表单绑定数据
            const formInfo = CommonUtils.createMultipleDevicesFormBindingData(formData);
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
                .enabled(this.selectedIDs.length !== 0 && !this.isUpdating)
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
                                        .fontColor(this.selectedIDs.includes(item.ID) ?
                                            $r('sys.color.interactive_active') : $r('sys.color.font_primary'))

                                    Text(item.MAC)
                                        .maxLines(1)
                                        .textOverflow({ overflow: TextOverflow.MARQUEE })
                                        .fontSize(StyleConstants.TEXT_FONT_SIZE_FOURTEEN)
                                        .fontColor(this.selectedIDs.includes(item.ID) ?
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
                                        .select(this.selectedIDs.includes(item.ID))
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
        Navigation() {
            if(this.isLoading) this.LoadingContent();
            else this.MainContent();
        }
        .title($r('app.string.form_edit_title'))
        .titleMode(NavigationTitleMode.Mini)
        .hideBackButton(false)
        .height(StyleConstants.FULL_PERCENT)
        .width(StyleConstants.FULL_PERCENT)
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, 'Loaded!');
        })
    }
}