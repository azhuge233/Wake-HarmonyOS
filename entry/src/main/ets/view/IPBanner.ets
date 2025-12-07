import { connection } from "@kit.NetworkKit";

import StyleConstants from "../common/constants/StyleConstants";
import Logger from "../common/utils/Logger";

@ComponentV2
export default struct IPBanner {
    private LOG_TAG = "[view/IPBanner]";

    @Param ipBannerText: string = '';

    @Event onRefresh: () => void = () => {};

    private netConnection: connection.NetConnection | null = null;

    aboutToAppear(): void {
        this.startNetListening();
    }

    aboutToDisappear(): void {
        this.stopNetListening()
    }

    // 启用网络监听
    // aboutToAppear 内调用
    private startNetListening() {
        // 创建网络监听器
        try {
            this.netConnection = connection.createNetConnection({
                netCapabilities: {
                    bearerTypes: [connection.NetBearType.BEARER_WIFI] // 指定监听WiFi
                }
            });
        } catch (err) {
            Logger.error(this.LOG_TAG, `创建网络监听失败: ${err}`);
            return;
        }

        // 注册网络可用的监听
        this.netConnection.on('netAvailable', (data: connection.NetHandle) => {
            Logger.info(this.LOG_TAG, `网络连接成功: ${JSON.stringify(data)}`);
            this.onRefresh();
        });

        // 注册网络能力变化的监听（这是检测IP/子网变化的关键）
        this.netConnection.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
            Logger.info(this.LOG_TAG, `网络能力发生变化，可能包括IP或子网: ${JSON.stringify(data)}`);
            this.onRefresh();
        });

        // 注册网络丢失的监听
        this.netConnection.on('netLost', (data: connection.NetHandle) => {
            Logger.info(this.LOG_TAG, `网络连接断开: ${JSON.stringify(data)}`);
            this.onRefresh();
        });

        // 开始监听
        this.netConnection.register((err: BusinessError) => {
            if (err) {
                Logger.error(this.LOG_TAG, `注册网络监听失败, ${err}`);
            }
        });
    }

    // 关闭网络监听
    // aboutToDisappear 内调用
    private stopNetListening() {
        if (this.netConnection) {
            this.netConnection.unregister((err: BusinessError) => {
                if (err) {
                    Logger.error(this.LOG_TAG, `取消注册网络监听失败，${err}`);
                }
            });
            this.netConnection = null;
        }
    }

    build() {
        Text(this.ipBannerText)
            .maxLines(StyleConstants.BANNER_MAX_LINE)
            .fontSize(StyleConstants.BANNER_FONT_SIZE)
            .fontWeight(StyleConstants.BANNER_FONT_WEIGHT)
            .backgroundColor($r("app.color.banner_grey"))
            .width(StyleConstants.FULL_PERCENT)
            .textAlign(TextAlign.Center)
    }
}