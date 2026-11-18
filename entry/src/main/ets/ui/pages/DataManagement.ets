import { common } from '@kit.AbilityKit';

import { StyleConstants } from '../../common/constants/StyleConstants';
import { Logger } from '../../common/log/Logger';
import { BackupService, ExportOutcome, ImportSummary } from '../../domain/BackupService';
import { CardBindingService } from '../../domain/CardBindingService';
import { DeviceService } from '../../domain/DeviceService';
import { DataManagementViewModel } from '../../viewmodel/DataManagementViewModel';
import { LoadingOverlay } from '../component/LoadingOverlay';
import { PageScaffold, PageReadyContext } from '../component/PageScaffold';
import { SettingGroup } from '../component/SettingGroup';
import { SettingRow } from '../component/SettingRow';
import { showToast } from '../feedback/Feedback';
import { resourceTextFormatted } from '../util/ResourceText';

@Builder
export function DataManagementBuilder() {
    DataManagement();
}

/**
 * 数据管理子页：导出、导入、清除三项从设置页搬来，弹窗、失败提示、卡片刷新与返回串沿用原实现。
 * 三项是操作行（点击执行、不跳页），不带箭头；卡面由 SettingGroup 承担。
 */
@ComponentV2
struct DataManagement {
    private LOG_TAG = '[ui/pages/DataManagement]';

    private viewModel: DataManagementViewModel = new DataManagementViewModel(BackupService.instance(),
        DeviceService.instance(), CardBindingService.instance());

    private uiContext = this.getUIContext();
    private context = this.uiContext.getHostContext() as common.UIAbilityContext;
    private promptAction = this.uiContext.getPromptAction();

    pathStack: NavPathStack | undefined = undefined;

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
     * 导入完成提示：四种情形各取一句完整文案，不拼句子。两个失败数都为 0 才是纯「导入成功」，
     * 其余三种交给 importDoneText 按情形选 key；数字作为格式化实参进句子，不接在句子后面。
     */
    private showImportDone(summary: ImportSummary): void {
        if (summary.failed === 0 && summary.cardsFailed === 0) {
            showToast(this.promptAction, $r('app.string.import_success'));
            return;
        }
        showToast(this.promptAction, this.importDoneText(summary));
    }

    /** 有失败时的提示：三分支互斥且穷尽——两者都有、只有入库失败、只有卡片刷新失败；前提是两个失败数不全为 0（由 showImportDone 保证） */
    private importDoneText(summary: ImportSummary): string {
        if (summary.failed > 0 && summary.cardsFailed > 0) {
            return resourceTextFormatted($r('app.string.import_partial_both'), this.context,
                [summary.failed, summary.cardsFailed]);
        }
        if (summary.failed > 0) {
            return resourceTextFormatted($r('app.string.import_partial_rows'), this.context, [summary.failed]);
        }
        return resourceTextFormatted($r('app.string.import_partial_cards'), this.context, [summary.cardsFailed]);
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
    ExportRow() {
        SettingRow({
            icon: $r('sys.symbol.arrow_up_circle'),
            title: $r('app.string.page_more_export'),
            desc: $r('app.string.export_desc'),
            showArrow: false,
            interactive: true,
            titleColor: $r('sys.color.font_primary'),
            onTap: () => {
                if (this.viewModel.busy === 'idle') {
                    this.exportDevices().catch((err: Error) => {
                        Logger.error(this.LOG_TAG, `导出失败, ${err}`);
                        showToast(this.promptAction, $r('app.string.export_failed'));
                    });
                } else {
                    this.showBusy();
                }
            }
        })
    }

    @Builder
    ImportRow() {
        SettingRow({
            icon: $r('sys.symbol.arrow_down_circle'),
            title: $r('app.string.page_more_import'),
            desc: $r('app.string.import_desc'),
            showArrow: false,
            interactive: true,
            titleColor: $r('sys.color.font_primary'),
            onTap: () => {
                if (this.viewModel.busy === 'idle') {
                    this.importConfirm().catch((err: Error) => {
                        Logger.error(this.LOG_TAG, `导入失败, ${err}`);
                        showToast(this.promptAction, $r('app.string.import_failed'));
                    });
                } else {
                    this.showBusy();
                }
            }
        })
    }

    @Builder
    ClearRow() {
        SettingRow({
            icon: $r('sys.symbol.trash'),
            title: $r('app.string.page_more_clear'),
            showArrow: false,
            interactive: true,
            titleColor: $r('sys.color.warning'),
            onTap: () => {
                if (this.viewModel.busy !== 'idle') {
                    this.showBusy();
                    return;
                }
                this.clearAll().catch((err: Error) => {
                    Logger.error(this.LOG_TAG, `清除失败, ${err}`);
                    showToast(this.promptAction, $r('app.string.clear_failed'));
                });
            }
        })
    }

    @Builder
    PageContent() {
        Column({ space: StyleConstants.CARD_SPACE }) {
            SettingGroup({
                rows: (): void => {
                    this.ExportRow();
                    this.ImportRow();
                }
            })

            SettingGroup({
                rows: (): void => {
                    this.ClearRow();
                }
            })
        }
        .width(StyleConstants.FULL_PERCENT)
        .padding({
            top: StyleConstants.PAGE_PADDING,
            bottom: StyleConstants.PAGE_PADDING,
            left: StyleConstants.PAGE_PADDING,
            right: StyleConstants.PAGE_PADDING
        })
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
            title: $r('app.string.data_management_title'),
            logTag: this.LOG_TAG,
            scrollable: true,
            pageBackground: $r('sys.color.background_secondary'),
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
