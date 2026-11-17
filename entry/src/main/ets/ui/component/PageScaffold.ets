import {
    hdsMaterial,
    HdsNavDestination,
    HdsNavigationMenuContentOptions,
    HdsNavigationTitle,
    HdsNavigationTitleBarOptions,
    SystemMaterialParams,
    TitleBarContentOptions,
    TitleBarStyleOptions
} from '@kit.UIDesignKit';

import { Logger } from '../../common/log/Logger';
import { StyleConstants } from '../../common/constants/StyleConstants';

/** onReady 交回的上下文：路由栈与本次路由入参 */
export interface PageReadyContext {
    pathStack: NavPathStack;
    param: object | undefined;
}

/**
 * HdsNavDestination 页的共用骨架：统一标题栏形态 + 内容区 + 覆盖层。
 * 只服务 HdsNavDestination 页；两个绑定页的根容器是 HdsNavigation，不进本件。
 * 不代页面 pop：退出路径各页不同，结果串留在页面侧，onBack 只回报“是否已消费”。
 */
@ComponentV2
export struct PageScaffold {
    private LOG_TAG = '[PageScaffold]';

    @Require @Param title: ResourceStr;
    @Require @Param logTag: string;
    @Param scrollable: boolean = false;
    @Param centered: boolean = false;
    @Param fillSize: boolean = false;
    @Param themeColorMode: boolean = false;
    @Param pageBackground: ResourceColor | undefined = undefined;
    @Param bindScrollables: Scroller[] = [];
    @Param menuOptions: HdsNavigationMenuContentOptions | undefined = undefined;

    @Event onReady: (ctx: PageReadyContext) => void = (ctx: PageReadyContext) => {
    };
    @Event onBack: () => boolean = () => false;

    @BuilderParam content: () => void = this.emptyBuilder;
    @BuilderParam overlayContent: () => void = this.emptyBuilder;

    @Builder
    emptyBuilder() {
    }

    /** 标题栏配置：无菜单时 content 里不写 menu 键，避免出现空菜单区 */
    private titleBarOptions(): HdsNavigationTitleBarOptions {
        const title: HdsNavigationTitle = { mainTitle: this.title };
        const content: TitleBarContentOptions = { title: title };
        if (this.menuOptions !== undefined) content.menu = this.menuOptions;

        const material: SystemMaterialParams = {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        };
        const style: TitleBarStyleOptions = { systemMaterialEffect: material };

        const options: HdsNavigationTitleBarOptions = {
            content: content,
            style: style,
            enableComponentSafeArea: true
        };
        return options;
    }

    build() {
        HdsNavDestination() {
            Stack({ alignContent: Alignment.Top }) {
                if (this.scrollable) {
                    Scroll() {
                        this.content();
                    }
                    .width(StyleConstants.FULL_PERCENT)
                } else {
                    this.content();
                }

                this.overlayContent();
            }
            .width(StyleConstants.FULL_PERCENT)
            .height(StyleConstants.FULL_PERCENT)
        }
        .titleBar(this.titleBarOptions())
        .alignSelf(this.centered ? ItemAlign.Center : ItemAlign.Auto)
        .align(Alignment.Center)
        .width(this.fillSize ? StyleConstants.FULL_PERCENT : undefined)
        .height(this.fillSize ? StyleConstants.FULL_PERCENT : undefined)
        .backgroundColor(this.pageBackground)
        .withTheme({ enableThemeColorMode: this.themeColorMode })
        .bindToScrollable(this.bindScrollables)
        .onReady((context: NavDestinationContext) => {
            Logger.debug(this.LOG_TAG, `${this.logTag} onReady fired, stackSize=${context.pathStack?.size()}`);
            const routeParam: object | undefined = context.pathInfo.param as object | undefined;
            const ready: PageReadyContext = {
                pathStack: context.pathStack,
                param: routeParam
            };
            this.onReady(ready);
            Logger.debug(this.LOG_TAG, `${this.logTag} onReady dispatched`);
        })
        .onBackPressed(() => {
            const consumed: boolean = this.onBack();
            Logger.debug(this.LOG_TAG, `${this.logTag} onBackPressed consumed=${consumed}`);
            return consumed;
        })
        .onAppear(() => {
            Logger.debug(this.LOG_TAG, `${this.logTag} Loaded!`);
        })
    }
}