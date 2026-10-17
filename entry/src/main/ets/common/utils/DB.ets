import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

import { Logger } from '../utils/Logger';
import { Device } from '../../model/Device';


export class DB {
    private static instance: DB | null = null;

    private isInitialized: boolean = false; // 初始化标志
    private initPromise: Promise<void> | null = null;
    private resolveInit: (() => void) | null = null;

    private rdbStore: relationalStore.RdbStore | undefined;

    private LOG_TAG = '[DB]'

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

    private SQL_CREATE_TABLE = `CREATE TABLE IF NOT EXISTS ${this.TABLE_NAME} (
        ${this.KEY_ID} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${this.KEY_MAC} TEXT NOT NULL,
        ${this.KEY_ALIAS} TEXT NOT NULL,
        ${this.KEY_ADDRESS} TEXT NOT NULL,
        ${this.KEY_PORT} INTEGER DEFAULT 9,
        ${this.KEY_ORDERINDEX} INTEGER DEFAULT 0
    )`;
    private SQL_DELETE_TABLE = `DELETE FROM ${this.TABLE_NAME}`;

    private constructor() { }

    public static getInstance(): DB {
        if (!DB.instance) DB.instance = new DB();
        return DB.instance;
    }

    public init(context: Context) {
        if (this.initPromise) return;

        this.initPromise = new Promise((resolve) => {
            this.resolveInit = resolve;

            // 异步初始化数据库
            relationalStore.getRdbStore(context, this.STORE_CONFIG).then((store) => {
                store.executeSync(this.SQL_CREATE_TABLE);

                this.rdbStore = store;
                this.isInitialized = true;
                resolve(); // 解析Promise表示初始化完成
            }).catch((err: BusinessError) => {
                Logger.error(this.LOG_TAG, `数据库初始化失败, ${err}`);
                this.initPromise = null;
                resolve(); // 允许下次 init() 重试
            });
        });
    }

    async getDevices() {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("数据库实例不存在");

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);

