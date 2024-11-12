@Component
export default struct TextItem {
    @Link text: string;
    textResource: Resource = $r("app.string.empty");
    placeholderResource: Resource = $r("app.string.empty");

    build() {
        Row() {
            Text(this.textResource)
                .margin({
                    right: '5%'
                })

            TextInput({
                placeholder: this.placeholderResource,
                text: this.text
            })
                .width('80%')
                .placeholderColor("#CCCCCC")
                .type(InputType.Normal)
                .onChange((value: string) => {
                    this.text = value;
                })
        }
        .margin({
            top: '2%',
            bottom: '2%'
        })
    }
}