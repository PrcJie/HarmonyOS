import { AddressItem, Location } from '../viewmodel/AddressItem';
import { PostionItem } from '../viewmodel/PositonItem';
import { CommonConstants as Const } from '../common/constants/CommonConstants';
import MapModel, { PositionList } from '../viewmodel/MapModel';
import MapController from '../controller/MapController';

@Component
export struct Map {
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All });
  private panStartX: number = 0;
  private panStartY: number = 0;
  @State screenMapWidth: number = 0;
  @State screenMapHeight: number = 0;
  @State mapWidth: number = 0;
  @State mapHeight: number = 0;
  @State mapX: number = 0;
  @State mapY: number = 0;
  @Provide data: AddressItem = new AddressItem();

  aboutToAppear(): void {
    MapController.setPinchCount(0);
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
    this.mapWidth = Const.MAP_WIDTH * scale;
    this.mapHeight = Const.MAP_HEIGHT * scale;
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
    MapController.initLeftTop(this.screenMapWidth, this.mapWidth);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        Stack({ alignContent: Alignment.TopStart }) {
          ForEach(this.data.location, (item: Location) => {
            Image(this.data.icon ?? $r('app.media.ic_location_train'))
              .width(Const.MAP_LANDMARKS_SIZE)
              .height(Const.MAP_LANDMARKS_SIZE)
              .objectFit(ImageFit.Contain)
              .offset({ x: item.positionX, y: item.positionY })
            Text(this.data.name ?? '')
              .fontSize($r('app.float.map_text_size'))
              .fontColor(this.data.textColor ?? $r('app.color.font_color_black'))
              .fontWeight(FontWeight.Bold)
              .offset({
                x: item.positionX + Const.MAP_TEXT_OFFSET_X,
                y: item.positionY + Const.MAP_TEXT_OFFSET_Y
              })
          }, (item: Location, index: number) =>
            index.toString() + '_' + item.originalPositionX.toString() + '_' +
              item.originalPositionY.toString() + '_' + this.data.name?.id.toString())
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
          })
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
