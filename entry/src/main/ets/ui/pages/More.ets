import { common } from '@kit.AbilityKit';

import { Logger } from '../../common/log/Logger';
import { BackupService, ExportOutcome, ImportSummary } from '../../domain/BackupService';
import { CardBindingService } from '../../domain/CardBindingService';
import { DeviceService } from '../../domain/DeviceService';
import { MoreViewModel } from '../../viewmodel/MoreViewModel';
import { LoadingOverlay } from '../component/LoadingOverlay';
import { MoreMenuItem } from '../component/MoreMenuItem';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { showToast } from '../feedback/Feedback';
import { resourceText } from '../util/ResourceText';

/** 更多页的一行：标题、图标、描述、动作 */
class MenuEntry {
    title: Resource;
    icon: Resource;
    desc: Resource | null;
    action: () => void;

    constructor(title: Resource, icon: Resource, desc: Resource | null, action: () => void) {
        this.title = title;
        this.icon = icon;
        this.desc = desc;
        this.action = action;
    }
}

@Builder
export function MoreBuilder() {
    More();
}

@ComponentV2
struct More {
    private LOG_TAG = '[ui/pages/More]';

    private viewModel: MoreViewModel = new MoreViewModel(BackupService.instance(),
        DeviceService.instance(), CardBindingService.instance());

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    private promptAction = this.uiContext.getPromptAction();

    pathStack: NavPathStack | undefined = undefined;

    private settingsEntries: Array<MenuEntry> = [
        new MenuEntry($r('app.string.color_mode_title'), $r('app.media.brush'), $r('app.string.color_mode_desc'),
            () => {
                if (this.viewModel.busy === 'idle') {
                    this.pathStack?.pushPath({ name: 'ColorModeSettings', param: this.pathStack });
                } else {
                    this.showBusy();
                }
            })
    ];

    private functionEntries: Array<MenuEntry> = [
        new MenuEntry($r('app.string.network_info_title'), $r('app.media.wifi'), $r('app.string.network_info_desc'),
            () => {
                if (this.viewModel.busy === 'idle') {
                    this.pathStack?.pushPath({ name: 'NetworkInfo', param: this.pathStack });
                } else {
                    this.showBusy();
                }
            }),
        new MenuEntry($r('app.string.page_more_export'), $r('app.media.arrow_up_circle'),
            $r('app.string.export_desc'), () => {
                if (this.viewModel.busy === 'idle') {
                    this.exportDevices().catch((err: Error) => {
                        Logger.error(this.LOG_TAG, `导出失败, ${err}`);
                        showToast(this.promptAction, $r('app.string.export_failed'));
                    });
                } else {
                    this.showBusy();
                }
            }),
        new MenuEntry($r('app.string.page_more_import'), $r('app.media.arrow_down_circle'),
            $r('app.string.import_desc'), () => {
                if (this.viewModel.busy === 'idle') {
                    this.importConfirm().catch((err: Error) => {
                        Logger.error(this.LOG_TAG, `导入失败, ${err}`);
                        showToast(this.promptAction, $r('app.string.import_failed'));
                    });
                } else {
                    this.showBusy();
                }
            })
    ];

    private othersEntries: Array<MenuEntry> = [
        new MenuEntry($r('app.string.page_more_clear'), $r('app.media.clean'), null, () => {
            if (this.viewModel.busy !== 'idle') {
                this.showBusy();
                return;
            }
            this.clearAll().catch((err: Error) => {
                Logger.error(this.LOG_TAG, `清除失败, ${err}`);
                showToast(this.promptAction, $r('app.string.clear_failed'));
            });
        })
    ];

    aboutToAppear(): void {
        this.viewModel.loadVersion();
    }

    /** 重入提示：按忙的种类给同一句等待文案；导出不造文案（系统保存对话框占屏，页面不在前台） */
    private showBusy(): void {
        if (this.viewModel.busy === 'importing') showToast(this.promptAction, $r('app.string.import_waiting_message'));
        else if (this.viewModel.busy === 'clearing') showToast(this.promptAction, $r('app.string.clear_waiting_message'));
    }

    private async exportDevices(): Promise<void> {
        const outcome: ExportOutcome = await this.viewModel.exportDevices();
        if (outcome.ok) {
            showToast(this.promptAction, $r('app.string.export_success'));
            return;
        }

        if (outcome.reason === 'cancelled') {
            Logger.warn(this.LOG_TAG, '导出取消');
            return;
        }

        showToast(this.promptAction, $r('app.string.export_failed'));
    }

    /**
     * 弹窗的 try 只包弹窗：入库那段的抛出要一路回落到条目调用处的 .catch（那里提示 import_failed），
     * 包在这里就会被“导入弹窗失败”的日志吃掉，用户侧变成“点了一下什么也没发生”。
     */
    private async importConfirm(): Promise<void> {
        let confirmed = false;
        try {
            const result = await this.promptAction.showDialog({
                title: $r('app.string.import_title'),
                message: $r('app.string.import_message'),
                buttons: [
                    {
                        text: $r('app.string.button_confirm_label'),
                        color: $r('sys.color.font_primary')
                    },
                    {
                        text: $r('app.string.button_cancel_label'),
                        color: $r('sys.color.font_primary')
                    }
                ]
            });

            confirmed = result.index === 0;
        } catch (err) {
            Logger.error(this.LOG_TAG, `导入弹窗失败, ${err}`);
            return;
        }

        if (confirmed) await this.importDevices();
        else Logger.warn(this.LOG_TAG, '导入已取消');
    }

