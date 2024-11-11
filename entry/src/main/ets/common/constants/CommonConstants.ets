import Machine from '../../model/Machine';
import { util } from '@kit.ArkTS';

export default class CommonConstants {
    static readonly MACHINE_DATA: Array<Machine> = [
      new Machine(util.generateRandomUUID(), "12:34:56:78:9A:BC", "Test Machine 1"),
        new Machine(util.generateRandomUUID(), "12:34:56:78:9A:BC", "Test Machine 2"),
        new Machine(util.generateRandomUUID(), "12:34:56:78:9A:BC", "Test Machine 3"),
    ]

    DURATION: number = 2500;

    PreferenceModel_TAG = '[PreferenceModel]';

    STORE_KEY_NAME = 'Wake-Machines';

    PREFERENCES_NAME = 'machines.db';
}