import { ConfigurationConstant } from '@kit.AbilityKit';

/** 进程级共享的应用设置对象（AppStorageV2 承载），页面读，Ability 与颜色模式设置页写 */
@ObservedV2
export class AppSettings {
    @Trace colorMode: ConfigurationConstant.ColorMode;

    constructor(colorMode: ConfigurationConstant.ColorMode) {
        this.colorMode = colorMode;
    }
}