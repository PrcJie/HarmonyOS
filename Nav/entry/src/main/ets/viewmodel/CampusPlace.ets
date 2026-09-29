import { Campus } from '../common/Campus';

export interface CampusPlace {
  id: number;
  name: string;
  description: string;
  mapX: number;
  mapY: number;
  icon: Resource;
  zoneId?: number;
  latitude?: number;
  longitude?: number;
}

// 点位对应校方平面图上的建筑与出入口，mapX/mapY 的单位是原图像素。
// 中心与北门使用已知 GCJ-02 坐标；其他经纬度按校区轮廓和示意图估算，待实地核准。
export const campusPlaces: Array<CampusPlace> = [
  {
    id: 0,
    name: '校区中心',
    description: Campus.ADDRESS,
    mapX: 546,
    mapY: 843,
    icon: $rawfile('ic_building.png'),
    latitude: Campus.LATITUDE,
    longitude: Campus.LONGITUDE
  },
  {
    id: 1,
    name: '北门',
    description: '陕鼓大道方向',
    mapX: 565,
    mapY: 270,
    icon: $rawfile('ic_home.png'),
    zoneId: 0,
    latitude: Campus.NORTH_GATE_LATITUDE,
    longitude: Campus.NORTH_GATE_LONGITUDE
  },
  {
    id: 2,
    name: '东门',
    description: '校园东侧出入口',
    mapX: 864,
    mapY: 704,
    icon: $rawfile('ic_home.png'),
    latitude: 34.3659,
    longitude: 109.1894
  },
  {
    id: 3,
    name: '东南门',
    description: '校园东南侧出入口',
    mapX: 847,
    mapY: 1344,
    icon: $rawfile('ic_home.png'),
    latitude: 34.3611,
    longitude: 109.1894
  },
  {
    id: 4,
    name: '图书馆',
    description: '校园平面图上的图书馆区域',
    mapX: 558,
    mapY: 722,
    icon: $rawfile('ic_library.png'),
    zoneId: 1,
    latitude: 34.3658,
    longitude: 109.1864
  },
  {
    id: 5,
    name: '运动场',
    description: '校园东侧运动场',
    mapX: 804,
    mapY: 1125,
    icon: $rawfile('ic_gymnasium.png'),
    latitude: 34.3627,
    longitude: 109.1884
  },
  {
    id: 6,
    name: '大学生活动中心',
    description: '校园东侧活动空间',
    mapX: 710,
    mapY: 918,
    icon: $rawfile('ic_building.png'),
    zoneId: 2,
    latitude: 34.3643,
    longitude: 109.1876
  }
];
