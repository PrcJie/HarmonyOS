import router from '@ohos.router';
import { Campus } from '../common/Campus';
import { CampusZone, campusZones } from '../viewmodel/CampusZone';

interface ZoneRouteParams {
  id?: number;
}

@Entry
@Component
struct ZoneDetailPage {
  private zones: CampusZone[] = campusZones;
  private swiperController: SwiperController = new SwiperController();
  private scroller: Scroller = new Scroller();
  private pinchStartScale: number = 1;
  private panStartX: number = 0;
  private panStartY: number = 0;
  private previewWidth: number = 0;
  private previewHeight: number = 0;
  private previewImageWidth: number = 0;
  private previewImageHeight: number = 0;

  @State private zoneIndex: number = 0;
  @State private previewIndex: number = -1;
  @State private previewScale: number = 1;
  @State private previewX: number = 0;
  @State private previewY: number = 0;

  aboutToAppear(): void {
    const params = router.getParams() as ZoneRouteParams;
    if (params && typeof params.id === 'number') {
      const index = this.zones.findIndex((zone: CampusZone) => zone.id === params.id);
      if (index >= 0) {
        this.zoneIndex = index;
      }
    }
  }

  private openMap(): void {
    router.pushUrl({
      url: 'pages/ZoneMapPage',
      params: { placeId: this.zones[this.zoneIndex].placeId }
    }).catch((error: Error) => {
      console.error(`无法打开地图位置：${error.message}`);
    });
  }

  private resetPreview(): void {
    this.previewScale = 1;
    this.previewX = 0;
    this.previewY = 0;
    this.previewImageWidth = 0;
    this.previewImageHeight = 0;
  }

  private openPreview(index: number): void {
    this.resetPreview();
    this.previewIndex = index;
  }

  private switchPreview(index: number): void {
    this.resetPreview();
    this.previewIndex = index;
  }

  private clampPreviewOffset(): void {
    if (this.previewImageWidth <= 0 || this.previewImageHeight <= 0 ||
      this.previewWidth <= 0 || this.previewHeight <= 0) {
      this.previewX = 0;
      this.previewY = 0;
      return;
    }
    const fit = Math.min(this.previewWidth / this.previewImageWidth,
      this.previewHeight / this.previewImageHeight);
    const displayWidth = this.previewImageWidth * fit;
    const displayHeight = this.previewImageHeight * fit;
    const maxX = Math.max(0, (displayWidth * this.previewScale - this.previewWidth) / 2);
    const maxY = Math.max(0, (displayHeight * this.previewScale - this.previewHeight) / 2);
    this.previewX = Math.max(-maxX, Math.min(maxX, this.previewX));
    this.previewY = Math.max(-maxY, Math.min(maxY, this.previewY));
  }

