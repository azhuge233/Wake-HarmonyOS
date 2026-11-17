import { formBindingData, formProvider } from '@kit.FormKit';

import { Logger } from '../common/log/Logger';
import { MultipleCardBindingData, SingleCardBindingData } from '../common/model/CardBindingData';

/** 一次发布的结果：哪些卡片成功、哪些失败。failed 必须被上层读到，刷新失败是业务结果 */
export interface PublishReport {
    updated: string[];
    failed: string[];
}

/**
 * 卡片刷新：@kit.FormKit 的 updateForm 集中在这里，页面与 VM 都不再出现 formProvider。
 * 绑定刷新、运行中、运行结果都是同一张卡片的整张数据替换，走同一条通道。
 */
export class CardPublisher {
    private LOG_TAG = '[CardPublisher]';

    private static instance: CardPublisher | null = null;

    constructor() {
    }

    static getInstance(): CardPublisher {
        if (!CardPublisher.instance) CardPublisher.instance = new CardPublisher();
        return CardPublisher.instance;
    }

    /** 绑定数据变化后刷新；raw 为空则发布未绑定占位数据 */
    async publishSingle(formID: string, raw: string | null): Promise<PublishReport> {
        if (raw === null || raw === '') return this.emptySingle(formID);

        try {
            const data = JSON.parse(raw) as SingleCardBindingData;
            return await this.push(formID, data);
        } catch (err) {
            Logger.error(this.LOG_TAG, `解析单设备卡片数据失败, formID: ${formID}, ${err}`);
            return this.failure(formID);
        }
    }

    async publishMultiple(formID: string, raw: string | null): Promise<PublishReport> {
        if (raw === null || raw === '') return this.emptyMultiple(formID);

        try {
            const data = JSON.parse(raw) as MultipleCardBindingData;
            return await this.push(formID, data);
        } catch (err) {
            Logger.error(this.LOG_TAG, `解析多设备卡片数据失败, formID: ${formID}, ${err}`);
            return this.failure(formID);
        }
    }

    /** 新卡片首次绑定前的空数据 */
    async emptySingle(formID: string): Promise<PublishReport> {
        return this.push(formID, SingleCardBindingData.empty(formID));
    }

    async emptyMultiple(formID: string): Promise<PublishReport> {
        return this.push(formID, MultipleCardBindingData.empty(formID));
    }

    /** 运行中 / 运行结果 */
    async publishRunSingle(formID: string, data: SingleCardBindingData): Promise<PublishReport> {
        return this.push(formID, data);
    }

    async publishRunMultiple(formID: string, data: MultipleCardBindingData): Promise<PublishReport> {
        return this.push(formID, data);
    }

    private async push(formID: string, data: Object): Promise<PublishReport> {
        try {
            const formInfo: formBindingData.FormBindingData = formBindingData.createFormBindingData(data);
            await formProvider.updateForm(formID, formInfo);
            Logger.debug(this.LOG_TAG, `已更新卡片, formID: ${formID}`);
            return { updated: [formID], failed: [] };
        } catch (err) {
            Logger.error(this.LOG_TAG, `刷新卡片失败, formID: ${formID}, ${err}`);
            return this.failure(formID);
        }
    }

    private failure(formID: string): PublishReport {
        return { updated: [], failed: [formID] };
    }
}