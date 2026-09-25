import ZonesItem from '../viewmodel/ZonesItem';
import ZonesViewModel from '../viewmodel/ZonesViewModel';

@Component
export default struct SwiperListItem {
  private swiperController: SwiperController = new SwiperController();
  private zonesList: ZonesItem[] = ZonesViewModel.getZonesList();
  @Prop imageHeight: number = 100;
  @Prop viewportHeight: number = 640;
  @Link currentZonesId: number;
  @Prop arrowIconOpacity: number = 1;
  @Consume('contentData') contentData: ZonesItem;

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Swiper(this.swiperController) {
        ForEach(this.zonesList, (item: ZonesItem) => {
          Image(item.swiperPic)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }, (item: ZonesItem) => item.id.toString())
      }
      .width('100%')
      .height('100%')
      .index(this.currentZonesId)
      .indicator(true)
      .loop(true)
      .cachedCount(3)
      .onChange((index: number) => {
        this.currentZonesId = index;
        this.contentData = this.zonesList[index];
      })

      Row() {
        Text('‹')
          .fontSize(32)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#66000000')
          .opacity(this.arrowIconOpacity)
          .onClick(() => {
            this.swiperController.showPrevious();
          })
        Blank()
        Text('›')
          .fontSize(32)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('#66000000')
          .opacity(this.arrowIconOpacity)
          .onClick(() => {
            this.swiperController.showNext();
          })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .height(Math.max(1, this.viewportHeight * this.imageHeight / 100))
    .clip(true)
  }
}