    private async importDevices(): Promise<void> {
        let uri: string | null = null;
        try {
            uri = await this.viewModel.pickBackupFile();
        } catch (err) {
            Logger.error(this.LOG_TAG, `选择备份文件失败, ${err}`);
            showToast(this.promptAction, $r('app.string.import_failed'));
            return;
        }

        if (uri === null) {
            Logger.warn(this.LOG_TAG, '未选择备份文件');
            return;
        }

        const result = await this.viewModel.importFromFile(uri);
        if (result.ok && result.value !== null) {
            this.showImportDone(result.value);
            this.pathStack?.pop('Import back');
            return;
        }

        Logger.error(this.LOG_TAG, `导入失败: ${result.error}`);
        showToast(this.promptAction, $r('app.string.import_failed'));
    }

    /**
     * 导入完成提示：两个失败数都要说。逐条入库失败数（summary.failed）与卡片刷新失败数（cardsFailed）
     * 各自并进同一句；两者都为 0 才是纯「导入成功」。文案复用现有三句资源拼出，不新增 key。
     */
    private showImportDone(summary: ImportSummary): void {
        if (summary.failed === 0 && summary.cardsFailed === 0) {
            showToast(this.promptAction, $r('app.string.import_success'));
            return;
        }

        const parts: string[] = [resourceText($r('app.string.import_success'), this.context)];
        if (summary.failed > 0) {
            parts.push(`${resourceText($r('app.string.import_failed'), this.context)} ${summary.failed}`);
        }
        if (summary.cardsFailed > 0) {
            parts.push(`${resourceText($r('app.string.card_refresh_failed'), this.context)} ${summary.cardsFailed}`);
        }
        showToast(this.promptAction, parts.join(' '));
    }

    private async clearAll(): Promise<void> {
        try {
            const result = await this.promptAction.showDialog({
                title: $r('app.string.clear_title'),
                message: $r('app.string.clear_message'),
                buttons: [
                    {
                        text: $r('app.string.button_confirm_label'),
                        color: $r('sys.color.font_primary')
                    },
                    {
                        text: $r('app.string.button_cancel_label'),
                        color: $r('sys.color.font_primary')
                    }
                ]
            });

            if (result.index !== 0) {
                Logger.warn(this.LOG_TAG, '清除已取消');
                return;
            }

            const cleared = await this.viewModel.clearAll();
            if (!cleared) {
                showToast(this.promptAction, $r('app.string.clear_failed'));
                return;
            }

            // 顺序与 Edit.updateDevice 一致：先报清除成功，再让卡片失败停在最后一句上
            showToast(this.promptAction, $r('app.string.clear_success'));
            const refreshError = this.viewModel.consumeCardRefreshError();
            if (refreshError !== '') showToast(this.promptAction, $r('app.string.card_refresh_failed'));

            this.pathStack?.pop('Clear press');
        } catch (err) {
            Logger.error(this.LOG_TAG, `清除失败, ${err}`);
            showToast(this.promptAction, $r('app.string.clear_failed'));
        }
    }

    @Builder
    EntryGroup(entries: Array<MenuEntry>) {
        ForEach(entries, (item: MenuEntry) => {
            MoreMenuItem({
                menuTitleText: item.title,
                menuDescText: item.desc,
                menuIcon: item.icon,
                onTap: item.action
            })
        }, (item: MenuEntry) => item.icon.id.toString())
    }

    @Builder
    EntryDivider() {
        Divider()
            .lineCap(LineCapStyle.Round)
            .strokeWidth(2)
            .width('90%')
    }

    @Builder
    VersionFooter() {
        Text(`${this.viewModel.versionName} (${this.viewModel.versionCode})`)
            .width('100%')
            .fontColor(Color.Grey)
            .fontSize(13)
            .alignSelf(ItemAlign.End)
            .textAlign(TextAlign.Center)
    }

    @Builder
    PageContent() {
        Column() {
            Column() {
                this.EntryGroup(this.settingsEntries);

                this.EntryDivider();

                this.EntryGroup(this.functionEntries);

                this.EntryDivider();

                this.EntryGroup(this.othersEntries);
            }
            .height('100%')
            .width('100%')

            this.VersionFooter();
        }
        .height('100%')
        .width('100%')
    }

    @Builder
    PageOverlay() {
        // 遮罩只在入库与清除这两段：导出无遮罩，选文件期间也无遮罩
        if (this.viewModel.busy === 'importing') {
            LoadingOverlay({ message: $r('app.string.import_waiting_message') })
        } else if (this.viewModel.busy === 'clearing') {
            LoadingOverlay({ message: $r('app.string.clear_waiting_message') })
        }
    }

    build() {
        PageScaffold({
            title: $r('app.string.more_title'),
            logTag: this.LOG_TAG,
            content: (): void => {
                this.PageContent();
            },
            overlayContent: (): void => {
                this.PageOverlay();
            },
            onReady: (ctx: PageReadyContext) => {
                this.pathStack = (ctx.param as NavPathStack | undefined) ?? ctx.pathStack;
            },
            onBack: () => {
                if (this.viewModel.busy === 'importing' || this.viewModel.busy === 'clearing') {
                    this.showBusy();
                    return true;
                }
                return false;
            }
        })
    }
}