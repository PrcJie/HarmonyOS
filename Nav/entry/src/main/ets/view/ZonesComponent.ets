import router from '@ohos.router';
import { CampusZone, campusZones } from '../viewmodel/CampusZone';

@Component
export struct Zones {
  private zones: CampusZone[] = campusZones;
  private changedIndex: boolean = false;
  @State private aheadIndex: number = 0;
  @State private dragOffsetY: number = 0;

  private cardPosition(index: number): number {
    const count = this.zones.length;
    const distance = this.aheadIndex - index;
    if (Math.abs(distance) <= Math.floor(count / 2)) {
      return distance;
    }
    return distance > 0 ? distance - count : distance + count;
  }

  private cardOffsetY(index: number): number {
    const position = this.cardPosition(index);
    return -position * 98 + this.dragOffsetY / (Math.abs(position) + 1);
  }

  private changeCard(up: boolean): void {
    const count = this.zones.length;
    if (count === 0) {
      return;
    }
    animateTo({ duration: 300 }, () => {
      this.aheadIndex = (this.aheadIndex + (up ? 1 : count - 1)) % count;
      this.dragOffsetY = 0;
    });
  }

  private openZone(id: number): void {
    router.pushUrl({ url: 'pages/ZoneDetailPage', params: { id: id } })
      .catch((error: Error) => {
        console.error(`无法打开区域详情：${error.message}`);
      });
  }

  build() {
    Column() {
      Text('区域导览')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#123C57')
        .width('100%')

      Text('上下滑动切换地点，点击卡片查看详情')
        .fontSize(13)
        .fontColor('#667785')
        .width('100%')
        .margin({ top: 6 })

      Stack({ alignContent: Alignment.Center }) {
        ForEach(this.zones, (zone: CampusZone, index: number) => {
          Stack({ alignContent: Alignment.Bottom }) {
            Image(zone.photo)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)

            Column() {
              Text(zone.category)
                .fontSize(12)
                .fontColor('#DFECF3')
              Text(zone.name)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .margin({ top: 4 })
              Text(zone.subtitle)
                .fontSize(13)
                .fontColor(Color.White)
                .margin({ top: 4 })
            }
            .width('100%')
            .padding({ top: 12, bottom: 16, left: 18, right: 18 })
            .alignItems(HorizontalAlign.Start)
            .backgroundColor('#B3123C57')
          }
          .width(`${86 - 10 * Math.abs(this.cardPosition(index))}%`)
          .aspectRatio(6 / 5)
          .borderRadius(16)
          .clip(true)
          .shadow({ radius: 22, color: '#330D2B3C', offsetY: 8 })
          .offset({ x: 0, y: this.cardOffsetY(index) })
          .opacity(1 - Math.abs(this.cardPosition(index)) * 0.12)
          .zIndex(3 - Math.abs(this.cardPosition(index)))
          .onClick(() => {
            if (index === this.aheadIndex) {
              this.openZone(zone.id);
            } else {
              this.changeCard(this.cardPosition(index) < 0);
            }
          })
        }, (zone: CampusZone) => zone.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .gesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionStart(() => {
            this.changedIndex = false;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (this.changedIndex) {
              return;
            }
            if (Math.abs(event.offsetY) < 60) {
              this.dragOffsetY = event.offsetY;
              return;
            }
            this.changedIndex = true;
            this.changeCard(event.offsetY < 0);
          })
          .onActionEnd(() => {
            animateTo({ duration: 300 }, () => {
              this.dragOffsetY = 0;
            });
          })
          .onActionCancel(() => {
            this.dragOffsetY = 0;
          })
      )

      Text(`${this.aheadIndex + 1} / ${this.zones.length}`)
        .fontSize(13)
        .fontColor('#667785')
        .margin({ bottom: 18 })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 20, left: 16, right: 16 })
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F2F6F8')
  }
}
