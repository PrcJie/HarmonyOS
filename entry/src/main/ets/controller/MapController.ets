import { UIContext } from '@ohos.arkui.UIContext';
import { AddressItem, Location } from '../viewmodel/AddressItem';
import { CommonConstants } from '../common/constants/CommonConstants';
import Logger from '../common/utils/Logger';

const TAG = 'MapController';

export class MapController {
  private leftTop: Array<number> = [0, 0];
  private mapScale: number = CommonConstants.MAP_MIN_SCALE;

  initLeftTop(screenMapWidth: number, mapWidth: number): void {
    this.leftTop = [Math.min(screenMapWidth - mapWidth, 0), 0];
  }

  getLeftTop(): Array<number> {
    return [...this.leftTop];
  }

  calLandmarksPosition(data: AddressItem): void {
    const multiples = this.mapMultiples();
    data.location.forEach((item: Location) => {
      item.positionX = item.originalPositionX * multiples -
        CommonConstants.MAP_LANDMARKS_SIZE / CommonConstants.DOUBLE_OR_HALF;
      item.positionY = item.originalPositionY * multiples -
        CommonConstants.MAP_LANDMARKS_SIZE;
    });
  }

  setMapScale(scale: number): void {
    if (!Number.isFinite(scale)) {
      throw new Error('Invalid map scale');
    }
    this.mapScale = Math.max(CommonConstants.MAP_MIN_SCALE,
      Math.min(CommonConstants.MAP_MAX_SCALE, scale));
  }

  getMapScale(): number {
    return this.mapScale;
  }

  mapMultiples(): number {
    return this.mapScale;
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


































