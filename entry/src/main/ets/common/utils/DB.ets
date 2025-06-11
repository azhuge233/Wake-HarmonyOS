import { relationalStore } from '@kit.ArkData';
import Logger from '../utils/Logger';
import { Context } from '@kit.AbilityKit';
import Machine from '../../model/Machine';
import { JSON } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';

export class DB {
    private static instance: DB | null = null;

    private isInitialized: boolean = false; // 初始化标志
    private initPromise: Promise<void> | null = null;
    private resolveInit: (() => void) | null = null;

    private rdbStore: relationalStore.RdbStore | undefined;

    private LOG_TAG = '[DB]'

    private STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'LoadTest.db',
        securityLevel: relationalStore.SecurityLevel.S1
    };

    private TABLE_NAME = 'MACHINE';
    private ID_KEY = 'ID';
    private MAC_KEY = 'MAC';
    private ALIAS_KEY = 'ALIAS';

    private SQL_CREATE_TABLE = `CREATE TABLE IF NOT EXISTS ${this.TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, MAC TEXT NOT NULL, ALIAS TEXT NOT NULL)`;

    private constructor() { }

    public static getInstance(): DB {
        if (!DB.instance) DB.instance = new DB();
        return DB.instance;
    }

    public initDB(context: Context) {
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
                Logger.error(this.LOG_TAG, "DB initialization failed");
                resolve(); // 即使失败也要resolve，避免永久阻塞
            });
        });
    }

    public async waitForReady(): Promise<void> {
        if (!this.initPromise) throw new Error("DB not initialized. Call initialize() first.");
        await this.initPromise;
    }

    async getMachineList() {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("Database not available");

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);

        const machines: Array<Machine> = [];

        const queryResult = await this.rdbStore.query(predicates, [this.ID_KEY, this.MAC_KEY, this.ALIAS_KEY]);

        if(queryResult === undefined) return;

        while (!queryResult.isAtLastRow) {
            queryResult.goToNextRow();

            const id = queryResult.getLong(queryResult.getColumnIndex(this.ID_KEY));
            const mac = queryResult.getString(queryResult.getColumnIndex(this.MAC_KEY));
            const alias = queryResult.getString(queryResult.getColumnIndex(this.ALIAS_KEY));

            machines.push(new Machine(id, mac, alias));
        }

        Logger.debug(this.LOG_TAG, `Query result: ${JSON.stringify(machines)}`);

        return machines;
    }

    async addMachine(mac: string, alias: string) {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("Database not available");

        Logger.debug(this.LOG_TAG, `New machine - MAC: ${mac}, Alias: ${alias}`);

        return this.rdbStore.insert(this.TABLE_NAME, { mac, alias });
    }

    async deleteMachineByID(id: number) {
        await this.waitForReady();

        if (!this.rdbStore) throw new Error("Database not available");

        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo(this.ID_KEY, id);

        const queryResult = await this.rdbStore?.query(predicates, [this.MAC_KEY, this.ALIAS_KEY]);

        if(queryResult === undefined) return;

        queryResult.goToNextRow();

        const mac = queryResult.getString(queryResult.getColumnIndex(this.MAC_KEY));
        const alias = queryResult.getString(queryResult.getColumnIndex(this.ALIAS_KEY));

        Logger.debug(this.LOG_TAG, `Deleting machine. ID: ${id}, MAC: ${mac}, Alias: ${alias}`);

        return this.rdbStore.delete(predicates);
    }
}