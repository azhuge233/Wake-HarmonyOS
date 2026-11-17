import bundleManager from '@ohos.bundle.bundleManager';

import { Logger } from '../common/log/Logger';

/** 关于页的视图模型：版本号读取，无服务依赖 */
@ObservedV2
export class AboutViewModel {
    private LOG_TAG = '[AboutViewModel]';

    @Trace versionName: string = '';
    @Trace versionCode: string = '';

    loadVersion(): void {
        try {
            const bundleInfo = bundleManager.getBundleInfoForSelfSync(
                bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
            this.versionName = bundleInfo.versionName;
            this.versionCode = bundleInfo.versionCode.toString();
        } catch (err) {
            Logger.error(this.LOG_TAG, `读取版本号失败: ${err}`);
        }
    }
}
