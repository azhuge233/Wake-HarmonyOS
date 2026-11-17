import { NetworkSnapshot } from '../common/ports/NetworkInfoPort';
import { NetworkInfoService } from '../domain/NetworkInfoService';

/** 网络信息页的视图模型：只取一份快照，页面自己排版 */
@ObservedV2
export class NetworkInfoViewModel {
    @Trace snapshot: NetworkSnapshot | null = null;
    @Trace loading: boolean = false;

    private service: NetworkInfoService;

    constructor(service: NetworkInfoService) {
        this.service = service;
    }

    async load(): Promise<void> {
        this.loading = true;
        this.snapshot = await this.service.snapshot();
        this.loading = false;
    }
}