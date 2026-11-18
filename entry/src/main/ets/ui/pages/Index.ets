import { common } from '@kit.AbilityKit';
import {
    hdsMaterial,
    HdsNavigation,
    HdsNavigationMenuContentOptions,
    HdsTabs,
    HdsTabsController,
    ScrollEffectType
} from '@kit.UIDesignKit';

import { CommonConstants } from '../../common/constants/CommonConstants';
import { StyleConstants } from '../../common/constants/StyleConstants';
import { Logger } from '../../common/log/Logger';
import { CardBindingService } from '../../domain/CardBindingService';
import { DeviceService } from '../../domain/DeviceService';
import { WakeResult, WakeService } from '../../domain/WakeService';
import { DeviceListViewModel } from '../../viewmodel/DeviceListViewModel';
import { DeviceViewModel } from '../../viewmodel/DeviceViewModel';
import { AppButton } from '../component/AppButton';
import { AppEmptyState } from '../component/AppEmptyState';
import { DeviceTile } from '../component/DeviceTile';
import { LoadingOverlay } from '../component/LoadingOverlay';
import { showToast, vibrate } from '../feedback/Feedback';
import { logPopResult } from '../util/PageResult';
import { resourceText } from '../util/ResourceText';

@Entry
@ComponentV2
struct Index {
    private LOG_TAG = '[ui/pages/Index]';

    @Local deviceList: DeviceListViewModel = new DeviceListViewModel(DeviceService.instance(),
        CardBindingService.instance(), WakeService.instance());
    @Local ipBannerText: string = '';

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    private promptAction = this.uiContext.getPromptAction();

    private scrollerForList: ListScroller = new ListScroller();
    private tabController: HdsTabsController = new HdsTabsController();

    private menus: HdsNavigationMenuContentOptions = {
        value: [
            {
                content: {
                    label: $r('app.string.navigation_menu_refresh'),
                    icon: $r('sys.symbol.arrow_clockwise'),
                    action: async () => {
                        await this.refreshIPBanner();
                        showToast(this.promptAction, $r('app.string.network_refreshed'));
                    }
                }
            },
            {
                content: {
                    label: $r('app.string.navigation_menu_settings'),
                    icon: $r('sys.symbol.gearshape'),
                    action: () => {
                        this.safeCloseSwipeActions();
                        this.openPage('More', true);
                    }
                }
            }
        ]
    };

    pageStack: NavPathStack = new NavPathStack();

    aboutToAppear(): void {
        // 网络监听在数据层，页面只收回调并重取广播地址
        this.deviceList.watchNetwork(() => {
            this.refreshIPBanner();
        });
    }

    aboutToDisappear(): void {
        this.deviceList.unwatchNetwork();
    }

    async onPageShow(): Promise<void> {
        await this.refreshIPBanner();
        await this.loadDevices();
        await this.consumeShortcutPath();
    }

    async onPageHide(): Promise<void> {
        this.safeCloseSwipeActions();
        await this.deviceList.releaseSender();
    }

    /** 快捷方式：只写不重载，Index 在 onPageShow 取用后删键 */
    private async consumeShortcutPath(): Promise<void> {
        const storage: LocalStorage | undefined = this.getUIContext().getSharedLocalStorage();
        if (storage === undefined) return;

        const path: string | undefined = storage.get<string>(CommonConstants.WINDOW_PARAM_SHORTCUT_PATH);
        if (path === undefined || path === '') return;

        Logger.debug(this.LOG_TAG, `检测到长按快捷方式页面: ${path}`);
        await this.goToSpecifyPage(path);
        storage.delete(CommonConstants.WINDOW_PARAM_SHORTCUT_PATH);
    }

    private async refreshIPBanner(): Promise<void> {
        await this.deviceList.refreshBroadcast();
        this.ipBannerText =
            `${resourceText($r('app.string.current_broadcast_ip'), this.context)}${this.deviceList.broadcastAddress}`;
    }

    private async loadDevices(): Promise<void> {
        await this.deviceList.load();
        this.consumeCardRefresh();
    }

    /** 卡片刷新失败：一次提示，正常路径不受影响 */
    private consumeCardRefresh(): void {
        const message: string = this.deviceList.consumeCardRefreshError();
        if (message !== '') showToast(this.promptAction, $r('app.string.card_refresh_failed'));
    }

    private safeCloseSwipeActions(): void {
        try {
            if (this.deviceList.devices.length > 0) this.scrollerForList.closeAllSwipeActions();
        } catch (err) {
            Logger.debug(this.LOG_TAG, `关闭左滑菜单失败, ${err}`);
        }
    }

