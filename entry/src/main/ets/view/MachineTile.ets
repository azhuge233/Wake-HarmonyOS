@Component
export default struct MachineTile {
    machineMAC: Resource = $r("app.string.empty");
    machineAlias: Resource = $r("app.string.empty");
    textButtonWake: Resource = $r("app.string.button_wake_label");

    build() {
        Row() {
            Column() {
                Row() {
                    Text(this.machineAlias)
                        .fontColor('#111111')
                        .align(Alignment.Top)
                        .textAlign(TextAlign.Start)
                }
                Row() {
                    Text(this.machineMAC)
                        .fontColor('#888888')
                }
            }
            .width('80%')

            Column() {
                Button(this.textButtonWake)
                    .backgroundColor('#936dc0')
                    .foregroundColor('#a7ff60')
                    .onClick(() => {})
            }
            .width('20%')
        }
    }
}