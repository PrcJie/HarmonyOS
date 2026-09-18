import { UIContext } from '@ohos.arkui.UIContext';
import { AddressItem, Location } from '../viewmodel/AddressItem';
import { CommonConstants } from '../common/constants/CommonConstants';
import Logger from '../common/utils/Logger';

const TAG = 'MapController';

export class MapController {
  private leftTop: Array<number> = [0, 0];
  private pinchCount: number = 0;

  initLeftTop(screenMapWidth: number, mapWidth: number): void {
    this.leftTop = [Math.min(screenMapWidth - mapWidth, 0), 0];
  }

  getLeftTop(): Array<number> {
    return [...this.leftTop];
  }

  calLandmarksPosition(data: AddressItem): void {
    const multiples = this.mapMultiples();
    data.location.forEach((item: Location) => {
      item.positionX = item.oripositionX * multiples -
        CommonConstants.MAP_LANDMARKS_SIZE * CommonConstants.MAP_ZOOM_RATIO / CommonConstants.DOUBLE_OR_HALF;
      item.positionY = item.oripositionY * multiples -
        CommonConstants.MAP_LANDMARKS_SIZE * CommonConstants.MAP_ZOOM_RATIO;
    });
  }

  setPinchCount(count: number): void {
    if (!Number.isFinite(count)) {
      throw new Error('Invalid zoom count');
    }
    this.pinchCount = Math.max(0, Math.min(CommonConstants.ZOOM_MAX_TIMES, Math.round(count)));
  }

  mapMultiples(): number {
    return Math.pow(CommonConstants.MAP_ZOOM_RATIO, this.pinchCount);
  }

  // 在组件中传入 this.getUIContext()，避免从控制器实例获取错误的上下文。
  getResourceString(resource: Resource, uiContext: UIContext): string {
    try {
      const context = uiContext.getHostContext();
      if (!context) {
        Logger.error(TAG, '资源上下文不可用');
        return '';
      }
      return context.resourceManager.getStringSync(resource);
    } catch {
      Logger.error(TAG, '查询不到资源文字');
      return '';
    }
  }
}
export default new MapController();


































