import { AddressItem, Location } from './AddressItem';
import { PostionItem, GeoCoordinates } from './PositonItem';
import { CommonConstants, PositionType } from '../common/constants/CommonConstants';
import { Geography } from '../common/utils/Geography';
import mapController from '../controller/MapController';

export class MapModel {
  calCoordinateByLonAndLat(geoCoordinates: Array<GeoCoordinates>, type: number,
    mapWidth: number, mapHeight: number): AddressItem {
    if (!Number.isInteger(type) || type < PositionType.TRAIN_STATION || type > PositionType.LIBRARY) {
      throw new Error('Invalid landmark type');
    }

    const index = type - 1;
    // 每次选择返回新对象，重复选择同一地标时也能触发界面更新。
    const addressItem = new AddressItem();
    addressItem.name = mapLandmarksName[index];
    addressItem.icon = mapLandmarksIcon[index];
    addressItem.textColor = mapLandmarksTextColor[index];
    addressItem.location = this.initLocationData(geoCoordinates, mapWidth, mapHeight);
    return addressItem;
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

// 完整地标类别及坐标，来源：arkui-x/samples 的 OxHornCampus 示例。
// https://github.com/arkui-x/samples/blob/master/CodeLab/OxHornCampus/features/map/src/main/ets/viewmodel/MapModel.ets
export const PositionList: Array<PostionItem> = [
  {
    icon: $r('app.media.ic_train_station'),
    text: $r('app.string.train_station'),
    type: PositionType.TRAIN_STATION,
    lngLat: [{ longitude: 113.886514, latitude: 22.876813 }]
  },
  {
    icon: $r('app.media.ic_mother_child'),
    text: $r('app.string.mother_child_room'),
    type: PositionType.MOTHER_CHILD_ROOM,
    lngLat: [{ longitude: 113.887914, latitude: 22.876813 }]
  },
  {
    icon: $r('app.media.ic_car_road'),
    text: $r('app.string.car_road'),
    type: PositionType.CAR_ROAD,
    lngLat: [{ longitude: 113.886304, latitude: 22.875713 }]
  },
  {
    icon: $r('app.media.ic_cafe'),
    text: $r('app.string.cafe'),
    type: PositionType.CAFE,
    lngLat: [
      { longitude: 113.886004, latitude: 22.878518 },
      { longitude: 113.889137, latitude: 22.880663 }
    ]
  },
  {
    icon: $r('app.media.ic_smoking_area'),
    text: $r('app.string.smoking_area'),
    type: PositionType.SMOKING_AREA,
    lngLat: [{ longitude: 113.88793, latitude: 22.875979 }]
  },
  {
    icon: $r('app.media.ic_convenience_store'),
    text: $r('app.string.convenience_store'),
    type: PositionType.CONVENIENCE_STORE,
    lngLat: [{ longitude: 113.886104, latitude: 22.878618 }]
  },
  {
    icon: $r('app.media.ic_gymnasium'),
    text: $r('app.string.gymnasium'),
    type: PositionType.GYMNASIUM,
    lngLat: [{ longitude: 113.887592, latitude: 22.876602 }]
  },
  {
    icon: $r('app.media.ic_restaurant'),
    text: $r('app.string.restaurant'),
    type: PositionType.RESTAURANT,
    lngLat: [{ longitude: 113.889261, latitude: 22.880244 }]
  },
  {
    icon: $r('app.media.ic_side_walk'),
    text: $r('app.string.side_walk'),
    type: PositionType.SIDE_WALK,
    lngLat: [{ longitude: 113.886312, latitude: 22.876207 }]
  },
  {
    icon: $r('app.media.ic_library'),
    text: $r('app.string.library'),
    type: PositionType.LIBRARY,
    lngLat: [{ longitude: 113.88689, latitude: 22.876711 }]
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
