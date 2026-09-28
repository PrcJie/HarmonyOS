import { CommonConstants } from '../common/constants/CommonConstants';
import { Position, TrainsLine, TrainsMap } from './TrainsMap';

/**
 * 列车在地图中的实时位置与方向信息
 */
export class TrainPosition {
  /**
   * 当前在地图画布上的 X 轴坐标
   */
  x: number = 0;

  /**
   * 当前在地图画布上的 Y 轴坐标
   */
  y: number = 0;

  /**
   * 当前行驶方向角度（0~360度，以水平向右为 0 度，顺时针方向递增）
   */
  direction: number = 0;

  /** 当前所在的线路段起点索引 */
  segmentIndex: number = 0;
}

/**
 * 园区小火车地图运行轨迹与状态计算模型
 */
export class TrainsMapModel {
  /**
   * 计算列车每经过一个地图坐标单位所需的毫秒数
   *
   * @param distance 线路总长度（坐标单位距离）
   * @param line 线路编号，对应 {@link TrainsLine} 枚举
   * @returns 每移动一个坐标单位所需的毫秒数；若距离无效或未知线路则返回 0
   */
  calDelay(distance: number, line: number): number {
    if (distance <= 0) {
      return 0;
    }
    switch (line) {
      case TrainsLine.LINE_ONE:
        return CommonConstants.LINE_ONE_TIME / distance;
      case TrainsLine.LINE_TWO:
        return CommonConstants.LINE_TWO_TIME / distance;
      case TrainsLine.LINE_THREE:
        return CommonConstants.LINE_THREE_TIME / distance;
      default:
        return 0;
    }
  }

  /**
   * 计算指定线路的总长度
   * 相邻坐标点之间采用切比雪夫距离（即较大轴向距离）计长，与线路图的逐点离散路径一致；
   * 若首尾点不重合，会自动累加首尾闭合段距离形成环线。
   *
   * @param data 线路关键坐标点数组
   * @returns 线路环线总长度
   */
  calDistance(data: Array<Position>): number {
    if (data.length < 2) {
      return 0;
    }
    let distance = 0;
    for (let index = 0; index < data.length - 1; index++) {
      distance += this.segmentDistance(data[index], data[index + 1]);
    }
    if (data[0].x !== data[data.length - 1].x || data[0].y !== data[data.length - 1].y) {
      distance += this.segmentDistance(data[data.length - 1], data[0]);
    }
    return distance;
  }

