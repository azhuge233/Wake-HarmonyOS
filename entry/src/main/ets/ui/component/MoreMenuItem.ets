import { StyleConstants } from '../../common/constants/StyleConstants';
import { SettingRow } from './SettingRow';

/**
 * 更多页的一行：图标 + 标题 + 描述行 + 点击。
 * 行形状由 SettingRow 承载，描述行经 desc 传入，不另起第二套行。
 */
@ComponentV2
export struct MoreMenuItem {
    @Param menuTitleText: ResourceStr = '';
    @Param menuDescText: ResourceStr | null = null;
    @Param menuIcon: ResourceStr = $r('app.media.icon');
    @Event onTap: () => void = () => {
    };

    build() {
        Column() {
            SettingRow({
                icon: this.menuIcon,
                title: this.menuTitleText,
                desc: this.menuDescText ?? '',
                onTap: () => this.onTap()
            })
        }
        .width(StyleConstants.FULL_PERCENT)
    }
}