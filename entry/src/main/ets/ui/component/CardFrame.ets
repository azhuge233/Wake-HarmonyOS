import { StyleConstants } from '../../common/constants/StyleConstants';

/**
 * 卡片外框（V1）：唯一消费方是两张 V1 卡片页，因此不用 V2 装饰器。
 * 标题为空则不渲染标题行；body 由调用方给。
 */
@Component
export struct CardFrame {
    @Prop title: string = '';
    onTap: () => void = () => {
    };
    @BuilderParam body: () => void = this.emptyBody;

    @Builder
    emptyBody() {
    }

    build() {
        Column() {
            if (this.title !== '') {
                Text(this.title)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Color.White)
                    .maxLines(StyleConstants.TEXT_INPUT_MAX_LINE)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
            }

            this.body();
        }
        .width(StyleConstants.FULL_PERCENT)
        .height(StyleConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.Center)
        .onClick(() => this.onTap())
    }
}