  /**
   * 根据班次起始时间推算当前时刻本轮列车已走过的累计路径长度
   *
   * @param distance 线路总长度
   * @param startTime 首班发车时间（格式为 "HH:mm"）
   * @param line 线路编号
   * @param nowTime 当前时间戳（毫秒），默认为 Date.now()
   * @returns 当前周期内已走过的路径长度（0 <= 长度 < 线路总长）
   */
  travelDistance(distance: number, startTime: string, line: number, nowTime: number = Date.now()): number {
    const delay = this.calDelay(distance, line);
    if (delay <= 0) {
      return 0;
    }
    const parts = startTime.split(':');
    const now = new Date(nowTime);
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(),
      Number(parts[0]), Number(parts[1]), 0, 0).getTime();
    const elapsed = Math.max(0, nowTime - start);
    const period = distance * delay;
    return distance * ((elapsed % period) / period);
  }

  /**
   * 计算从起点到终点的方向角（以水平向右为 0 度，顺时针方向增大）
   *
   * @param startX 起点 X 坐标
   * @param startY 起点 Y 坐标
   * @param endX 终点 X 坐标
   * @param endY 终点 Y 坐标
   * @returns 行驶方向角度（0~360度）
   */
  fetchDirection(startX: number, startY: number, endX: number, endY: number): number {
    if (startX === endX && startY === endY) {
      return 0;
    }
    const angle = this.calcAngle(startX, startY, endX, endY);
    if (endX >= startX && endY >= startY) {
      return angle;
    }
    if (endX < startX && endY >= startY) {
      return 180 - angle;
    }
    if (endX < startX && endY < startY) {
      return 180 + angle;
    }
    return 360 - angle;
  }

  /**
   * 计算起点与终点连线相对于水平轴的锐角夹角（利用反正切函数）
   *
   * @param startX 起点 X 坐标
   * @param startY 起点 Y 坐标
   * @param endX 终点 X 坐标
   * @param endY 终点 Y 坐标
   * @returns 锐角夹角（度数，范围 0~90）
   */
  calcAngle(startX: number, startY: number, endX: number, endY: number): number {
    const width = Math.abs(endX - startX);
    const height = Math.abs(endY - startY);
    return Math.atan2(height, width) * 180 / Math.PI;
  }

  /**
   * 计算线段在 X 轴方向的位移比率（每单位切比雪夫距离对应的 X 轴增量）
   *
   * @param start 线段起点
   * @param end 线段终点
   * @returns X 轴变化比率（-1 到 1 之间）
   */
  fetchRatioX(start: Position, end: Position): number {
    const distance = this.segmentDistance(start, end);
    return distance === 0 ? 0 : (end.x - start.x) / distance;
  }

  /**
   * 计算线段在 Y 轴方向的位移比率（每单位切比雪夫距离对应的 Y 轴增量）
   *
   * @param start 线段起点
   * @param end 线段终点
   * @returns Y 轴变化比率（-1 到 1 之间）
   */
  fetchRatioY(start: Position, end: Position): number {
    const distance = this.segmentDistance(start, end);
    return distance === 0 ? 0 : (end.y - start.y) / distance;
  }

  /**
   * 沿线路路径进行线性插值，计算当前已行驶距离对应的地图坐标和行驶方向
   *
   * @param data 线路关键点坐标数组
   * @param distance 累计行驶距离
   * @returns 列车当前的位置坐标及方向角度
   */
  positionAtDistance(data: Array<Position>, distance: number): TrainPosition {
    const result = new TrainPosition();
    if (data.length === 0) {
      return result;
    }
    result.x = data[0].x;
    result.y = data[0].y;
    const total = this.calDistance(data);
    if (total <= 0) {
      return result;
    }
    let remaining = ((distance % total) + total) % total;
    const isClosed = data[0].x === data[data.length - 1].x &&
      data[0].y === data[data.length - 1].y;
    const segmentCount = isClosed ? data.length - 1 : data.length;
    for (let index = 0; index < segmentCount; index++) {
      const start = data[index];
      const end = data[(index + 1) % data.length];
      const length = this.segmentDistance(start, end);
      if (length === 0) {
        continue;
      }
      if (remaining <= length) {
        result.x = start.x + this.fetchRatioX(start, end) * remaining;
        result.y = start.y + this.fetchRatioY(start, end) * remaining;
        result.direction = this.fetchDirection(start.x, start.y, end.x, end.y);
        result.segmentIndex = index;
        return result;
      }
      remaining -= length;
    }
    return result;
  }

  /**
   * 计算两相邻坐标点之间的切比雪夫距离（即 X 轴与 Y 轴距离差的较大值）
   *
   * @param start 起点
   * @param end 终点
   * @returns 两点间的距离
   */
  private segmentDistance(start: Position, end: Position): number {
    return Math.max(Math.abs(end.x - start.x), Math.abs(end.y - start.y));
  }
}

/**
 * 园区小火车地图模型单例
 */
const trainsMapModel = new TrainsMapModel();
export default trainsMapModel;

/**
 * 园区火车线路配置列表（包含背景图、发车间隔和沿线站点坐标点数据）
 */
