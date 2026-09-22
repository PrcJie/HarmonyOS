import router from '@ohos.router';
import ZonesItem from '../viewmodel/ZonesItem';
import ZonesViewModel from '../viewmodel/ZonesViewModel';
import { CommonConstants } from '../common/constants/CommonConstants';
import BuildListItem from '../view/BuildListItem';
import SubTitleItem from '../view/SubTitleItem';
import SwiperListItem from '../view/SwiperListItem';

interface ZoneRouteParams {
  id?: number;
}

@Entry
@Component
struct ContentPage {
  private zonesList: ZonesItem[] = ZonesViewModel.getZonesList();
  @Provide('contentData') contentData: ZonesItem = ZonesViewModel.getZonesByIndex(0);
  @State currentZonesId: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as ZoneRouteParams;
    if (params && typeof params.id === 'number' && Number.isInteger(params.id)) {
      const index = this.zonesList.findIndex((item: ZonesItem) => item.id === params.id);
      if (index >= 0) {
        this.currentZonesId = index;
        this.contentData = this.zonesList[index];
      }
    }
  }

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 16 }) {
          SwiperListItem({
            imageHeight: 100,
            currentZonesId: $currentZonesId,
            arrowIconOpacity: 1
          })

          SubTitleItem()

          Text(this.contentData.createTime)
            .fontSize(14)
            .fontColor('#66717C')

          ForEach(this.contentData.content, (paragraph: string, index: number) => {
            Text(paragraph)
              .fontSize(16)
              .fontColor('#34404C')
              .lineHeight(26)
          }, (_paragraph: string, index: number) => `${this.contentData.id}-${index}`)

          Text('建筑信息')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C2833')

          BuildListItem({ type: CommonConstants.BUILDING_TEXT })

          Text('地理位置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C2833')

          BuildListItem({ type: CommonConstants.GEOGRAPHY_LIGHT })
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 32 })
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .title(this.contentData.title)
    .titleMode(NavigationTitleMode.Mini)
    .backgroundColor($r('app.color.introduction_page_color'))
  }
}
