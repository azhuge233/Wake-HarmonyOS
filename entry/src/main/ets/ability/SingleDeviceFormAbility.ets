import { Want } from '@kit.AbilityKit';
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';

import { CommonConstants } from '../common/constants/CommonConstants';
import { Logger } from '../common/log/Logger';
import { SingleCardBindingData } from '../common/model/CardBindingData';
import { CardBindingStore } from '../data/CardBindingStore';
import { CardPublisher } from '../data/CardPublisher';
import { AbilitySetup } from './AbilitySetup';

/**
 * 单设备卡片的 FormExtensionAbility：卡片生命周期 + restore 消息。
 * 绑定数据只经 CardBindingStore 与 CardPublisher 读写，不碰页面与工具类。
 */
export default class SingleDeviceFormAbility extends FormExtensionAbility {
    private LOG_TAG = '[SingleDeviceFormAbility]';

    private store: CardBindingStore = CardBindingStore.getInstance();
    private publisher: CardPublisher = CardPublisher.getInstance();

    onCreate(want: Want): void {
        AbilitySetup.initDataLayer(this.context);
    }

    onAddForm(want: Want) {
        const formID = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;

        Logger.debug(this.LOG_TAG, `onAddForm() formID: ${formID}`);

        // 新卡片首次绑定前的空数据；FormBindingData 由本层创建，common/ 不引 FormKit
        return formBindingData.createFormBindingData(SingleCardBindingData.empty(formID));
    }

    async onUpdateForm(formId: string) {
        Logger.debug(this.LOG_TAG, `${formId} onUpdateForm()`);
        AbilitySetup.initDataLayer(this.context);

        const raw = await this.store.getRaw(formId);
        const report = await this.publisher.publishSingle(formId, raw);

        if (report.failed.length > 0) {
            Logger.warn(this.LOG_TAG, `onUpdateForm() formID = ${formId} 的卡片刷新失败`);
        } else {
            Logger.debug(this.LOG_TAG, `onUpdateForm() formID = ${formId} 的卡片已更新`);
        }
    }

    async onFormEvent(formId: string, message: string) {
        Logger.debug(this.LOG_TAG, `onFormEvent(), formID: ${formId}, message: ${message}`);

        AbilitySetup.initDataLayer(this.context);

        const messageObj: Record<string, Object> = JSON.parse(message);
        const action = messageObj.formAction as string;

        if (action === CommonConstants.FORM_MESSAGE_RESTORE) {
            await this.handleRestoreAction(formId, messageObj.data as string);
        } else {
            Logger.warn(this.LOG_TAG, `onFormEvent() 未知指令: ${action}`);
        }
    }

    async onRemoveForm(formId: string) {
        Logger.debug(this.LOG_TAG, `onRemoveForm() formID: ${formId}`);

        AbilitySetup.initDataLayer(this.context);

        const removed = await this.store.remove(formId);
        if (removed) Logger.debug(this.LOG_TAG, `onRemoveForm() 已删除卡片绑定: ${formId}`);
        else Logger.warn(this.LOG_TAG, `onRemoveForm() 删除卡片绑定失败: ${formId}`);
    }

    onCastToNormalForm(formId: string) {
        Logger.debug(this.LOG_TAG, `onCastToNormalForm() formID: ${formId}`);
    }

    onAcquireFormState(want: Want) {
        const formID = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
        Logger.debug(this.LOG_TAG, `onAcquireFormState() formID: ${formID}`);
        return formInfo.FormState.READY;
    }

    /** 卡片恢复显示：有绑定数据就重发，没有就清除绑定并重置卡片 */
    private async handleRestoreAction(formID: string, from: string): Promise<void> {
        Logger.debug(this.LOG_TAG, `handleRestoreAction() 调用方 ${from}`);

        const raw = await this.store.getRaw(formID);
        if (raw === null) {
            Logger.warn(this.LOG_TAG, `handleRestoreAction() 未查询到 formID = ${formID} 卡片的绑定数据`);
            await this.store.remove(formID);
        }

        await this.publisher.publishSingle(formID, raw);
    }
}