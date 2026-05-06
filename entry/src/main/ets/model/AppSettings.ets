import { ConfigurationConstant } from '@kit.AbilityKit';

export class AppSettings {
    colorMode: ConfigurationConstant.ColorMode;

    constructor(colorMode: ConfigurationConstant.ColorMode) {
        this.colorMode = colorMode;
    }
}