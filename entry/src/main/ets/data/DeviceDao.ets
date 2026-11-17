import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

import { Logger } from '../common/log/Logger';
import { Device, NewDeviceRecord } from '../common/model/Device';
import { PortInput } from '../common/util/PortInput';

export interface OrderIndexPair {
    id: number;
    orderIndex: number;
}

/**
 * 设备表的读写。表结构与列名与旧版一致（DEVICE / ID,MAC,ALIAS,ADDRESS,PORT,ORDERINDEX）。
 * 只做读写：业务判定在 domain/DeviceService。
 * 构造函数公开，供测试替换构造实参；getInstance() 只是生产装配入口。
 */
export class DeviceDao {
    private LOG_TAG = '[DeviceDao]';

    private static instance: DeviceDao | null = null;

    private initPromise: Promise<void> | null = null;
    /** 初始化失败的原因：initPromise 已清空后仍留着，供 ready() 把原始错误交出去 */
    private initError: Error | null = null;
    private rdbStore: relationalStore.RdbStore | undefined;

    private STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'Wake.db',
        securityLevel: relationalStore.SecurityLevel.S1
    };

    private TABLE_NAME = 'DEVICE';

    private KEY_ID = 'ID';
    private KEY_MAC = 'MAC';
    private KEY_ALIAS = 'ALIAS';
    private KEY_ADDRESS = 'ADDRESS';
    private KEY_PORT = 'PORT';
    private KEY_ORDERINDEX = 'ORDERINDEX';

    private COLUMNS: string[] = [
        this.KEY_ID,
        this.KEY_MAC,
        this.KEY_ALIAS,
        this.KEY_ADDRESS,
        this.KEY_PORT,
        this.KEY_ORDERINDEX
    ];

    private SQL_CREATE_TABLE = `CREATE TABLE IF NOT EXISTS ${this.TABLE_NAME} (
        ${this.KEY_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${this.KEY_MAC} TEXT NOT NULL,
        ${this.KEY_ALIAS} TEXT NOT NULL,
        ${this.KEY_ADDRESS} TEXT NOT NULL,
        ${this.KEY_PORT} INTEGER DEFAULT 9,
        ${this.KEY_ORDERINDEX} INTEGER DEFAULT 0
    )`;
    private SQL_DELETE_TABLE = `DELETE FROM ${this.TABLE_NAME}`;

    constructor() {
    }

    static getInstance(): DeviceDao {
        if (!DeviceDao.instance) DeviceDao.instance = new DeviceDao();
        return DeviceDao.instance;
    }

    /**
     * 幂等：重复调用与并发调用共用同一个 initPromise，只建一个 store。
     * initPromise 只在失败分支清空（供下次 init() 重试），而清空那一刻 rdbStore 尚未赋值，
     * 所以并发调用不会各建一个 store，重试也不会留着半成品 store。
     * 失败原因另存 initError：initPromise 清空后 ready() 仍能把原始错误交给调用方。
     * 只用应用上下文建库：库路径由传入的上下文决定，UIAbilityContext 会落到 `<bundle>/entry/rdb`——
     * 与 2.8.0 的数据不是一个文件，覆盖安装后旧设备读不到且不报错。
     */
    init(context: Context): void {
        if (this.initPromise) return;

        const appContext: Context = context.getApplicationContext();

        this.initPromise = new Promise<void>((resolve: () => void, reject: (reason: Error) => void) => {
            relationalStore.getRdbStore(appContext, this.STORE_CONFIG).then((store: relationalStore.RdbStore) => {
                store.executeSync(this.SQL_CREATE_TABLE);
                this.rdbStore = store;
                this.initError = null; // 本次初始化成功（含失败后的重试成功）：旧的失败原因不再成立
                resolve();
            }).catch((err: BusinessError) => {
                Logger.error(this.LOG_TAG, `设备库初始化失败, ${err}`);
                const failure = new Error(`设备库初始化失败: ${err.message}`);
                this.initError = failure; // 先留原因再清 initPromise：ready() 在那之后仍拿得到原始错误
                this.initPromise = null; // 允许下次 init() 重试
                reject(failure);
            });
        });

        // 初始化失败由 ready() 的调用方拿到；这里防止未处理的 rejection 打断进程
        this.initPromise.catch((err: Error) => {
            Logger.warn(this.LOG_TAG, `设备库初始化失败（已记录）: ${err.message}`);
        });
    }

    /**
     * 三种拒绝各自可区分：初始化仍在进行 ⇒ 交回那次 init 的 promise；
     * 初始化失败（initPromise 已清空、失败原因仍在）⇒ 原样拒绝失败原因，文案带原始错误信息；
     * 从未 init ⇒ 「未初始化」。把前两者合成一句，调用方就分不出是没 init 还是 init 失败。
     */
    ready(): Promise<void> {
        const pending = this.initPromise;
        if (pending) return pending;

        const failure = this.initError;
        if (failure) return Promise.reject(failure);

        return Promise.reject(new Error('设备库未初始化，先执行 init()'));
    }

    async getAll(): Promise<Device[]> {
        await this.ready();

        if (!this.rdbStore) throw new Error('设备库实例不存在');

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        const queryResult = await this.rdbStore.query(predicates, this.COLUMNS);

        try {
            const devices: Array<Device> = [];

            while (queryResult.goToNextRow()) {
                devices.push(this.readRow(queryResult));
            }

            devices.sort((a: Device, b: Device) => a.OrderIndex - b.OrderIndex);
            Logger.debug(this.LOG_TAG, `查询到设备数: ${devices.length}`);
            return devices;
        } finally {
            try {
                queryResult.close();
            } catch (closeErr) {
                Logger.warn(this.LOG_TAG, `关闭查询结果失败, ${closeErr}`);
            }
        }
    }

    async getByID(id: number): Promise<Device | null> {
        await this.ready();

        if (!this.rdbStore) throw new Error('设备库实例不存在');

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo(this.KEY_ID, id);

        const queryResult = await this.rdbStore.query(predicates, this.COLUMNS);

        try {
            if (queryResult.goToNextRow()) {
                return this.readRow(queryResult);
            }
            return null;
        } finally {
            try {
                queryResult.close();
            } catch (closeErr) {
                Logger.warn(this.LOG_TAG, `关闭查询结果失败, ${closeErr}`);
            }
        }
    }

    /** 返回新行 ID */
    async insert(record: NewDeviceRecord): Promise<number> {
        await this.ready();

        if (!this.rdbStore) throw new Error('设备库实例不存在');

        const valueBucket: relationalStore.ValuesBucket = {
            'MAC': record.mac,
            'ALIAS': record.alias,
            'ADDRESS': record.address,
            'PORT': record.port,
            'ORDERINDEX': record.orderIndex
        };

        const id = await this.rdbStore.insert(this.TABLE_NAME, valueBucket);
        Logger.debug(this.LOG_TAG, `已写入设备, ID: ${id}`);
        return id;
    }

    async update(device: Device): Promise<boolean> {
        await this.ready();

        if (!this.rdbStore) throw new Error('设备库实例不存在');

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo(this.KEY_ID, device.ID);

        const valueBucket: relationalStore.ValuesBucket = {
            'MAC': device.MAC,
            'ALIAS': device.Alias,
            'ADDRESS': device.Address,
            'PORT': device.Port,
            'ORDERINDEX': device.OrderIndex
        };

        const changed = await this.rdbStore.update(valueBucket, predicates);
        Logger.debug(this.LOG_TAG, `更新设备, ID: ${device.ID}, 影响行数: ${changed}`);
        return changed > 0;
    }

    async delete(id: number): Promise<boolean> {
        await this.ready();

        if (!this.rdbStore) throw new Error('设备库实例不存在');

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo(this.KEY_ID, id);

        const changed = await this.rdbStore.delete(predicates);
        Logger.debug(this.LOG_TAG, `删除设备, ID: ${id}, 影响行数: ${changed}`);
        return changed > 0;
    }

    async clear(): Promise<boolean> {
        await this.ready();

        if (!this.rdbStore) throw new Error('设备库实例不存在');

        await this.rdbStore.executeSql(this.SQL_DELETE_TABLE);
        Logger.debug(this.LOG_TAG, '已清空设备表');
        return true;
    }

    /** 单事务整体回写排序；失败回滚并返回 false */
    async updateOrderIndices(pairs: OrderIndexPair[]): Promise<boolean> {
        await this.ready();

        if (!this.rdbStore) throw new Error('设备库实例不存在');

        try {
            this.rdbStore.beginTransaction();

            for (const pair of pairs) {
                const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
                predicates.equalTo(this.KEY_ID, pair.id);

                const valueBucket: relationalStore.ValuesBucket = {
                    'ORDERINDEX': pair.orderIndex
                };

                await this.rdbStore.update(valueBucket, predicates);
            }

            this.rdbStore.commit();
            Logger.info(this.LOG_TAG, `排序回写成功，共 ${pairs.length} 条`);
            return true;
        } catch (err) {
            try {
                this.rdbStore.rollBack();
            } catch (rollbackErr) {
                Logger.error(this.LOG_TAG, `回滚事务失败: ${rollbackErr}`);
            }
            Logger.error(this.LOG_TAG, `排序回写失败: ${err}`);
            return false;
        }
    }

    private readRow(queryResult: relationalStore.ResultSet): Device {
        const id = queryResult.getLong(queryResult.getColumnIndex(this.KEY_ID));
        const mac = queryResult.getString(queryResult.getColumnIndex(this.KEY_MAC));
        const alias = queryResult.getString(queryResult.getColumnIndex(this.KEY_ALIAS));
        const address = queryResult.getString(queryResult.getColumnIndex(this.KEY_ADDRESS));
        const storedPort = queryResult.getLong(queryResult.getColumnIndex(this.KEY_PORT));
        const orderIndex = queryResult.getLong(queryResult.getColumnIndex(this.KEY_ORDERINDEX));

        // 2.8.0 的编辑页把端口留空存成 0；0 不是合法端口，读侧按 PortInput 的存量归一口径取默认值，
        // 存量记录才能再保存（规则归 PortInput 所有，导入行走同一条）
        const port = PortInput.normalizeStored(storedPort);

        return new Device(id, mac, alias, address, port, orderIndex);
    }
}