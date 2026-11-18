class StyleConstants {
    public readonly FULL_PERCENT = '100%';
    public readonly EIGHTY_FIVE_PERCENT = '85%';
    public readonly EIGHTY_PERCENT = '80%';
    public readonly SEVENTY_TWO_PERCENT = '72%';
    public readonly SEVENTY_PERCENT = '70%';
    public readonly SIXTY_PERCENT = '60%';
    public readonly THIRTY_PERCENT = '30%';
    public readonly TWENTY_TWO_PERCENT = '22%';
    public readonly TWENTY_PERCENT = '20%';
    public readonly TEN_PERCENT = '10%';
    public readonly FIVE_PERCENT = '5%';
    public readonly TWO_PERCENT = '2%';

    public readonly MARGIN_TWO_PERCENT = '2%';

    public readonly MARGIN_TWENTY = 20;
    public readonly MARGIN_TEN = 10;
    public readonly MARGIN_EIGHT = 8;
    public readonly MARGIN_FIVE = 5;
    public readonly MARGIN_THREE = 3;

    public readonly PADDING_SIXTEEN = 16;
    public readonly PADDING_FIFTEEN = 15;
    public readonly PADDING_TEN = 10;
    public readonly PADDING_EIGHT = 8;
    public readonly PADDING_FIVE = 5;
    public readonly PADDING_TWO = 2;

    public readonly TEXT_INPUT_MAX_LINE = 1;
    public readonly TEXT_INPUT_DEFAULT_MAX_LENGTH = 99;
    public readonly TEXT_INPUT_MAC_MAX_LENGTH = 17;
    public readonly TEXT_INPUT_ALIAS_MAX_LENGTH = 30;
    public readonly TEXT_INPUT_PORT_MAX_LENGTH = 5;

    public readonly TEXT_FONT_SIZE_TWENTY_TWO = 22;
    public readonly TEXT_FONT_SIZE_EIGHTEEN = 18;
    public readonly TEXT_FONT_SIZE_SEVENTEEN = 17;
    public readonly TEXT_FONT_SIZE_FIFTEEN = 15;
    public readonly TEXT_FONT_SIZE_FOURTEEN = 14;
    public readonly TEXT_FONT_SIZE_THIRTEEN = 13;
    public readonly TEXT_FONT_SIZE_TWELVE = 12;
    public readonly TEXT_FONT_SIZE_EIGHT = 8;

    public readonly DELETE_BUTTON_WIDTH = 40;
    public readonly DELETE_BUTTON_HEIGHT = 40;

    public readonly ICON_HEIGHT = 28;
    public readonly ICON_WIDTH = 28;
    // 图标盒宽固定：文字列左缘由它钉住，不再由图标尺寸加左右外边距凑出
    public readonly ICON_BOX_WIDTH = 32;
    // 图标盒到文字列的距离
    public readonly ICON_TEXT_GAP = 12;

    public readonly PROGRESS_WIDTH = 100;
    public readonly PROGRESS_COLUMN_BLUR_LEVEL = 8;
    public readonly PROGRESS_STROKE_WIDTH = 18;

    public readonly LOADING_WIDTH = 128;

    public readonly BORDER_RADIUS_THIRTEEN = 13;
    public readonly BORDER_WIDTH = 0.5;

    public readonly FORM_ITEM_HEIGHT = 45;
    // 卡片条目内的图标：须小于 FORM_ITEM_HEIGHT，上下留白不小于 MARGIN_THREE
    public readonly FORM_ITEM_ICON = 36;

    public readonly BAR_BOTTOM_MARGIN = 28;

    /** 底部悬浮胶囊的留底高度：胶囊高 + 离底距，列表末尾按它让出底带 */
    public get TAB_BAR_HEIGHT(): number {
        return this.TAB_BAR_CAPSULE_HEIGHT + this.BAR_BOTTOM_MARGIN;
    }

    public readonly DEVICE_TILE_HEIGHT = 76;

    // 卡面四件套的取值：设备条目、设置页的卡与网络信息页签卡共用同一组
    public readonly CARD_RADIUS = 16;
    public readonly CARD_BORDER_WIDTH = 1;
    public readonly CARD_PADDING = 16;
    public readonly CARD_SPACE = 12;

    public readonly ROW_VERTICAL_PADDING = 12;
    public readonly PAGE_PADDING = 16;

    public readonly TAB_BAR_CAPSULE_HEIGHT = 56;
    // 三档同值：分档会让胶囊在分屏与全屏之间跳宽；按英文「Add New Device」在 12fp 下的宽度定，留出胶囊内边距
    public readonly TAB_BAR_WIDTH = 140;

    // 页签分段：槽高与槽内边距。槽圆角取高度折半；选中块圆角 18 = (槽高 − 2×内边距) ÷ 2（1vp 描边另占内缩带，块实际高 34）
    public readonly TAB_SEGMENT_HEIGHT = 40;
    public readonly TAB_SEGMENT_INSET = 2;

    // 可折叠分组头的线宽与文字、箭头尺寸
    public readonly DIVIDER_STOKE_WIDTH = 1;
    public readonly DIVIDER_FONT_SIZE = 12;
    public readonly DIVIDER_SYMBOL_SIZE = 15;
}

const styleConstants = new StyleConstants();
export { styleConstants as StyleConstants };
