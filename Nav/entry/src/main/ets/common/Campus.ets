export class Campus {
  static readonly NAME: string = '西安工程大学临潼校区';
  static readonly ADDRESS: string = '陕西省西安市临潼区陕鼓大道58号';

  // 高德地图所标注的校区中心和北门位置（GCJ-02）。
  static readonly LATITUDE: number = 34.364901;
  static readonly LONGITUDE: number = 109.186326;
  static readonly NORTH_GATE_LATITUDE: number = 34.369223;
  static readonly NORTH_GATE_LONGITUDE: number = 109.186582;

  // 校方平面图：https://fzghc.xpu.edu.cn/info/1185/2564.htm
  // 平面图是示意图；地标使用图内像素定位。
  static readonly MAP_WIDTH: number = 937;
  static readonly MAP_HEIGHT: number = 1678;
}
