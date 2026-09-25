import window from '@ohos.window';
import ZonesItem from '../viewmodel/ZonesItem';
import { DeviceScreen } from '../common/utils/DeviceScreen';

/** 区域详情的全屏图片预览：轮播、双指缩放和拖动。 */
@CustomDialog
export struct ImageView {
  controller: CustomDialogController;
  @Consume('contentData') contentData: ZonesItem;
  @Prop currentImageId: number = 0;

  // 窗口和图片尺寸使用 px；手势偏移与 translate 使用 vp。
  private deviceWidth: number = 0;
  private deviceHeight: number = 0;
  private imageWidths: number[] = [];
  private imageHeights: number[] = [];

  @State private curIndex: number = 0;
  @State private isGesture: boolean = false;
  @State private imgScale: number = 1;
  @State private imgOffsetX: number = 0;
  @State private imgOffsetY: number = 0;
  private curScale: number = 1;
  private preOffsetX: number = 0;
  private preOffsetY: number = 0;

  aboutToAppear(): void {
    // 同一个弹窗再次打开时，清除上一组图片的尺寸和缩放状态。
    this.imageWidths = [];
    this.imageHeights = [];
    this.resetImage();
    const lastIndex = Math.max(0, this.contentData.imageList.length - 1);
    this.curIndex = Math.max(0, Math.min(this.currentImageId, lastIndex));
    const hostContext = this.getUIContext().getHostContext();
    if (!hostContext) {
      return;
    }
    DeviceScreen.getDeviceSize(hostContext).then((currentWindow: window.Window) => {
      const rect = currentWindow.getWindowProperties().windowRect;
      if (this.deviceWidth <= 0 || this.deviceHeight <= 0) {
        this.deviceWidth = rect.width;
        this.deviceHeight = rect.height;
      }
    }).catch((error: Error) => {
      console.error(`无法获取图片预览窗口尺寸：${error.message}`);
    });
  }

  /** 图片以 Contain 显示，缩放后只能拖动超出窗口的部分。 */
  private detectBoundary(): void {
    const imageWidth = this.imageWidths[this.curIndex];
    const imageHeight = this.imageHeights[this.curIndex];
    if (this.deviceWidth <= 0 || this.deviceHeight <= 0 || !imageWidth || !imageHeight) {
      this.imgOffsetX = 0;
      this.imgOffsetY = 0;
      return;
    }

    const fit = Math.min(this.deviceWidth / imageWidth, this.deviceHeight / imageHeight);
    const displayWidth = imageWidth * fit;
    const displayHeight = imageHeight * fit;
    const maxOffsetX = Math.max(0, (displayWidth * this.imgScale - this.deviceWidth) / 2);
    // 图片缩放后仍矮于窗口时，不允许沿纵向拖动。
    const maxOffsetY = displayHeight * this.imgScale > this.deviceHeight ?
      (displayHeight * this.imgScale - this.deviceHeight) / 2 : 0;
    const maxOffsetXvp = this.getUIContext().px2vp(maxOffsetX);
    const maxOffsetYvp = this.getUIContext().px2vp(maxOffsetY);
    this.imgOffsetX = Math.max(-maxOffsetXvp, Math.min(maxOffsetXvp, this.imgOffsetX));
    this.imgOffsetY = Math.max(-maxOffsetYvp, Math.min(maxOffsetYvp, this.imgOffsetY));
  }

  /** 缩放限制为 1～4 倍；恢复原始比例时同时归位图片。 */
  private limitScale(): void {
    this.imgScale = Math.max(1, Math.min(4, this.imgScale));
    this.curScale = this.imgScale;
    if (this.imgScale === 1) {
      this.imgOffsetX = 0;
      this.imgOffsetY = 0;
    } else {
      this.detectBoundary();
    }
    this.isGesture = this.imgScale > 1;
  }

  private resetImage(): void {
    this.imgScale = 1;
    this.curScale = 1;
    this.imgOffsetX = 0;
    this.imgOffsetY = 0;
    this.isGesture = false;
  }

