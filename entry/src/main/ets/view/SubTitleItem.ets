import ZonesItem from '../viewmodel/ZonesItem';

@Component
export default struct SubTitleItem {
  @Consume('contentData') contentData: ZonesItem;

  build() {
    Column() {
      Column() {
        Text(this.contentData.title)
          .fontSize(24)
          .fontColor('#FFFFFF')
          .height(32)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 16 })

        Text(this.contentData.subTitle)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .height(19)
          .opacity(0.6)
          .margin({ top: 2, bottom: 12 })

        Image(this.contentData.starLinePic[0])
          .height(20)
          .width(309)
          .margin({ bottom: 12 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Image(this.contentData.subPicTop)
        .height(214)
        .width('100%')
        .objectFit(ImageFit.Fill)
    }
    .width('100%')
    .backgroundColor(this.contentData.backgroundColor)
  }
}
