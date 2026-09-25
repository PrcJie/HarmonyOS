import { CommonConstants, TrainsLine } from '../common/constants/CommonConstants';
import { TrainsMap } from '../viewmodel/TrainsMap';
import { PositionList } from '../viewmodel/TrainsMapModel';

@Component
export struct Trains {
  @State private trainsMapData: TrainsMap[] = PositionList;
  @State private selectedLine: number = -1;
  @State private currentTime: number = Date.now();
  private refreshTimer: number = -1;

  aboutToAppear(): void {
    this.currentTime = Date.now();
    this.refreshTimer = setInterval(() => {
      this.currentTime = Date.now();
    }, 60 * 1000);
  }

  aboutToDisappear(): void {
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
      this.refreshTimer = -1;
    }
  }

  isOperating(line: number): boolean {
    switch (line) {
      case TrainsLine.LINE_ONE:
        return this.checkTime(CommonConstants.LINE_ONE_START_TIME, CommonConstants.LINE_ONE_END_TIME);
      case TrainsLine.LINE_TWO:
        return !this.checkWeekend() &&
          this.checkTime(CommonConstants.LINE_TWO_START_TIME, CommonConstants.LINE_TWO_END_TIME);
      case TrainsLine.LINE_THREE:
        return this.checkWeekend() ?
          this.checkTime(CommonConstants.LINE_THREE_WEEKEND_START_TIME,
            CommonConstants.LINE_THREE_WEEKEND_END_TIME) :
          this.checkTime(CommonConstants.LINE_THREE_START_TIME, CommonConstants.LINE_THREE_END_TIME);
      default:
        return false;
    }
  }

  checkTime(startTime: string, endTime: string): boolean {
    const now = new Date(this.currentTime);
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    const startParts = startTime.split(':');
    const endParts = endTime.split(':');
    const startMinutes = Number(startParts[0]) * 60 + Number(startParts[1]);
    const endMinutes = Number(endParts[0]) * 60 + Number(endParts[1]);
    return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
  }

  checkWeekend(): boolean {
    const weekday = new Date(this.currentTime).getDay();
    return weekday === 0 || weekday === 6;
  }

  build() {
    Navigation() {
      Column({ space: 12 }) {
        Image(this.selectedLine < 0 ? $r('app.media.ic_train_map') :
          this.trainsMapData[this.selectedLine].imgBg)
          .width('100%')
          .aspectRatio(1.75)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)
          .onClick(() => {
            this.selectedLine = -1;
          })

        List({ space: 12 }) {
          ForEach(this.trainsMapData, (item: TrainsMap, index: number) => {
            ListItem() {
              Row() {
                Text() {
                  Span(`${index + 1}号线`)
                  Span(this.isOperating(index) ? '（运营中）' : '（非运营）')
                    .fontColor(this.isOperating(index) ? '#35B83C' : '#E90000')
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                }
                .fontSize(16)
                .fontWeight(FontWeight.Medium)

                Text(`约${item.interval}分钟/趟`)
                  .fontColor('#99000000')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)
              .padding({ top: 17, left: 12, bottom: 18, right: 12 })
              .borderRadius(8)
              .backgroundColor(this.selectedLine === index ? '#E8F2FF' : Color.White)
              .onClick(() => {
                this.selectedLine = this.selectedLine === index ? -1 : index;
              })
            }
          }, (_item: TrainsMap, index: number) => index.toString())
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 12, right: 12 })
    }
    .title('园区火车')
    .titleMode(NavigationTitleMode.Full)
    .hideToolBar(true)
    .hideBackButton(true)
    .backgroundColor('#F1F3F5')
  }
}