export const PositionList: Array<TrainsMap> = [
  {
    // 1 号线配置
    imgBg: $r('app.media.ic_line1'),
    interval: 10,
    lineData: [
      { x: 318, y: 132 },
      { x: 296, y: 131 },
      { x: 283, y: 129 },
      { x: 275, y: 126 },
      { x: 262, y: 116 },
      { x: 248, y: 111 },
      { x: 235, y: 121 },
      { x: 219, y: 140 },
      { x: 159, y: 194 },
      { x: 134, y: 245 },
      { x: 138, y: 271 },
      { x: 163, y: 284 },
      { x: 258, y: 266 },
      { x: 271, y: 254 },
      { x: 278, y: 237 },
      { x: 284, y: 220 },
      { x: 290, y: 215 },
      { x: 302, y: 215 },
      { x: 340, y: 215 },
      { x: 362, y: 193 },
      { x: 374, y: 164 },
      { x: 357, y: 146 },
      { x: 335, y: 135 },
      { x: 318, y: 132 }
    ]
  },
  {
    // 2 号线配置
    imgBg: $r('app.media.ic_line2'),
    interval: 17,
    lineData: [
      { x: 657, y: 394 },
      { x: 640, y: 391 },
      { x: 557, y: 352 },
      { x: 535, y: 343 },
      { x: 518, y: 341 },
      { x: 503, y: 331 },
      { x: 502, y: 321 },
      { x: 507, y: 312 },
      { x: 531, y: 294 },
      { x: 548, y: 288 },
      { x: 564, y: 281 },
      { x: 565, y: 273 },
      { x: 485, y: 210 },
      { x: 466, y: 185 },
      { x: 457, y: 177 },
      { x: 444, y: 174 },
      { x: 409, y: 170 },
      { x: 374, y: 164 },
      { x: 357, y: 146 },
      { x: 335, y: 135 },
      { x: 318, y: 132 },
      { x: 296, y: 131 },
      { x: 283, y: 129 },
      { x: 275, y: 126 },
      { x: 262, y: 116 },
      { x: 248, y: 111 },
      { x: 235, y: 121 },
      { x: 219, y: 140 },
      { x: 159, y: 194 },
      { x: 134, y: 245 },
      { x: 138, y: 271 },
      { x: 163, y: 284 },
      { x: 258, y: 266 },
      { x: 271, y: 254 },
      { x: 278, y: 237 },
      { x: 284, y: 220 },
      { x: 290, y: 215 },
      { x: 302, y: 215 },
      { x: 340, y: 215 },
      { x: 362, y: 193 },
      { x: 374, y: 178 },
      { x: 409, y: 170 },
      { x: 444, y: 174 },
      { x: 457, y: 177 },
      { x: 466, y: 185 },
      { x: 485, y: 210 },
      { x: 565, y: 273 },
      { x: 564, y: 281 },
      { x: 570, y: 290 },
      { x: 584, y: 296 },
      { x: 617, y: 320 },
      { x: 643, y: 328 },
      { x: 667, y: 329 },
      { x: 682, y: 329 },
      { x: 695, y: 337 },
      { x: 706, y: 350 },
      { x: 708, y: 360 },
      { x: 704, y: 369 },
      { x: 678, y: 390 },
      { x: 657, y: 394 }
    ]
  },
  {
    // 3 号线配置
    imgBg: $r('app.media.ic_line3'),
    interval: 37,
    lineData: [
      { x: 248, y: 111 },
      { x: 235, y: 121 },
      { x: 219, y: 140 },
      { x: 159, y: 194 },
      { x: 134, y: 245 },
      { x: 138, y: 271 },
      { x: 163, y: 284 },
      { x: 258, y: 266 },
      { x: 271, y: 254 },
      { x: 278, y: 237 },
      { x: 284, y: 220 },
      { x: 290, y: 215 },
      { x: 302, y: 215 },
      { x: 340, y: 215 },
      { x: 362, y: 193 },
      { x: 374, y: 178 },
      { x: 409, y: 170 },
      { x: 444, y: 174 },
      { x: 457, y: 177 },
      { x: 466, y: 185 },
      { x: 485, y: 210 },
      { x: 565, y: 273 },
      { x: 564, y: 281 },
      { x: 570, y: 290 },
      { x: 584, y: 296 },
      { x: 617, y: 320 },
      { x: 643, y: 326 },
      { x: 667, y: 329 },
      { x: 679, y: 329 },
      { x: 695, y: 335 },
      { x: 728, y: 357 },
      { x: 750, y: 368 },
      { x: 804, y: 443 },
      { x: 805, y: 454 },
      { x: 798, y: 459 },
      { x: 778, y: 462 },
      { x: 759, y: 462 },
      { x: 745, y: 456 },
      { x: 720, y: 432 },
      { x: 713, y: 415 },
      { x: 721, y: 397 },
      { x: 750, y: 368 },
      { x: 736, y: 359 },
      { x: 728, y: 357 },
      { x: 720, y: 359 },
      { x: 678, y: 390 },
      { x: 657, y: 394 },
      { x: 640, y: 391 },
      { x: 557, y: 352 },
      { x: 535, y: 343 },
      { x: 518, y: 341 },
      { x: 503, y: 331 },
      { x: 502, y: 321 },
      { x: 507, y: 312 },
      { x: 531, y: 294 },
      { x: 548, y: 288 },
      { x: 564, y: 281 },
      { x: 565, y: 273 },
      { x: 485, y: 210 },
      { x: 466, y: 185 },
      { x: 457, y: 177 },
      { x: 444, y: 174 },
      { x: 409, y: 170 },
      { x: 374, y: 164 },
      { x: 357, y: 146 },
      { x: 335, y: 135 },
      { x: 318, y: 132 },
      { x: 296, y: 131 },
      { x: 283, y: 129 },
      { x: 275, y: 126 },
      { x: 262, y: 116 },
      { x: 248, y: 111 }
    ]
  }
];
