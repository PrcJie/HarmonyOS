import { AddressItem, Location } from './AddressItem';
import { PostionItem, GeoCoordinates } from './PositonItem';
import { CommonConstants, PositionType } from '../common/constants/CommonConstants';
import { Geography } from '../common/utils/Geography';
import mapController from '../controller/MapController';

export class MapModel {
  private data?: AddressItem;
  private addressArray: Array<AddressItem | undefined> =
    new Array<AddressItem | undefined>(CommonConstants.MAP_LANDMARKS_LENGTH).fill(undefined);

  calCoordinateByLonAndLat(geoCoordinates: Array<GeoCoordinates>, type: number,
    mapWidth: number, mapHeight: number): AddressItem {
    this.data = undefined;
    if (!Number.isInteger(type) || type < PositionType.TRAIN_STATION || type > PositionType.LIBRARY) {
      throw new Error('Invalid landmark type');
    }

    const index = type - 1;
    let addressItem = this.addressArray[index];
    if (!addressItem) {
      addressItem = new AddressItem();
      addressItem.name = mapLandmarksName[index];
      addressItem.icon = mapLandmarksIcon[index];
      addressItem.textColor = mapLandmarksTextColor[index];
      this.addressArray[index] = addressItem;
    }

    addressItem.location = this.initLocationData(geoCoordinates, mapWidth, mapHeight);
    this.data = addressItem;
    return this.data;
  }

  initLocationData(geoCoordinates: Array<GeoCoordinates>, mapWidth: number,
    mapHeight: number): Array<Location> {
    const locations: Array<Location> = [];
    const multiples = mapController.mapMultiples();
    const scaleX = mapWidth / multiples / CommonConstants.MAP_WIDTH;
    const scaleY = mapHeight / multiples / CommonConstants.MAP_HEIGHT;

    geoCoordinates.forEach((item: GeoCoordinates) => {
      const pixelCoordinate = Geography.toPixelCoordinate(item.latitude, item.longitude);
      locations.push(new Location(
        pixelCoordinate.coordinatesX * scaleX,
        pixelCoordinate.coordinatesY * scaleY
      ));
    });
    return locations;
  }
}

export default new MapModel();

// 截图中的两个示例地标。
export const PositionList: Array<PostionItem> = [
  {
    icon: $r('app.media.ic_train_station'),
    text: $r('app.string.train_station'),
    type: PositionType.TRAIN_STATION,
    lngLat: [{ longitude: 113.887914, latitude: 22.876813 }]
  },
  {
    icon: $r('app.media.ic_mother_child'),
    text: $r('app.string.mother_child_room'),
    type: PositionType.MOTHER_CHILD_ROOM,
    lngLat: [{ longitude: 113.887914, latitude: 22.876813 }]
  }
];

// 文本信息。
const mapLandmarksName: Array<Resource> = [
  $r('app.string.train_station'),
  $r('app.string.mother_child_room'),
  $r('app.string.car_road'),
  $r('app.string.cafe'),
  $r('app.string.smoking_area'),
  $r('app.string.convenience_store'),
  $r('app.string.gymnasium'),
  $r('app.string.restaurant'),
  $r('app.string.side_walk'),
  $r('app.string.library')
];

// 文本颜色。
const mapLandmarksTextColor: Array<Resource> = [
  $r('app.color.train_station_color'),
  $r('app.color.mother_child_room_color'),
  $r('app.color.car_road_color'),
  $r('app.color.cafe_color'),
  $r('app.color.smoking_area_color'),
  $r('app.color.convenience_store_color'),
  $r('app.color.gymnasium_color'),
  $r('app.color.restaurant_color'),
  $r('app.color.side_walk_color'),
  $r('app.color.library_color')
];

// 地标图标。
const mapLandmarksIcon: Array<Resource> = [
  $r('app.media.ic_location_train'),
  $r('app.media.ic_location_nursing'),
  $r('app.media.ic_location_driveway'),
  $r('app.media.ic_location_cafe'),
  $r('app.media.ic_location_smoking'),
  $r('app.media.ic_location_shop'),
  $r('app.media.ic_location_gymnasium'),
  $r('app.media.ic_location_restaurant'),
  $r('app.media.ic_location_sidewalk'),
  $r('app.media.ic_location_library')
];