        try {
            const queryResult = await this.rdbStore.query(predicates, [
                this.KEY_ID,
                this.KEY_MAC,
                this.KEY_ALIAS,
                this.KEY_ADDRESS,
                this.KEY_PORT,
                this.KEY_ORDERINDEX
            ]);

            try {
                if(queryResult === undefined) throw new Error("查询为空");

                Logger.debug(this.LOG_TAG, `查询结果，行数: ${queryResult.rowCount}, 列数: ${queryResult.columnCount}`)

                const devices: Array<Device> = [];

                while (queryResult.goToNextRow()) {
                    const id = queryResult.getLong(queryResult.getColumnIndex(this.KEY_ID));
                    const mac = queryResult.getString(queryResult.getColumnIndex(this.KEY_MAC));
                    const alias = queryResult.getString(queryResult.getColumnIndex(this.KEY_ALIAS));
                    const addr = queryResult.getString(queryResult.getColumnIndex(this.KEY_ADDRESS));
                    const port = queryResult.getLong(queryResult.getColumnIndex(this.KEY_PORT));
                    const orderIndex = queryResult.getLong(queryResult.getColumnIndex(this.KEY_ORDERINDEX));

                    devices.push(new Device(id, mac, alias, addr, port, orderIndex));
                }

                devices.sort((a, b) => a.OrderIndex - b.OrderIndex);

                Logger.debug(this.LOG_TAG, `设备列表长度: ${devices.length}`);

                return devices;
            } finally {
                try {
                    queryResult.close();
                } catch (closeErr) {
                    Logger.warn(this.LOG_TAG, `关闭查询结果失败, ${closeErr}`);
                }
            }
        } catch (err) {
            throw new Error(`获取设备列表失败, ${err}`);
        }
    }

    async addDevice(device: Device) {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("数据库实例不存在");

        try {
            const valueBucket: relationalStore.ValuesBucket = {
                "MAC": device.MAC,
                "ALIAS": device.Alias,
                "ADDRESS": device.Address,
                "PORT": device.Port,
                "ORDERINDEX": device.OrderIndex
            };

            Logger.debug(this.LOG_TAG,
                `添加新设备 -
                    MAC: ${device.MAC},
                    Alias: ${device.Alias},
                    Address: ${device.Address},
                    Port: ${device.Port},
                    OrderIndex: ${device.OrderIndex}`
            );

            const result = await this.rdbStore.insert(this.TABLE_NAME, valueBucket);
            return result;
        } catch (err) {
            throw new Error(err);
        }
    }

    async updateDeviceByID(device: Device) {
        await this.waitForReady();

        if(!this.rdbStore) throw new Error("数据库实例不存在");

        Logger.debug(this.LOG_TAG, `更新设备 -
            ID: ${device.ID},
            MAC: ${device.MAC},
            Alias: ${device.Alias},
            Address: ${device.Address},
            Port: ${device.Port},
            OrderIndex: ${device.OrderIndex}`
        );

        try {
            let predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
            predicates.equalTo(this.KEY_ID, device.ID);

            const valueBucket: relationalStore.ValuesBucket = {
                "MAC": device.MAC,
                "ALIAS": device.Alias,
                "ADDRESS": device.Address,
                "PORT": device.Port,
                "ORDERINDEX": device.OrderIndex,
            };

            const result = await this.rdbStore.update(valueBucket, predicates);

            return result;
        } catch (err) {
            throw new Error(err);
        }
    }

    async deleteDeviceByID(device: Device) {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("数据库实例不存在");

        const id = device.ID;

        Logger.debug(this.LOG_TAG, `删除设备, ID: ${id}`);

        let predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo(this.KEY_ID, id);

        try {
            const result = await this.rdbStore.delete(predicates);

            return result;
        } catch (err) {
            throw new Error(err);
        }
    }

    async batchUpdateOrderIndices(orderUpdates: Array<Array<number>>): Promise<boolean> {
        await this.waitForReady();

        if (!this.rdbStore) {
            Logger.error(this.LOG_TAG, "数据库实例不存在");
            return false;
        }

        try {
            // 开始事务
            this.rdbStore.beginTransaction();

            for (const update of orderUpdates) {
                const id = update[0];
                const orderIndex = update[1];

                const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
                predicates.equalTo(this.KEY_ID, id);

                const valueBucket: relationalStore.ValuesBucket = {
                    "ORDERINDEX": orderIndex // 只更新排序字段
                };

                await this.rdbStore.update(valueBucket, predicates);
                // Logger.debug(this.LOG_TAG, `已更新条目 ID：${id} 的排序索引为：${orderIndex}`);
            }

            // 提交事务
            this.rdbStore.commit();
            Logger.info(this.LOG_TAG, `批量排序更新成功，共处理 ${orderUpdates.length} 个条目。`);
            return true;
        } catch (err) {
            // 回滚事务；回滚本身失败时不能掩盖原始错误
            try {
                this.rdbStore.rollBack();
            } catch (rollbackErr) {
                Logger.error(this.LOG_TAG, `回滚事务失败: ${rollbackErr}`);
            }
            Logger.error(this.LOG_TAG, `批量更新排序索引失败: ${err}`);
            return false;
        }
    }

    async clearTable() {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("数据库实例不存在");

        try {
            await this.rdbStore.executeSql(this.SQL_DELETE_TABLE);
            Logger.debug(this.LOG_TAG, "成功清除表");
        } catch (err) {
            Logger.error(this.LOG_TAG, `清除表失败, 代码: ${err.code}, 错误信息: ${err.message}`);
            throw new Error("清除表失败");
        }
    }

    async getDeviceByID(deviceID: number): Promise<Device | null> {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("数据库实例不存在");

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo(this.KEY_ID, deviceID);

        try {
            const queryResult = await this.rdbStore.query(predicates, [
                this.KEY_ID,
                this.KEY_ALIAS,
                this.KEY_MAC,
                this.KEY_ADDRESS,
                this.KEY_PORT,
                this.KEY_ORDERINDEX
            ]);

            try {
                if(queryResult.goToNextRow()) {
                    const id = queryResult.getLong(queryResult.getColumnIndex(this.KEY_ID));
                    const alias = queryResult.getString(queryResult.getColumnIndex(this.KEY_ALIAS));
                    const mac = queryResult.getString(queryResult.getColumnIndex(this.KEY_MAC));
                    const ip = queryResult.getString(queryResult.getColumnIndex(this.KEY_ADDRESS));
                    const port = queryResult.getLong(queryResult.getColumnIndex(this.KEY_PORT));
                    const orderIndex = queryResult.getLong(queryResult.getColumnIndex(this.KEY_ORDERINDEX));

                    const device = new Device(id, mac, alias, ip, port, orderIndex);

                    Logger.debug(this.LOG_TAG, `查询到 ${JSON.stringify(device)}`);

                    return device;
                }

                Logger.debug(this.LOG_TAG, `没有查询到 ID = ${deviceID} 的结果`)
                return null;
            } finally {
                try {
                    queryResult.close();
                } catch (closeErr) {
                    Logger.warn(this.LOG_TAG, `关闭查询结果失败, ${closeErr}`);
                }
            }
        } catch (err) {
            Logger.error(this.LOG_TAG, `getDeviceByID() 执行失败, ${err}`);
            return null;
        }
    }

    private async waitForReady(): Promise<void> {
        if (!this.initPromise) throw new Error("数据库未初始化，先执行 init()");
        await this.initPromise;
    }
}