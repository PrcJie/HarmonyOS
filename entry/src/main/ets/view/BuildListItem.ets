import { CommonConstants } from '../common/constants/CommonConstants';
import ZonesItem from '../viewmodel/ZonesItem';

@Component
export default struct BuildListItem {
  @Prop type: string = '';
  @Consume('contentData') contentData: ZonesItem;

  build() {
    Column() {
      Image(this.contentData.starLinePic[1])
        .height(20)
        .width('87%')
        .margin({ bottom: 30 })

      if (this.type === CommonConstants.BUILDING_TEXT) {
        Text(this.contentData.buildingInformation)
          .width('87%')
          .fontSize(14)
          .fontColor('#34404C')
          .lineHeight(22)
          .margin({ bottom: 24 })
      }

      Column() {
        if (this.type === CommonConstants.BUILDING_TEXT) {
          Image(this.contentData.buildingPic)
            .width('100%')
            .height(240)
            .objectFit(ImageFit.Contain)
            .borderRadius(24)
        } else {
          Image(this.type === CommonConstants.GEOGRAPHY_LIGHT ?
            this.contentData.geographyPicLight : this.contentData.geographyPic)
            .width('100%')
            .height(240)
            .objectFit(ImageFit.Contain)
            .borderRadius(24)
        }
      }
      .width('87%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 20, bottom: 32 })
  }
}
