import { AddressItem, Location } from '../viewmodel/AddressItem';
import { PostionItem } from '../viewmodel/PositonItem';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import MapModel, { PositionList } from '../viewmodel/MapModel';
import MapController from '../controller/MapController';

@Component
export struct Map {
  private panOption: PanGestureOptions = new PanGestureOptions({ fingers: 1, direction: PanDirection.All });
  private panStartX: number = 0;
  private panStartY: number = 0;
  private pinchStartScale: number = Const.MAP_MIN_SCALE;
  @State screenMapWidth: number = 0;
  @State screenMapHeight: number = 0;
  @State mapWidth: number = 0;
  @State mapHeight: number = 0;
  @State mapX: number = 0;
  @State mapY: number = 0;
  @State landmarkData: Array<AddressItem> = [];
  @Provide data: AddressItem = new AddressItem();

  aboutToAppear(): void {
    MapController.setMapScale(Const.MAP_MIN_SCALE);
  }

  private zoomMap(targetScale: number, centerX: number, centerY: number): void {
    if (this.mapWidth <= 0 || this.mapHeight <= 0 || !Number.isFinite(targetScale)) {
      return;
    }

    const oldMultiple = MapController.mapMultiples();
    MapController.setMapScale(targetScale);
    const newMultiple = MapController.mapMultiples();
    const scale = newMultiple / oldMultiple;
    if (!Number.isFinite(scale) || scale === 1) {
      return;
    }

    const focusX = Number.isFinite(centerX) ? centerX : this.screenMapWidth / Const.DOUBLE_OR_HALF;
    const focusY = Number.isFinite(centerY) ? centerY : this.screenMapHeight / Const.DOUBLE_OR_HALF;
    this.mapWidth *= scale;
    this.mapHeight *= scale;
    this.mapX = Math.min(0, Math.max(this.screenMapWidth - this.mapWidth,
      focusX - (focusX - this.mapX) * scale));
    this.mapY = Math.min(0, Math.max(this.screenMapHeight - this.mapHeight,
      focusY - (focusY - this.mapY) * scale));
    MapController.calLandmarksPosition(this.data);
    this.landmarkData.forEach((address: AddressItem) => {
      MapController.calLandmarksPosition(address);
    });
    // AddressItem 不是 @Observed，重新赋值数组以刷新所有地标的位置。
    this.landmarkData = this.landmarkData.slice();
  }

  private doubleTapZoom(centerX: number, centerY: number): void {
    const currentScale = MapController.getMapScale();
    const targetScale = currentScale >= Const.MAP_MAX_SCALE ? Const.MAP_MIN_SCALE :
      Math.min(currentScale * Const.MAP_DOUBLE_TAP_SCALE, Const.MAP_MAX_SCALE);
    this.zoomMap(targetScale, centerX, centerY);
  }

  private loadAllLandmarks(): void {
    const landmarks: Array<AddressItem> = [];
    PositionList.forEach((item: PostionItem) => {
      const address = MapModel.calCoordinateByLonAndLat(item.lngLat, item.type,
        this.mapWidth, this.mapHeight);
      MapController.calLandmarksPosition(address);
      landmarks.push(address);
    });
    this.landmarkData = landmarks;
  }

