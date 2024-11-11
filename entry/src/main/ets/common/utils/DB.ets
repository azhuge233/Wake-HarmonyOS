import { relationalStore } from '@kit.ArkData';
import Logger from '../utils/Logger';
import { Context } from '@kit.AbilityKit';
import Machine from '../../model/Machine';
import { JSON } from '@kit.ArkTS';

class DB {
    private rdbStore: relationalStore.RdbStore | undefined;
    private LOG_LABEL = '[DB]'
    private STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'LoadTest.db',
        securityLevel: relationalStore.SecurityLevel.S1
    };
    private TABLE_NAME = 'MACHINE';
    private ID_KEY = 'ID';
    private MAC_KEY = 'MAC';
    private ALIAS_KEY = 'ALIAS';
    private SQL_CREATE_TABLE = `CREATE TABLE IF NOT EXISTS ${this.TABLE_NAME} (ID INTEGER PRIMARY KEY AUTOINCREMENT, MAC TEXT NOT NULL, ALIAS TEXT NOT NULL)`;

    initDB(context: Context) {
        relationalStore.getRdbStore(context, this.STORE_CONFIG, (err, store) => {
            if (err) {
                Logger.error(this.LOG_LABEL, `Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
                return;
            }
            Logger.info(this.LOG_LABEL, 'Succeeded in getting RdbStore.');

            store.executeSql(this.SQL_CREATE_TABLE);

            this.rdbStore = store;
        });
    }

    async getMachineList() {
        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);

        const machines: Array<Machine> = [];

        const queryResult = await this.rdbStore?.query(predicates, [this.ID_KEY, this.MAC_KEY, this.ALIAS_KEY]);

        if(queryResult === undefined) return;

        while (!queryResult.isAtLastRow) {
            queryResult.goToNextRow();

            const id = queryResult.getLong(queryResult.getColumnIndex(this.ID_KEY));
            const mac = queryResult.getString(queryResult.getColumnIndex(this.MAC_KEY));
            const alias = queryResult.getString(queryResult.getColumnIndex(this.ALIAS_KEY));

            machines.push(new Machine(id, mac, alias));
        }

        Logger.debug(this.LOG_LABEL, `Query result: ${JSON.stringify(machines)}`);

        return machines;
    }

    addMachine(mac: string, alias: string) {
        Logger.debug(this.LOG_LABEL, `New machine - MAC: ${mac}, Alias: ${alias}`);
        return this.rdbStore?.insert(this.TABLE_NAME, { mac, alias });
    }

    deleteMachineByID(id: number) {
        const predicates = new relationalStore.RdbPredicates(this.TABLE_NAME);
        predicates.equalTo(this.ID_KEY, id);
        return this.rdbStore?.delete(predicates);
    }
}

export default new DB() as DB;