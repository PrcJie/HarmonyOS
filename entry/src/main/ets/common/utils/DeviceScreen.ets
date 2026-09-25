import window from '@ohos.window';
import display from '@ohos.display';

export class DeviceScreen {
  /** 获取当前 UIAbility 对应的窗口，供图片预览计算可视区域。 */
  public static getDeviceSize(context: Context): Promise<window.Window> {
    try {
      return window.getLastWindow(context);
    } catch (error) {
      return Promise.reject(error);
    }
  }

  /** 将屏幕的物理像素高度换算成 vp。 */
  public static getDeviceHeight(): number {
    try {
      const currentDisplay = display.getDefaultDisplaySync();
      if (currentDisplay.densityDPI <= 0) {
        return 0;
      }
      return currentDisplay.height * 160 / currentDisplay.densityDPI;
    } catch (error) {
      return 0;
    }
  }
}
