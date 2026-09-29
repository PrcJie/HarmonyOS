import router from '@ohos.router';
import { Map } from '../view/MapView';

interface MapRouteParams {
  placeId?: number;
}

@Entry
@Component
struct ZoneMapPage {
  @State private placeId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as MapRouteParams;
    if (params && typeof params.placeId === 'number') {
      this.placeId = params.placeId;
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹')
          .fontSize(30)
          .fontColor(Color.White)
          .width(42)
          .textAlign(TextAlign.Center)
          .onClick(() => router.back())

        Text('地图位置')
          .fontSize(19)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#165A82')

      Map({ initialPlaceId: this.placeId })
        .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