  private updateMapSize(width: number, height: number): void {
    if (!Number.isFinite(width) || !Number.isFinite(height) || width <= 0 || height <= 0 ||
      (width === this.screenMapWidth && height === this.screenMapHeight)) {
      return;
    }

    const oldMapWidth = this.mapWidth;
    const oldMapHeight = this.mapHeight;
    const centerX = oldMapWidth > 0 ?
      (this.screenMapWidth / Const.DOUBLE_OR_HALF - this.mapX) / oldMapWidth : 0.5;
    const centerY = oldMapHeight > 0 ?
      (this.screenMapHeight / Const.DOUBLE_OR_HALF - this.mapY) / oldMapHeight : 0.5;
    this.screenMapWidth = width;
    this.screenMapHeight = height;

    // 保持底图比例，并确保地图覆盖整个可视区域。
    const scale = Math.max(width / Const.MAP_WIDTH, height / Const.MAP_HEIGHT);
    const multiples = MapController.mapMultiples();
    this.mapWidth = Const.MAP_WIDTH * scale * multiples;
    this.mapHeight = Const.MAP_HEIGHT * scale * multiples;
    this.mapX = Math.min(0, Math.max(width - this.mapWidth,
      width / Const.DOUBLE_OR_HALF - centerX * this.mapWidth));
    this.mapY = Math.min(0, Math.max(height - this.mapHeight,
      height / Const.DOUBLE_OR_HALF - centerY * this.mapHeight));

    // 横竖屏或窗口尺寸改变时，地标也使用新的地图尺寸。
    if (oldMapWidth > 0 && oldMapHeight > 0 && this.data.location.length > 0) {
      const resizedData = new AddressItem();
      resizedData.name = this.data.name;
      resizedData.icon = this.data.icon;
      resizedData.textColor = this.data.textColor;
      resizedData.location = this.data.location.map((item: Location) => new Location(
        item.originalPositionX * this.mapWidth / oldMapWidth,
        item.originalPositionY * this.mapHeight / oldMapHeight
      ));
      MapController.calLandmarksPosition(resizedData);
      this.data = resizedData;
    }
    this.loadAllLandmarks();
    MapController.initLeftTop(this.screenMapWidth, this.mapWidth);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Stack({ alignContent: Alignment.TopStart }) {
          ForEach(this.landmarkData, (address: AddressItem, addressIndex: number) => {
            ForEach(address.location, (item: Location, locationIndex: number) => {
              Image(address.icon ?? $r('app.media.ic_location_train'))
                .width(Const.MAP_LANDMARKS_SIZE)
                .height(Const.MAP_LANDMARKS_SIZE)
                .objectFit(ImageFit.Contain)
                .offset({ x: item.positionX, y: item.positionY })
              Text(address.name ?? '')
                .fontSize($r('app.float.map_text_size'))
                .fontColor(address.textColor ?? $r('app.color.font_color_black'))
                .fontWeight(FontWeight.Bold)
                .offset({
                  x: item.positionX + Const.MAP_TEXT_OFFSET_X,
                  y: item.positionY + Const.MAP_TEXT_OFFSET_Y
                })
            }, (item: Location, locationIndex: number) =>
              addressIndex.toString() + '_' + locationIndex.toString() + '_' +
                item.originalPositionX.toString() + '_' + item.originalPositionY.toString())
          }, (_address: AddressItem, index: number) => index.toString())
        }
        .width(this.mapWidth)
        .height(this.mapHeight)
        .backgroundImage($r('app.media.ic_nav_map'))
        .backgroundImageSize(ImageSize.Cover)
        .offset({ x: this.mapX, y: this.mapY })
      }
      .height(Const.FULL_PERCENT)
      .width(Const.FULL_PERCENT)
      .justifyContent(FlexAlign.Start)
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
              this.mapX = Math.min(0, Math.max(this.screenMapWidth - this.mapWidth,
                this.panStartX + event.offsetX));
              this.mapY = Math.min(0, Math.max(this.screenMapHeight - this.mapHeight,
                this.panStartY + event.offsetY));
            }),
          PinchGesture({ fingers: Const.MAP_FINGER_COUNT })
            .onActionStart(() => {
              this.pinchStartScale = MapController.getMapScale();
            })
            .onActionUpdate((event: GestureEvent) => {
              if (!Number.isFinite(event.scale) || event.scale <= 0) {
                return;
              }
              const accuracy = Math.pow(10, Const.MAP_SCALE_ACCURACY);
              const targetScale = Math.round(this.pinchStartScale * event.scale * accuracy) / accuracy;
              this.zoomMap(targetScale, event.pinchCenterX, event.pinchCenterY);
            }),
          TapGesture({ count: 2, fingers: 1 })
            .onAction((event: GestureEvent) => {
              if (event.fingerList.length === 0) {
                return;
              }
              const touchPoint = event.fingerList[0];
              this.doubleTapZoom(touchPoint.localX, touchPoint.localY);
            })
        )
      )

      CustomPanel({
        screenMapWidth: this.screenMapWidth,
        screenMapHeight: this.screenMapHeight,
        mapWidth: this.mapWidth,
        mapHeight: this.mapHeight,
        mapX: this.mapX,
        mapY: this.mapY
      })
    }
    .height(Const.FULL_PERCENT)
    .width(Const.FULL_PERCENT)
    .clip(true)
  }
}

@Component
struct PositionGrid {
  positionItem: PostionItem = new PostionItem();

  build() {
    Column() {
      Image(this.positionItem.icon)
        .width($r('app.float.navigation_panel_icon_size'))
        .height($r('app.float.navigation_panel_icon_size'))
        .objectFit(ImageFit.Contain)
        .margin($r('app.float.navigation_panel_icon_margin'))
      Text(this.positionItem.text)
        .fontSize($r('app.float.navigation_icon_text'))
    }
    .width(Const.FULL_PERCENT)
  }
}