    /**
     * 子页返回的统一处理：按入口声明重载设备列表 → 刷广播地址 → 记 pop 结果。
     * 列表重载先做：子页改的是库，读回列表才能拿到结果；广播地址不受子页影响。
     */
    private async handleChildPop(popInfo: PopInfo, reloadDevices: boolean): Promise<void> {
        if (reloadDevices) await this.loadDevices();
        await this.refreshIPBanner();
        logPopResult(this.LOG_TAG, popInfo);
    }

    /** reloadOnPop 必填、不设默认值：新页面必须自己声明返回时是否重载 */
    private openPage(name: string, reloadOnPop: boolean): void {
        this.pageStack.pushPath({
            name: name,
            param: this.pageStack,
            onPop: async (popInfo: PopInfo) => {
                await this.handleChildPop(popInfo, reloadOnPop);
            }
        });
    }

    /** 快捷方式入口：当前只有 AddDevice（shortcuts_config.json 的 shortCutKey），返回要重载列表 */
    private async goToSpecifyPage(path: string): Promise<void> {
        if (this.pageStack.size() > 0) this.pageStack.clear();

        try {
            Logger.debug(this.LOG_TAG, `跳转至页面 ${path}`);
            this.pageStack.pushPath({
                name: path,
                param: this.pageStack,
                onPop: async (popInfo: PopInfo) => {
                    await this.handleChildPop(popInfo, true);
                }
            });
        } catch (err) {
            Logger.error(this.LOG_TAG, `${path} 页面跳转失败, ${err}`);
        }
    }

    /** 唤醒结果按 kind 取文案：文案不进领域层 */
    private async wakeDevice(device: DeviceViewModel): Promise<void> {
        const result: WakeResult = await this.deviceList.wake(device);

        if (result.ok) {
            showToast(this.promptAction, $r('app.string.send_magic_packet_success'));
        } else if (result.kind === 'no-broadcast') {
            showToast(this.promptAction, $r('app.string.no_broadcast_ip'));
        } else {
            showToast(this.promptAction, $r('app.string.send_magic_packet_failed', result.detail));
        }
    }

    private async deleteDevice(device: DeviceViewModel): Promise<void> {
        try {
            const result = await this.promptAction.showDialog({
                title: $r('app.string.deletion_dialog_title'),
                message: $r('app.string.deletion_dialog_message', device.Alias),
                buttons: [
                    {
                        text: $r('app.string.deletion_dialog_confirm'),
                        color: $r('sys.color.warning')
                    },
                    {
                        text: $r('app.string.deletion_dialog_cancel'),
                        color: $r('sys.color.font_primary')
                    }
                ]
            });

            if (result.index !== 0) {
                Logger.warn(this.LOG_TAG, '取消删除');
                return;
            }

            const removed = await this.deviceList.remove(device);
            if (!removed) {
                showToast(this.promptAction, $r('app.string.clear_failed'));
                return;
            }
            this.consumeCardRefresh();
        } catch (err) {
            Logger.error(this.LOG_TAG, `删除设备失败, ${err}`);
        }
    }

    @Builder
    DeleteButton(device: DeviceViewModel) {
        Row() {
            Button() {
                SymbolGlyph($r('sys.symbol.trash'))
                    .fontSize(StyleConstants.ICON_WIDTH)
                    .fontColor([$r('sys.color.font_primary')])
            }
            .backgroundColor($r('sys.color.warning'))
            .type(ButtonType.Circle)
            .accessibilityText($r('app.string.accessibility_delete_device'))
            .width(StyleConstants.DELETE_BUTTON_WIDTH)
            .height(StyleConstants.DELETE_BUTTON_HEIGHT)
            .onClick(() => {
                this.deleteDevice(device);
            })
        }
        .margin({
            left: '3%',
            right: '3%'
        })
    }

    @Builder
    EditButton(device: DeviceViewModel) {
        Row() {
            Button() {
                SymbolGlyph($r('sys.symbol.square_and_pencil'))
                    .fontSize(StyleConstants.ICON_WIDTH)
                    .fontColor([$r('sys.color.font_primary')])
            }
            .backgroundColor($r('app.color.green'))
            .type(ButtonType.Circle)
            .accessibilityText($r('app.string.accessibility_edit_device'))
            .width(StyleConstants.DELETE_BUTTON_WIDTH)
            .height(StyleConstants.DELETE_BUTTON_HEIGHT)
            .onClick(() => {
                this.safeCloseSwipeActions();
                this.pageStack.pushPath({
                    name: 'Edit',
                    param: [this.deviceList, device, this.pageStack],
                    onPop: async (popInfo: PopInfo) => {
                        await this.handleChildPop(popInfo, true);
                    }
                });
            })
        }
        .margin({
            left: '3%'
        })
    }

    @Builder
    TabBuilder(symbol: Resource, text: ResourceStr, onClick: () => void) {
        Column() {
            SymbolGlyph(symbol)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_TWENTY_TWO)
                .fontColor([$r('sys.color.font_primary')])

            Text(text)
                .fontSize(StyleConstants.TEXT_FONT_SIZE_TWELVE)
                .fontColor($r('sys.color.font_primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({
            left: '2%',
            right: '2%'
        })
        .onClick(onClick)
    }

