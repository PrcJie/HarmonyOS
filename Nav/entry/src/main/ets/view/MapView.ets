import router from '@ohos.router';
import { Campus } from '../common/Campus';
import { CampusPlace, campusPlaces } from '../viewmodel/CampusPlace';

@Component
export struct Map {
  @Prop initialPlaceId: number = 0;
  private panOption: PanGestureOptions = new PanGestureOptions({ fingers: 1, direction: PanDirection.All });
  private panStartX: number = 0;
  private panStartY: number = 0;
  private pinchStartScale: number = 1;

  @State private screenMapWidth: number = 0;
  @State private screenMapHeight: number = 0;
  @State private mapWidth: number = 0;
  @State private mapHeight: number = 0;
  @State private mapX: number = 0;
  @State private mapY: number = 0;
  @State private mapScale: number = 1;
  @State private selectedPlaceIndex: number = 0;
  @State private panelExpanded: boolean = true;
  @State private searchMessage: string = '';

  aboutToAppear(): void {
    if (this.initialPlaceId !== 0) {
      const index = campusPlaces.findIndex((place: CampusPlace) => place.id === this.initialPlaceId);
      this.selectedPlaceIndex = index >= 0 ? index : 0;
    }
  }

  private clampOffset(offset: number, viewport: number, content: number): number {
    return Math.min(0, Math.max(viewport - content, offset));
  }

  private focusPlace(index: number): void {
    const place = campusPlaces[index];
    this.mapX = this.clampOffset(
      this.screenMapWidth / 2 - place.mapX * this.mapWidth / Campus.MAP_WIDTH,
      this.screenMapWidth, this.mapWidth);
    this.mapY = this.clampOffset(
      this.screenMapHeight / 2 - place.mapY * this.mapHeight / Campus.MAP_HEIGHT,
      this.screenMapHeight, this.mapHeight);
  }

  private selectPlace(index: number): void {
    this.selectedPlaceIndex = index;
    this.focusPlace(index);
    this.panelExpanded = false;
    this.searchMessage = '';
  }

  private openSelectedZone(): void {
    const zoneId = campusPlaces[this.selectedPlaceIndex].zoneId;
    if (zoneId === undefined) {
      return;
    }
    router.pushUrl({ url: 'pages/ZoneDetailPage', params: { id: zoneId } })
      .catch((error: Error) => {
        console.error(`无法打开区域详情：${error.message}`);
      });
  }

  private searchPlace(value: string): void {
    const query = value.trim();
    if (query.length === 0) {
      return;
    }
    for (let index = 0; index < campusPlaces.length; index++) {
      if (campusPlaces[index].name.includes(query)) {
        this.selectPlace(index);
        return;
      }
    }
    this.searchMessage = '未找到该地标';
  }

  private updateMapSize(width: number, height: number): void {
    if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0 ||
      (width === this.screenMapWidth && height === this.screenMapHeight)) {
      return;
    }

    const centerX = this.mapWidth > 0 ?
      (this.screenMapWidth / 2 - this.mapX) / this.mapWidth :
      campusPlaces[this.selectedPlaceIndex].mapX / Campus.MAP_WIDTH;
    const centerY = this.mapHeight > 0 ?
      (this.screenMapHeight / 2 - this.mapY) / this.mapHeight :
      campusPlaces[this.selectedPlaceIndex].mapY / Campus.MAP_HEIGHT;
    const fitScale = Math.max(width / Campus.MAP_WIDTH, height / Campus.MAP_HEIGHT);

