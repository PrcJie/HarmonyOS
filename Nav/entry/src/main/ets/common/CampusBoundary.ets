/**
 * 临潼校区轮廓（GCJ-02，纬度在前）。
 * 依据 OpenStreetMap contributors 的 way 272520394 转换，ODbL 1.0。
 * 用作地图显示遮罩；如校方边界有变动，可直接调整这些顶点。
 */
export interface CampusCoordinate {
  latitude: number;
  longitude: number;
}

export const CAMPUS_BOUNDARY: CampusCoordinate[] = [
  { latitude: 34.360507, longitude: 109.189546 },
  { latitude: 34.360130, longitude: 109.184454 },
  { latitude: 34.360462, longitude: 109.184020 },
  { latitude: 34.360724, longitude: 109.183987 },
  { latitude: 34.360766, longitude: 109.183703 },
  { latitude: 34.361015, longitude: 109.183653 },
  { latitude: 34.361030, longitude: 109.183203 },
  { latitude: 34.361333, longitude: 109.183253 },
  { latitude: 34.361334, longitude: 109.182952 },
  { latitude: 34.361956, longitude: 109.182485 },
  { latitude: 34.362894, longitude: 109.182986 },
  { latitude: 34.363848, longitude: 109.182368 },
  { latitude: 34.364538, longitude: 109.182418 },
  { latitude: 34.365490, longitude: 109.183203 },
  { latitude: 34.366263, longitude: 109.183170 },
  { latitude: 34.366262, longitude: 109.183670 },
  { latitude: 34.369383, longitude: 109.183570 },
  { latitude: 34.369462, longitude: 109.185390 },
  { latitude: 34.370130, longitude: 109.189479 },
  { latitude: 34.370034, longitude: 109.189535 }
];
