import { ConfigurationConstant } from '@kit.AbilityKit';

@ObservedV2
export class AppSettings {
    @Trace colorMode: ConfigurationConstant.ColorMode;

    constructor(colorMode: ConfigurationConstant.ColorMode) {
        this.colorMode = colorMode;
    }
}