    this.screenMapWidth = width;
    this.screenMapHeight = height;
    this.mapWidth = Campus.MAP_WIDTH * fitScale * this.mapScale;
    this.mapHeight = Campus.MAP_HEIGHT * fitScale * this.mapScale;
    this.mapX = this.clampOffset(width / 2 - centerX * this.mapWidth, width, this.mapWidth);
    this.mapY = this.clampOffset(height / 2 - centerY * this.mapHeight, height, this.mapHeight);
  }

  private zoomMap(targetScale: number, centerX: number, centerY: number): void {
    if (this.mapWidth <= 0 || this.mapHeight <= 0 || !Number.isFinite(targetScale)) {
      return;
    }
    const nextScale = Math.max(1, Math.min(4, targetScale));
    const factor = nextScale / this.mapScale;
    if (factor === 1) {
      return;
    }
    const focusX = Number.isFinite(centerX) ? centerX : this.screenMapWidth / 2;
    const focusY = Number.isFinite(centerY) ? centerY : this.screenMapHeight / 2;
    this.mapScale = nextScale;
    this.mapWidth *= factor;
    this.mapHeight *= factor;
    this.mapX = this.clampOffset(focusX - (focusX - this.mapX) * factor,
      this.screenMapWidth, this.mapWidth);
    this.mapY = this.clampOffset(focusY - (focusY - this.mapY) * factor,
      this.screenMapHeight, this.mapHeight);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Stack({ alignContent: Alignment.TopStart }) {
          Image($rawfile('campus_map.png'))
            .width(this.mapWidth)
            .height(this.mapHeight)
            .objectFit(ImageFit.Fill)

          ForEach(campusPlaces, (place: CampusPlace, index: number) => {
            Circle()
              .width(index === this.selectedPlaceIndex ? 18 : 12)
              .height(index === this.selectedPlaceIndex ? 18 : 12)
              .fill(index === this.selectedPlaceIndex ? '#D44C2F' : '#1675A6')
              .stroke(Color.White)
              .strokeWidth(2)
              .position({
                x: place.mapX * this.mapWidth / Campus.MAP_WIDTH -
                  (index === this.selectedPlaceIndex ? 9 : 6),
                y: place.mapY * this.mapHeight / Campus.MAP_HEIGHT -
                  (index === this.selectedPlaceIndex ? 9 : 6)
              })
              .onClick(() => this.selectPlace(index))
          }, (place: CampusPlace) => place.id.toString())

          Text(campusPlaces[this.selectedPlaceIndex].name)
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor('#164967')
            .backgroundColor(Color.White)
            .borderRadius(5)
            .padding(4)
            .position({
              x: campusPlaces[this.selectedPlaceIndex].mapX * this.mapWidth / Campus.MAP_WIDTH + 8,
              y: campusPlaces[this.selectedPlaceIndex].mapY * this.mapHeight / Campus.MAP_HEIGHT - 28
            })
        }
        .width(this.mapWidth)
        .height(this.mapHeight)
        .offset({ x: this.mapX, y: this.mapY })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Start)
      .onAreaChange((_oldVal: Area, newVal: Area) => {
        this.updateMapSize(Number(newVal.width), Number(newVal.height));
      })
      .gesture(
        GestureGroup(
          GestureMode.Parallel,
          PanGesture(this.panOption)
            .onActionStart(() => {
              this.panStartX = this.mapX;
              this.panStartY = this.mapY;
            })
            .onActionUpdate((event: GestureEvent) => {
              this.mapX = this.clampOffset(this.panStartX + event.offsetX,
                this.screenMapWidth, this.mapWidth);
              this.mapY = this.clampOffset(this.panStartY + event.offsetY,
                this.screenMapHeight, this.mapHeight);
            }),
          PinchGesture({ fingers: 2 })
            .onActionStart(() => {
              this.pinchStartScale = this.mapScale;
            })
            .onActionUpdate((event: GestureEvent) => {
              if (Number.isFinite(event.scale) && event.scale > 0) {
                this.zoomMap(Math.round(this.pinchStartScale * event.scale * 100) / 100,
                  event.pinchCenterX, event.pinchCenterY);
              }
            }),
          TapGesture({ count: 2, fingers: 1 })
            .onAction((event: GestureEvent) => {
              if (event.fingerList.length > 0) {
                const nextScale = this.mapScale >= 4 ? 1 : Math.min(this.mapScale * 2, 4);
                this.zoomMap(nextScale, event.fingerList[0].localX, event.fingerList[0].localY);
              }
            })
        )
      )

      Column() {
        Row() {
          Column() {
            Text(campusPlaces[this.selectedPlaceIndex].name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            Text(campusPlaces[this.selectedPlaceIndex].description)
              .fontSize(12)
              .fontColor('#667785')
              .margin({ top: 3 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Image(this.panelExpanded ? $rawfile('ic_panel_down.png') : $rawfile('ic_panel_up.png'))
            .width(24)
            .height(24)
            .objectFit(ImageFit.Contain)
        }
        .width('100%')
        .padding(12)
        .onClick(() => {
          this.panelExpanded = !this.panelExpanded;
        })

        if (campusPlaces[this.selectedPlaceIndex].zoneId !== undefined) {
          Button('查看区域介绍')
            .height(36)
            .fontSize(13)
            .backgroundColor('#165A82')
            .margin({ bottom: 8 })
            .onClick(() => this.openSelectedZone())
        }

        if (this.panelExpanded) {
          Search({ placeholder: '搜索校园地标' })
            .width('92%')
            .height(42)
            .onSubmit((value: string) => this.searchPlace(value))

          if (this.searchMessage.length > 0) {
            Text(this.searchMessage)
              .fontSize(12)
              .fontColor('#B8382B')
          }

          Grid() {
            ForEach(campusPlaces, (place: CampusPlace, index: number) => {
              GridItem() {
                Column() {
                  Image(place.icon)
                    .width(29)
                    .height(29)
                    .objectFit(ImageFit.Contain)
                  Text(place.name)
                    .fontSize(12)
                    .margin({ top: 4 })
                }
                .width('100%')
              }
              .onClick(() => this.selectPlace(index))
            }, (place: CampusPlace) => place.id.toString())
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr')
          .height(186)
          .padding(10)
          .width('100%')
        }
      }
      .width('100%')
      .backgroundColor('#F8FBFD')
      .borderRadius({ topLeft: 14, topRight: 14 })
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .onAreaChange((_oldVal: Area, newVal: Area) => {
      this.updateMapSize(Number(newVal.width), Number(newVal.height));
    })
  }
}