    @Builder
    DeviceListContent() {
        List({ scroller: this.scrollerForList, space: StyleConstants.CARD_SPACE }) {
            ForEach(this.deviceList.devices, (device: DeviceViewModel) => {
                ListItem() {
                    DeviceTile({
                        device: device,
                        onWake: () => {
                            this.wakeDevice(device);
                        }
                    })
                }
                .swipeAction({
                    end: {
                        builder: () => {
                            this.EditButton(device);
                            this.DeleteButton(device);
                        }
                    }
                })
            }, (device: DeviceViewModel) =>
                // key 带字段值：ForEach 只按 key 复用条目，只拿 ID 做 key 时字段变了条目仍是旧的
                // 实例，列表停在旧名/旧端口；ORDERINDEX 不进 key，重排时条目才跟着位置移动而不是重建
                `${device.ID}|${device.MAC}|${device.Alias}|${device.Address}|${device.Port}`)
            .onMove((from: number, to: number) => {
                // onMove 需要同步返回是否接受本次移动；写入异步执行，失败只记录日志
                this.deviceList.reorder(from, to).catch((err: Error) => {
                    Logger.error(this.LOG_TAG, `重排设备失败, ${err}`);
                });
                return true;
            }, {
                onLongPress: () => {
                    this.vibrateForReorder();
                }
            })
        }
        .listDirection(Axis.Vertical)
        .alignSelf(ItemAlign.Start)
        .height('100%')
        .width('100%')
        // 设备卡左右内缩走列表内边距；底部让出量走内容末尾留白，不写在 padding 上（否则被抬的是视口）
        .padding({
            top: StyleConstants.PAGE_PADDING,
            left: StyleConstants.PAGE_PADDING,
            right: StyleConstants.PAGE_PADDING
        })
        // 悬浮栏压住内容（barOverlap），滚动范围末尾让出「胶囊高 + 离底距 + 页面内边距」
        .contentEndOffset(StyleConstants.TAB_BAR_HEIGHT + StyleConstants.PAGE_PADDING)
    }

    private vibrateForReorder(): void {
        vibrate(CommonConstants.VIBRATE_EFFECT_ID_SOFT);
    }

    @Builder
    MainContent() {
        if (this.deviceList.loadState === 'failed') {
            // 加载失败与空列表分开：失败给重试入口
            AppEmptyState({
                text: $r('app.string.device_list_load_failed'),
                retryLabel: $r('app.string.button_retry_label'),
                onRetry: () => {
                    this.loadDevices();
                }
            })
        } else if (this.deviceList.devices.length === 0) {
            AppEmptyState({
                text: $r('app.string.no_device_message'),
                hint: $r('app.string.create_new_device_message')
            })
        } else {
            this.DeviceListContent();
        }
    }

    build() {
        HdsNavigation(this.pageStack) {
            // 单 TabContent 仅作为底部“添加新设备”入口
            HdsTabs({ controller: this.tabController }) {
                TabContent() {
                    Stack({ alignContent: Alignment.Top }) {
                        this.MainContent();

                        if (this.deviceList.loadState === 'loading') {
                            LoadingOverlay({ message: $r('app.string.loading_message') })
                        }
                    }
                }
                .tabBar(this.TabBuilder(
                    $r('sys.symbol.plus'),
                    $r('app.string.button_Add_label'),
                    () => {
                        this.safeCloseSwipeActions();
                        this.pageStack.pushPath({
                            name: 'AddDevice',
                            param: this.pageStack,
                            onPop: async (popInfo: PopInfo) => {
                                await this.handleChildPop(popInfo, true);
                            }
                        });
                    }
                ))
            }
            .barPosition(BarPosition.End)
            .scrollable(false)
            .barOverlap(true)
            .barFloatingStyle({
                barBottomMargin: StyleConstants.BAR_BOTTOM_MARGIN,
                // 三档同值：胶囊在分屏与全屏之间不跳宽
                barWidth: {
                    smallWidth: StyleConstants.TAB_BAR_WIDTH,
                    mediumWidth: StyleConstants.TAB_BAR_WIDTH,
                    largeWidth: StyleConstants.TAB_BAR_WIDTH
                },
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.ADAPTIVE,
                    materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
                }
            })
        }
        .titleBar({
            content: {
                title: {
                    mainTitle: $r('app.string.title_label'),
                    subTitle: this.ipBannerText
                },
                menu: this.menus
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
        .bindToScrollable([this.scrollerForList])
        // 页面底铺在根节点：悬浮栏保持系统材质叠在其上，栏内外的底是同一层
        .backgroundColor($r('sys.color.background_secondary'))
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, 'Loaded!');
        })
    }
}