@Component
struct CustomPanel {
  private positionList: Array<PostionItem> = PositionList;
  @State panelOpacity: number = Const.PANEL_HIGH_OPACITY;
  @State panelHeight: number = Const.PANEL_FULL_HEIGHT;
  @State isExpanded: boolean = true;
  @State iconOpacity: number = Const.PANEL_HIGH_OPACITY;
  @Consume data: AddressItem;
  @Link screenMapWidth: number;
  @Link screenMapHeight: number;
  @Link mapWidth: number;
  @Link mapHeight: number;
  @Link mapX: number;
  @Link mapY: number;

  private setPanelExpanded(expanded: boolean): void {
    this.isExpanded = expanded;
    this.panelHeight = expanded ? Const.PANEL_FULL_HEIGHT : 0;
    this.panelOpacity = expanded ? Const.PANEL_HIGH_OPACITY : 0;
    // 折叠后保留箭头，用户才能再次展开面板。
    this.iconOpacity = expanded ? Const.PANEL_HIGH_OPACITY : Const.PANEL_LOW_OPACITY;
  }

  private selectPosition(item: PostionItem): void {
    if (this.mapWidth <= 0 || this.mapHeight <= 0 || item.lngLat.length === 0) {
      return;
    }
    const address = MapModel.calCoordinateByLonAndLat(item.lngLat, item.type,
      this.mapWidth, this.mapHeight);
    MapController.calLandmarksPosition(address);
    this.data = address;
    this.setFirstLandmarksCenter();
    this.setPanelExpanded(false);
  }

  private searchPosition(value: string): void {
    const query = value.trim();
    if (query.length === 0) {
      return;
    }
    for (const item of this.positionList) {
      if (MapController.getResourceString(item.text, this.getUIContext()) === query) {
        this.selectPosition(item);
        return;
      }
    }
  }

  private setFirstLandmarksCenter(): void {
    if (this.data.location.length === 0) {
      return;
    }
    const firstLocation = this.data.location[0];
    const multiples = MapController.mapMultiples();
    this.mapX = Math.min(0, Math.max(this.screenMapWidth - this.mapWidth,
      this.screenMapWidth / Const.DOUBLE_OR_HALF - firstLocation.originalPositionX * multiples));
    this.mapY = Math.min(0, Math.max(this.screenMapHeight - this.mapHeight,
      this.screenMapHeight / Const.DOUBLE_OR_HALF - firstLocation.originalPositionY * multiples));
  }

  build() {
    Column() {
      Column() {
        Image(this.isExpanded ? $r('app.media.ic_panel_down') : $r('app.media.ic_panel_up'))
          .height($r('app.float.navigation_icon_down'))
          .objectFit(ImageFit.Contain)
      }
      .width(Const.FULL_PERCENT)
      .opacity(this.iconOpacity)
      .backgroundColor($r('app.color.custom_panel_background'))
      .borderRadius({
        topLeft: $r('app.float.navigation_panel_radius'),
        topRight: $r('app.float.navigation_panel_radius')
      })
      .onClick(() => {
        this.setPanelExpanded(!this.isExpanded);
      })

      Column() {
        Search({ placeholder: Const.PANEL_PLACEHOLDER })
          .height($r('app.float.navigation_search_height'))
          .width(Const.SEARCHBAR_WIDTH)
          .onSubmit((value: string) => {
            this.searchPosition(value);
          })
        Grid() {
          ForEach(this.positionList, (item: PostionItem) => {
            GridItem() {
              PositionGrid({ positionItem: item })
            }
            .onClick(() => {
              this.selectPosition(item);
            })
          }, (item: PostionItem) => item.type.toString())
        }
        .columnsTemplate(Const.GRID_COLUMNS)
        .rowsTemplate('1fr 1fr')
        .columnsGap($r('app.float.navigation_column_gap'))
        .rowsGap($r('app.float.navigation_row_gap'))
        .padding($r('app.float.navigation_grid_padding'))
        .layoutWeight(1)
        .width(Const.FULL_PERCENT)
      }
      .width(Const.FULL_PERCENT)
      .height(this.panelHeight)
      .opacity(this.panelOpacity)
      .enabled(this.isExpanded)
      .clip(true)
      .animation({
        duration: Const.ANIMATION_DURATION,
        curve: Curve.EaseOut,
        iterations: 1,
        playMode: PlayMode.Normal
      })
      .backgroundColor($r('app.color.custom_panel_background'))
    }
    .width(Const.FULL_PERCENT)
  }
}
