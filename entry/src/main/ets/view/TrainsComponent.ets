import { CommonConstants } from '../common/constants/CommonConstants';
import { TrainsLine, TrainsMap } from '../viewmodel/TrainsMap';
import trainsMapModel, { PositionList } from '../viewmodel/TrainsMapModel';
import { TrainsTrack } from './TrainsTrack';

@Component
export struct Trains {
  @State private trainsMapData: TrainsMap[] = PositionList;
  @State private selectedLine: number = -1;
  @State private showLineOne: boolean = false;
  @State private showLineTwo: boolean = false;
  @State private showLineThree: boolean = false;
  @State private currentTime: number = Date.now();
  private refreshTimer: number = -1;

  aboutToAppear(): void {
    this.currentTime = Date.now();
    if (this.refreshTimer !== -1) {
      clearInterval(this.refreshTimer);
    }
    this.refreshTimer = setInterval(() => {
      this.currentTime = Date.now();
    }, 1000);
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

  changeShowMap(line?: number): void {
    if (line === undefined) {
      return;
    }
    switch (line) {
      case TrainsLine.LINE_ONE:
        this.showLineOne = !this.showLineOne;
        break;
      case TrainsLine.LINE_TWO:
        this.showLineTwo = !this.showLineTwo;
        break;
      case TrainsLine.LINE_THREE:
        this.showLineThree = !this.showLineThree;
        break;
      default:
        return;
    }
    if (this.fetchShowMap(line)) {
      this.selectedLine = line;
    } else if (this.showLineOne) {
      this.selectedLine = TrainsLine.LINE_ONE;
    } else if (this.showLineTwo) {
      this.selectedLine = TrainsLine.LINE_TWO;
    } else if (this.showLineThree) {
      this.selectedLine = TrainsLine.LINE_THREE;
    } else {
      this.selectedLine = -1;
    }
  }

  fetchShowMap(line?: number): boolean {
    switch (line) {
      case TrainsLine.LINE_ONE:
        return this.showLineOne;
      case TrainsLine.LINE_TWO:
        return this.showLineTwo;
      case TrainsLine.LINE_THREE:
        return this.showLineThree;
      default:
        return false;
    }
  }

  private startTime(line: number): string {
    if (line === TrainsLine.LINE_TWO) {
      return CommonConstants.LINE_TWO_START_TIME;
    }
    if (line === TrainsLine.LINE_THREE) {
      return this.checkWeekend() ? CommonConstants.LINE_THREE_WEEKEND_POSITION_START_TIME :
        CommonConstants.LINE_THREE_START_TIME;
    }
    return CommonConstants.LINE_ONE_START_TIME;
  }

  private distanceTravelled(line: number): number {
    if (line < 0 || line >= this.trainsMapData.length) {
      return 0;
    }
    const total = trainsMapModel.calDistance(this.trainsMapData[line].lineData);
    return trainsMapModel.travelDistance(total, this.startTime(line), line, this.currentTime);
  }

  private progress(line: number): number {
    const total = trainsMapModel.calDistance(this.trainsMapData[line].lineData);
    return total > 0 ? Math.floor(this.distanceTravelled(line) * 100 / total) : 0;
  }

  build() {
    Navigation() {
      Column({ space: 12 }) {
        Stack() {
          Image(this.selectedLine < 0 ? $r('app.media.ic_train_map') :
            this.trainsMapData[this.selectedLine].imgBg)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)

          if (this.selectedLine >= 0 && this.isOperating(this.selectedLine)) {
            ForEach([this.selectedLine], (line: number) => {
              TrainsTrack({ trainsInfo: this.trainsMapData[line], trainLine: line })
            }, (line: number) => line.toString())
          }
        }
          .width('100%')
          .aspectRatio(1.75)
          .borderRadius(8)
          .clip(true)
          .onClick(() => {
            this.selectedLine = -1;
            this.showLineOne = false;
            this.showLineTwo = false;
            this.showLineThree = false;
          })

        List({ space: 12 }) {
          ForEach(this.trainsMapData, (item: TrainsMap, index: number) => {
            ListItem() {
              Column({ space: 12 }) {
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
                .onClick(() => {
                  this.changeShowMap(index);
                })

                if (this.fetchShowMap(index) && this.isOperating(index)) {
                  Column({ space: 6 }) {
                    Text(`按班次推算的列车位置：已行驶约${this.progress(index)}%`)
                      .fontSize(14)
                      .fontColor('#34404C')
                    Text('地图标记依据发车时间与线路坐标估算')
                      .fontSize(12)
                      .fontColor('#66717C')
                  }
                  .width('100%')
                  .alignItems(HorizontalAlign.Start)
                }
              }
              .width('100%')
              .padding({ top: 17, left: 12, bottom: 18, right: 12 })
              .borderRadius(8)
              .backgroundColor(this.fetchShowMap(index) ? '#E8F2FF' : Color.White)
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
