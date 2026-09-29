export interface CampusZone {
  id: number;
  name: string;
  subtitle: string;
  category: string;
  introduction: string;
  location: string;
  photo: Resource;
  poster: Resource;
  placeId: number;
}

// 区域页只展示已有实景照片的地点；新增地点时在此补充图片与介绍。
export const campusZones: CampusZone[] = [
  {
    id: 0,
    name: '北门',
    subtitle: '从陕鼓大道走进校园',
    category: '校园出入口',
    introduction: '北门是临潼校区北侧的出入口，面向陕鼓大道。从这里可以进入校园。',
    location: '临潼校区北侧 · 陕鼓大道方向',
    photo: $rawfile('xpu_gate_source.png'),
    poster: $rawfile('swiper_gate_zine.png'),
    placeId: 1
  },
  {
    id: 1,
    name: '图书馆',
    subtitle: '走近校园里的阅读空间',
    category: '学习空间',
    introduction: '临潼校区图书馆是校园平面图中标注的地标之一。你可以在地图页查找图书馆，了解它在校园中的位置。',
    location: '临潼校区 · 图书馆区域',
    photo: $rawfile('xpu_library_source.png'),
    poster: $rawfile('swiper_library_zine.png'),
    placeId: 4
  },
  {
    id: 2,
    name: '大学生活动中心',
    subtitle: '看见校园活动的空间',
    category: '校园生活',
    introduction: '大学生活动中心位于临潼校区内。区域页展示其建筑实景，方便你在校园中辨认这处地标。',
    location: '西安工程大学临潼校区内',
    photo: $rawfile('xpu_activity_center_source.png'),
    poster: $rawfile('swiper_activity_zine.png'),
    placeId: 6
  }
];
