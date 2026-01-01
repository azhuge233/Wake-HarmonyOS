import { FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

import { PM } from '../../common/utils/PM';
import { DB } from '../../common/utils/DB';
import FormData from '../model/FormData';
import CommonConstants from '../../common/constants/CommonConstants';
import CommonUtils from '../../common/utils/CommonUtils';
import Logger from '../../common/utils/Logger';

export default class WakeFormAbility extends FormExtensionAbility {
    private LOG_TAG = '[EntryFormAbility]';

    private db: DB = DB.getInstance();
    private pm: PM = PM.getInstance();

    // Tips
    // 卡片变换大小时会调用，新建变换后的 Form
    onAddForm(want: Want) {
        // Called to return a FormBindingData object.
        const formID = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;
        // const formDimensions = want?.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number;

        Logger.debug(this.LOG_TAG, `onAddForm() formID: ${formID}`);

        const formData = new FormData(formID, false);

        return CommonUtils.createFormBindingData(formData);
    }

    // Tips
    // 卡片变换大小时会调用，删除被变换的 Form
    async onUpdateForm(formId: string) {
        // Called to notify the form provider to update a specified form.
        Logger.debug(this.LOG_TAG, `${formId} onUpdateForm()`);

        this.init();

        try {
            const formData = await this.getFormDataByID(formId);

            if(formData) {
                Logger.debug(this.LOG_TAG, `onUpdateForm() 查询到 formID = ${formId} 的卡片 formData`);

                const formInfo = CommonUtils.createFormBindingData(formData);
                await formProvider.updateForm(formId, formInfo);

                Logger.debug(this.LOG_TAG, `onUpdateForm() formID = ${formId} 的卡片已更新`);
            } else {
                Logger.warn(this.LOG_TAG, `onUpdateForm() formID = ${formId} 的卡片 formData 为空`);

                const formInfo = CommonUtils.createFormBindingData(formId);
                await formProvider.updateForm(formId, formInfo);

                Logger.warn(this.LOG_TAG, `onUpdateForm() 已重置 formID = ${formId} 的卡片`);
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `${formId} onUpdateForm() 执行错误, ${err}`)
        }
    }

    async onFormEvent(formId: string, message: string) {
        // Called when a specified message event defined by the form provider is triggered.
        Logger.debug(this.LOG_TAG, `onFormEvent(), formID: ${formId}, message: ${message}`);

        this.init();

        // 卡片传参
        const messageObj: Record<string, Object> = JSON.parse(message);
        // action 参数
        const action = messageObj.formAction as string;

        // 根据 action 执行：更新卡片信息
        if(action === CommonConstants.FormMessage_Update) await this.handleUpdateAction(formId, messageObj.data as number);
        else Logger.warn(this.LOG_TAG, `onFormEvent() 未知指令: ${action}`);
    }

    async onRemoveForm(formId: string) {
        // Called to notify the form provider that a specified form has been destroyed.
        Logger.debug(this.LOG_TAG, `onRemoveForm() formID: ${formId}`);

        this.init();

        await this.unbindForm(formId);
    }

    onCastToNormalForm(formId: string) {
        // Called when the form provider is notified that a temporary form is successfully
        // converted to a normal form.
        Logger.debug(this.LOG_TAG, `onCastToNormalForm() formID: ${formId}`);
    }

    onAcquireFormState(want: Want) {
        // Called to return a {@link FormState} object.
        const formID = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;

        Logger.debug(this.LOG_TAG, `$onAcquireFormState() formID: ${formID}`);

        return formInfo.FormState.READY;
    }

    private init() {
        this.db.init(this.context);
        this.pm.init(this.context);
    }

    private async unbindForm(formID: string) {
        const success = await this.pm.unbind(formID);
        if(success) Logger.debug(this.LOG_TAG, `unbindForm() 已删除卡片绑定: ${formID}`);
        else Logger.warn(this.LOG_TAG, `unbindForm() 删除卡片绑定失败: ${formID}`)
    }

    private async getFormDataByID(formID: string): Promise<FormData | null> {
        const formData = await this.pm.getFormDataByID(formID);

        Logger.debug(this.LOG_TAG, `getFormDataByID() ${formID} 查询结果: ${JSON.stringify(formData)}`);

        return formData;
    }

    private async handleUpdateAction(formID: string, deviceID: number) {
        const device = await this.db.getDeviceByID(deviceID);

        if(device) {
            Logger.debug(this.LOG_TAG, `handleUpdateAction() 查询到指令 deviceID = ${deviceID} 的 DB 条目`);

            const formData = new FormData(formID, true);

            formData.deviceID = device.ID;
            formData.alias = device.Alias;
            formData.mac = device.MAC;

            const success = await this.pm.bind(formID, formData);

            if(success) Logger.debug(this.LOG_TAG, `handleUpdateAction() 已更新 formID = ${formID} 的卡片`);
            else Logger.warn(this.LOG_TAG, `handleUpdateAction() formID = ${formID} 的卡片更新失败`);

            Logger.debug(this.LOG_TAG, `handleUpdateAction() 已更新 formID = ${formID} 的卡片`);
        } else {
            Logger.warn(this.LOG_TAG, `handleUpdateAction() 指令 deviceID = ${deviceID} 的条目为空`);

            await this.unbindForm(formID);
        }

        await this.onUpdateForm(formID);
    }
}