  build() {
    Stack() {
      Swiper() {
        ForEach(this.contentData.imageList, (item: ResourceStr, index: number) => {
          Image(item)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .scale({ x: this.imgScale, y: this.imgScale })
            .translate({ x: this.imgOffsetX, y: this.imgOffsetY })
            .onComplete((event) => {
              if (event && event.width > 0 && event.height > 0) {
                this.imageWidths[index] = event.width;
                this.imageHeights[index] = event.height;
                if (index === this.curIndex) {
                  this.detectBoundary();
                }
              }
            })
            .gesture(
              PinchGesture()
                .onActionUpdate((event?: GestureEvent) => {
                  if (!event || !Number.isFinite(event.scale) || event.scale <= 0) {
                    return;
                  }
                  this.imgScale = Math.max(1, Math.min(4, this.curScale * event.scale));
                  this.detectBoundary();
                })
                .onActionEnd(() => {
                  this.limitScale();
                })
            )
        }, (_item: ResourceStr, index: number) => index.toString())
      }
      .width('100%')
      .height('100%')
      .loop(false)
      .index(this.curIndex)
      .disableSwipe(this.imgScale > 1)
      .indicator(this.contentData.imageList.length > 1)
      .onChange((index: number) => {
        this.curIndex = index;
        this.resetImage();
      })
      .visibility(this.isGesture ? Visibility.Hidden : Visibility.Visible)

      // 放大后用独立图层处理拖动，避免 Swiper 的翻页手势抢占平移。
      if (this.contentData.imageList.length > 0) {
        Row() {
          Image(this.contentData.imageList[this.curIndex])
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .scale({ x: this.imgScale, y: this.imgScale })
            .translate({ x: this.imgOffsetX, y: this.imgOffsetY })
            .onComplete((event) => {
              if (event && event.width > 0 && event.height > 0) {
                this.imageWidths[this.curIndex] = event.width;
                this.imageHeights[this.curIndex] = event.height;
                this.detectBoundary();
              }
            })
            .gesture(
              GestureGroup(GestureMode.Parallel,
                PinchGesture()
                  .onActionUpdate((event?: GestureEvent) => {
                    if (!event || !Number.isFinite(event.scale) || event.scale <= 0) {
                      return;
                    }
                    this.imgScale = Math.max(1, Math.min(4, this.curScale * event.scale));
                    this.detectBoundary();
                  })
                  .onActionEnd(() => {
                    this.limitScale();
                  }),
                PanGesture()
                  .onActionStart(() => {
                    this.preOffsetX = this.imgOffsetX;
                    this.preOffsetY = this.imgOffsetY;
                  })
                  .onActionUpdate((event?: GestureEvent) => {
                    if (!event) {
                      return;
                    }
                    this.imgOffsetX = this.preOffsetX + event.offsetX;
                    this.imgOffsetY = this.preOffsetY + event.offsetY;
                    this.detectBoundary();
                  })
                  .onActionEnd(() => {
                    this.detectBoundary();
                  })
              )
            )
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .visibility(this.isGesture ? Visibility.Visible : Visibility.Hidden)
      }

      Text('×')
        .fontSize(32)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(44)
        .height(44)
        .borderRadius(22)
        .backgroundColor('#88000000')
        .position({ x: '85%', y: 16 })
        .onClick(() => {
          this.controller.close();
        })
    }
    .width('100%')
    .height('100%')
    .clip(true)
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const width = Number(newArea.width);
      const height = Number(newArea.height);
      if (width > 0 && height > 0) {
        this.deviceWidth = this.getUIContext().vp2px(width);
        this.deviceHeight = this.getUIContext().vp2px(height);
        this.detectBoundary();
      }
    })
    .linearGradient({
      direction: GradientDirection.Top,
      colors: [['#FF515151', 0.8], ['#FF222222', 1.0]]
    })
  }
}
