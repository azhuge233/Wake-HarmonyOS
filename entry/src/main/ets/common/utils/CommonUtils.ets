import { deviceInfo, BusinessError, systemDateTime } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { PromptAction } from '@ohos.arkui.UIContext';
import { picker, fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { vibrator } from '@kit.SensorServiceKit';
import { buffer } from '@kit.ArkTS';
import { formBindingData } from '@kit.FormKit';

import Logger from './Logger';
import StyleConstants from '../constants/StyleConstants';
import { DeviceJsonObject } from '../../model/JsonObject';
import SingleDeviceFormData from '../../singledevicewidget/model/SingleDeviceFormData'
import MultipleDevicesFormData from '../../multipledeviceswidget/model/MultipleDevicesFormData';

class CommonUtils {
    private LOG_TAG = "[CommonUtils]";

    // Debug
    // 等待 time 秒
    public async sleep(time: number): Promise<void> {
        await new Promise<void>(resolve => setTimeout(resolve, time));
    }

    public alert(message: string | Resource, promptAction: PromptAction) {
        promptAction.openToast({
            message: message
        }).catch((err: BusinessError) => {
            Logger.error(this.LOG_TAG, `<alert API > 17> 错误, ${err}`);
        });
    }

    // 从 NavDestination 由 pop() 返回时
    // 显示回调 popInfo
    public returnFromSubPage(popInfo: PopInfo): void {
        Logger.debug(this.LOG_TAG,
            `从 [${popInfo.info.name}] 页面返回, 携带参数: ${JSON.stringify(popInfo.result)}`);
    }

    // 检查 MAC、Alias 是否为空
    public isStringNullOrEmpty(str?: string): boolean {
        return str === undefined || str === null || str === '' || str.length === 0;
    }

    // 检查 MAC 合法性，分隔符仅支持 ':' 和 '-'
    public macValidate(mac: string): Resource | string {
        if (mac.length < StyleConstants.TEXT_INPUT_MAC_MAX_LENGTH) {
            return $r("app.string.validate_mac_too_short");
        }

        const regex = /^(?:[0-9A-Fa-f]{2}([-:]))(?:[0-9A-Fa-f]{2}\1){4}[0-9A-Fa-f]{2}$/

        if (!regex.test(mac)) {
            return $r("app.string.validate_mac_regex_fail");
        }

        Logger.info(this.LOG_TAG, `MAC validateion passed. MAC: ${mac}`);

        return '';
    }

    // 设备振动
    public vibrate(effectId: string) {
        try {
            vibrator.isSupportEffect(effectId, (err: BusinessError, state: boolean) => {
                if (err) {
                    Logger.error(this.LOG_TAG, `查询振动效果失败, 代码: ${err.code}, 错误信息: ${err.message}`);
                    return;
                }

                Logger.info(this.LOG_TAG, `设置支持 ${effectId} 振动`);

                if (state) {
                    try {
                        // 触发马达振动
                        vibrator.startVibration({
                            type: 'preset',
                            effectId: effectId,
                            count: 1,
                            intensity: 100,
                        }, {
                            usage: 'unknown'
                        }, (error: BusinessError) => {
                            if (error) Logger.error(this.LOG_TAG, `振动触发失败, 代码: ${error.code}, 错误信息: ${error.message}`);
                            else Logger.info(this.LOG_TAG, '成功触发振动');
                        });
                    } catch (error) {
                        Logger.error(this.LOG_TAG, `振动发生未知错误, ${error}`);
                    }
                }
            });
        } catch (error) {
            Logger.error(this.LOG_TAG, `振动发生未知错误, ${error}`);
        }
    }

    // 导出功能
    // 保存到文件
    public async saveToFile(json: string, context: common.UIAbilityContext): Promise<boolean> {
        let jsonFilename = `Wake-backup-${this.getDate()}.json`;

        const documentSaveOptions = new picker.DocumentSaveOptions();
        documentSaveOptions.newFileNames = [jsonFilename];
        documentSaveOptions.fileSuffixChoices = [".json"];

        const documentViewPicker = new picker.DocumentViewPicker(context);

        try {
            const uris = await documentViewPicker.save(documentSaveOptions);
            Logger.debug(this.LOG_TAG, `已选取保存路径: ${uris}`);

            if (uris.length > 0) {
                let savePath: string = uris[0];

                let jsonFile = fs.openSync(savePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

                let writeLen = fs.writeSync(jsonFile.fd, json);
                Logger.debug(this.LOG_TAG, `配置文件已保存, 路径: ${jsonFile.path}, 写入长度: ${writeLen}`);

                fs.closeSync(jsonFile);
                return true;
            }

            Logger.warn(this.LOG_TAG, "没有选取保存路径");
            return false;
        } catch (err) {
            Logger.error(this.LOG_TAG, `保存失败, 代码: ${err.code},  ${err.message}`);
            throw new Error("备份导出失败");
        }
    }

    // 导入功能
    // 选择备份文件路径
    public async pickFile(context: common.UIAbilityContext): Promise<string[]> {
        const documentSelectOptions = new picker.DocumentSelectOptions();
        documentSelectOptions.maxSelectNumber = 1;
        documentSelectOptions.fileSuffixFilters = [".json"];

        const documentViewPicker = new picker.DocumentViewPicker(context);
        const uris = await documentViewPicker.select(documentSelectOptions);

        Logger.debug(this.LOG_TAG, `选取文件: ${uris}`);
        return uris;
    }

    // 导入功能
    // 读取备份文件
    public async readFile(uri: string): Promise<string | undefined> {
        try {
            let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);

            let fileStat = fs.statSync(file.fd);
            let fileSize = fileStat.size;
            Logger.debug(this.LOG_TAG, `文件大小: ${fileSize} 字节`);

            // 读取文件
            // cannot use readText(Sync), throws 13900002 error(No such file or directory)
            let arrayBuffer = new ArrayBuffer(fileSize);
            let readLen = fs.readSync(file.fd, arrayBuffer);

            Logger.debug(this.LOG_TAG, `从文件读取 ${readLen} 字节`);
            if (readLen !== fileSize) Logger.warn(this.LOG_TAG,
                `应读取 ${fileSize} 字节, 但实际读取 ${readLen}`);

            let jsonString = buffer.from(arrayBuffer, 0, readLen).toString();

            fs.closeSync(file);

            Logger.debug(this.LOG_TAG, `读取成功, 内容长度: ${jsonString.length}`);
            return jsonString;
        } catch (err) {
            Logger.error(this.LOG_TAG, `文件读取失败, ${err}`);
            return undefined;
        }
    }

    // 导入功能
    // 解析 json 字符串到 DeviceJsonObject[] 对象
    public async parseData(jsonStr: string): Promise<Array<DeviceJsonObject>> {
        try {
            const deviceListJsonObject = JSON.parse(jsonStr) as Array<DeviceJsonObject>;

            if (Array.isArray(deviceListJsonObject)) {
                Logger.debug(this.LOG_TAG, `数据解析成功, 指令列表长度: ${deviceListJsonObject.length}`);
                return deviceListJsonObject;
            } else throw new Error("解析失败，指令列表非数组");
        } catch (err) {
            Logger.error(this.LOG_TAG, `数据解析失败, 代码: ${err.code}, 错误信息: ${err.message}`);
            throw new Error(err);
        }
    }

    // 关闭应用
    public closeApplication(from: string, context: common.UIAbilityContext) {
        Logger.info(from, `关闭应用`);
        context.terminateSelf().catch((err: BusinessError) => {
            Logger.error(from, `关闭应用失败, ${err}`);
        });
    }

    // 根据 data 类型创建 FormBindingData
    public createSingleDeviceFormBindingData(data: string | SingleDeviceFormData): formBindingData.FormBindingData {
        if(typeof(data) === "string") return this.createEmptySingleDeviceFormBindingData(data);
        else return formBindingData.createFormBindingData(data);
    }

    public createMultipleDevicesFormBindingData(data: string | MultipleDevicesFormData): formBindingData.FormBindingData {
        if(typeof(data) === "string") return this.createEmptyMultipleDevicesFormBindingData(data);
        else return formBindingData.createFormBindingData(data);
    }

    // 获取资源字符串，方便异常处理
    public getStringFromResource(context: common.UIAbilityContext, stringResource: Resource): string {
        try {
            return context.resourceManager.getStringSync(stringResource.id);
        } catch (err) {
            Logger.error(this.LOG_TAG, `获取资源字符串失败, ${err}`);
            return '';
        }
    }

    // 获取时间（毫秒）
    private getDate(): string {
        let date = new Date(systemDateTime.getTime());

        const formattedTime = `${date.getTime().toString()}`;
        Logger.debug(this.LOG_TAG, formattedTime);

        return formattedTime;
    }

    // 创建对应 formID 的空 FormData
    private createEmptySingleDeviceFormBindingData(formID: string): formBindingData.FormBindingData {
        const formData: SingleDeviceFormData = new SingleDeviceFormData(formID, false);

        return formBindingData.createFormBindingData(formData);
    }

    private createEmptyMultipleDevicesFormBindingData(formID: string): formBindingData.FormBindingData {
        const formData: MultipleDevicesFormData = new MultipleDevicesFormData(formID, false);

        return formBindingData.createFormBindingData(formData);
    }
}

export default new CommonUtils();