  @Builder
  private preview() {
    Stack({ alignContent: Alignment.Center }) {
      Image(this.previewIndex === 0 ? this.zones[this.zoneIndex].photo : this.zones[this.zoneIndex].poster)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .scale({ x: this.previewScale, y: this.previewScale })
        .translate({ x: this.previewX, y: this.previewY })
        .onComplete((event) => {
          if (event && event.width > 0 && event.height > 0) {
            this.previewImageWidth = event.width;
            this.previewImageHeight = event.height;
            this.clampPreviewOffset();
          }
        })

      Column() {
        Row() {
          Text(this.zones[this.zoneIndex].name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Blank()
          Text('×')
            .fontSize(32)
            .fontColor(Color.White)
            .width(44)
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.previewIndex = -1;
              this.resetPreview();
            })
        }
        .width('100%')

        Blank()

        Row() {
          Button('‹')
            .fontSize(26)
            .width(48)
            .height(48)
            .backgroundColor('#66555555')
            .onClick(() => this.switchPreview(this.previewIndex === 0 ? 1 : 0))
          Blank()
          Text(`${this.previewIndex + 1} / 2 · 双击或双指缩放`)
            .fontSize(13)
            .fontColor(Color.White)
          Blank()
          Button('›')
            .fontSize(26)
            .width(48)
            .height(48)
            .backgroundColor('#66555555')
            .onClick(() => this.switchPreview(this.previewIndex === 0 ? 1 : 0))
        }
        .width('100%')
      }
      .width('100%')
      .height('100%')
      .padding({ top: 24, bottom: 32, left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0000000')
    .clip(true)
    .gesture(
      GestureGroup(GestureMode.Parallel,
        PinchGesture({ fingers: 2 })
          .onActionStart(() => {
            this.pinchStartScale = this.previewScale;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (Number.isFinite(event.scale) && event.scale > 0) {
              this.previewScale = Math.max(1, Math.min(4, this.pinchStartScale * event.scale));
              this.clampPreviewOffset();
            }
          }),
        PanGesture({ direction: PanDirection.All })
          .onActionStart(() => {
            this.panStartX = this.previewX;
            this.panStartY = this.previewY;
          })
          .onActionUpdate((event: GestureEvent) => {
            this.previewX = this.panStartX + event.offsetX;
            this.previewY = this.panStartY + event.offsetY;
            this.clampPreviewOffset();
          }),
        TapGesture({ count: 2, fingers: 1 })
          .onAction(() => {
            this.previewScale = this.previewScale > 1 ? 1 : 2;
            this.previewX = 0;
            this.previewY = 0;
          })
      )
    )
    .onAreaChange((_oldVal: Area, newVal: Area) => {
      this.previewWidth = Number(newVal.width);
      this.previewHeight = Number(newVal.height);
      this.clampPreviewOffset();
    })
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('‹')
            .fontSize(30)
            .fontColor(Color.White)
            .width(42)
            .textAlign(TextAlign.Center)
            .onClick(() => router.back())

          Text('区域导览')
            .fontSize(19)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width('100%')
        .height(56)
        .backgroundColor('#165A82')

        Scroll(this.scroller) {
          Column() {
            Swiper(this.swiperController) {
              ForEach(this.zones, (zone: CampusZone, index: number) => {
                Stack({ alignContent: Alignment.BottomStart }) {
                  Image(zone.photo)
                    .width('100%')
                    .height('100%')
                    .objectFit(ImageFit.Cover)
                    .onClick(() => {
                      this.zoneIndex = index;
                      this.openPreview(0);
                    })

                  Column() {
                    Text(zone.category)
                      .fontSize(13)
                      .fontColor('#DFECF3')
                    Text(zone.name)
                      .fontSize(26)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(Color.White)
                      .margin({ top: 4 })
                  }
                  .width('100%')
                  .padding({ top: 12, bottom: 18, left: 20, right: 20 })
                  .alignItems(HorizontalAlign.Start)
                  .backgroundColor('#B3123C57')
                }
                .width('100%')
                .height('100%')
              }, (zone: CampusZone) => zone.id.toString())
            }
            .width('100%')
            .height(280)
            .index(this.zoneIndex)
            .loop(true)
            .indicator(true)
            .onChange((index: number) => {
              this.zoneIndex = index;
            })

            Row() {
              Text('‹ 上一处')
                .fontSize(14)
                .fontColor('#165A82')
                .onClick(() => this.swiperController.showPrevious())
              Blank()
              Text(`${this.zoneIndex + 1} / ${this.zones.length}`)
                .fontSize(13)
                .fontColor('#667785')
              Blank()
              Text('下一处 ›')
                .fontSize(14)
                .fontColor('#165A82')
                .onClick(() => this.swiperController.showNext())
            }
            .width('100%')
            .padding({ top: 14, bottom: 14, left: 20, right: 20 })

            Column() {
              Text(this.zones[this.zoneIndex].subtitle)
                .fontSize(17)
                .fontColor('#165A82')

              Text('区域介绍')
                .fontSize(21)
                .fontWeight(FontWeight.Bold)
                .fontColor('#123C57')
                .margin({ top: 30 })

              Text(this.zones[this.zoneIndex].introduction)
                .fontSize(15)
                .fontColor('#344A58')
                .lineHeight(24)
                .margin({ top: 12 })

              Text('导览海报')
                .fontSize(21)
                .fontWeight(FontWeight.Bold)
                .fontColor('#123C57')
                .margin({ top: 32, bottom: 14 })

              Image(this.zones[this.zoneIndex].poster)
                .width('100%')
                .aspectRatio(3 / 5)
                .objectFit(ImageFit.Contain)
                .borderRadius(12)
                .onClick(() => this.openPreview(1))

              Text('点击图片查看大图')
                .fontSize(12)
                .fontColor('#667785')
                .margin({ top: 8 })

              Text('所在位置')
                .fontSize(21)
                .fontWeight(FontWeight.Bold)
                .fontColor('#123C57')
                .margin({ top: 32 })

              Text(this.zones[this.zoneIndex].location)
                .fontSize(15)
                .fontColor('#344A58')
                .margin({ top: 12, bottom: 16 })

              Image($rawfile('campus_map.png'))
                .width('100%')
                .aspectRatio(Campus.MAP_WIDTH / Campus.MAP_HEIGHT)
                .objectFit(ImageFit.Contain)
                .borderRadius(12)
                .backgroundColor(Color.White)
                .onClick(() => this.openMap())

              Button('在地图中查看')
                .height(44)
                .backgroundColor('#165A82')
                .margin({ top: 18 })
                .onClick(() => this.openMap())

              Button('回到顶部')
                .height(42)
                .backgroundColor('#E2EDF3')
                .fontColor('#165A82')
                .margin({ top: 30 })
                .onClick(() => {
                  this.scroller.scrollTo({
                    xOffset: 0,
                    yOffset: 0,
                    animation: { duration: 350, curve: Curve.EaseOut }
                  });
                })
            }
            .width('100%')
            .padding({ top: 18, bottom: 36, left: 20, right: 20 })
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')

      if (this.previewIndex >= 0) {
        this.preview()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F6F8')
  }
}
