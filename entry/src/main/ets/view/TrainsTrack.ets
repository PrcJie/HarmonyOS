import { image } from '@kit.ImageKit';
import { CommonConstants } from '../common/constants/CommonConstants';
import { Position, TrainsLine, TrainsMap } from '../viewmodel/TrainsMap';
import trainsMapModel from '../viewmodel/TrainsMapModel';

/** 底图跟随列车移动，箭头和列车标记绘制在其上方。 */
@Component
export struct TrainsTrack {
  private setting: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.setting);
  private trainSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private contextTrainLine: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.trainSetting);

  @Prop trainsInfo: TrainsMap = new TrainsMap();
  @Prop trainLine: number = TrainsLine.LINE_ONE;

  private imgBgBitmap: ImageBitmap | undefined = undefined;
  private imgTrain: ImageBitmap | undefined = undefined;
  private imgCircle: ImageBitmap | undefined = undefined;
  private pixelMaps: Array<image.PixelMap> = [];
  @State private canvasWidth: number = 0;
  @State private canvasHeight: number = 0;
  private backgroundReady: boolean = false;
  private trainLayerReady: boolean = false;
  private intervalId: number = -1;

  private sumDistance: number = 0;
  private delay: number = 0;
  private currentIndex: number = 0;
  @State private trainX: number = 0;
  @State private trainY: number = 0;
  @State private bgX: number = 0;
  @State private bgY: number = 0;
  @State private rotateAngle: number = CommonConstants.INIT_ROTATE_ANGLE;
  private positionStart: Position = new Position();
  private positionEnd: Position = new Position();

  aboutToAppear(): void {
    this.imgBgBitmap = this.loadImageBitmap(this.trainsInfo.imgBg);
    this.imgTrain = this.loadImageBitmap($r('app.media.ic_train'));
    this.imgCircle = this.loadImageBitmap($r('app.media.ic_circle'));

    this.sumDistance = trainsMapModel.calDistance(this.trainsInfo.lineData);
    this.delay = trainsMapModel.calDelay(this.sumDistance, this.trainLine);
    this.fetchStartPosition();
  }

  private startAnimation(): void {
    if (!this.backgroundReady || !this.trainLayerReady || this.intervalId !== -1) {
      return;
    }
    this.drawTrainPosition();
    if (this.delay > 0) {
      const refreshMs = Math.max(16, Math.min(50, this.delay));
      this.intervalId = setInterval(() => this.drawTrainPosition(), refreshMs);
    }
  }

  aboutToDisappear(): void {
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
    if (this.imgBgBitmap !== undefined) {
      this.imgBgBitmap.close();
    }
    if (this.imgTrain !== undefined) {
      this.imgTrain.close();
    }
    if (this.imgCircle !== undefined) {
      this.imgCircle.close();
    }
    this.pixelMaps.forEach((pixelMap: image.PixelMap) => {
      pixelMap.release();
    });
    this.pixelMaps = [];
    this.backgroundReady = false;
    this.trainLayerReady = false;
  }

  private loadImageBitmap(res: Resource): ImageBitmap | undefined {
    let imageSource: image.ImageSource | undefined = undefined;
    try {
      const fileData: Uint8Array = getContext(this).resourceManager.getMediaContentSync(res);
      const imageData = fileData.buffer.slice(fileData.byteOffset,
        fileData.byteOffset + fileData.byteLength) as ArrayBuffer;
      imageSource = image.createImageSource(imageData);
      const options: image.DecodingOptions = {
        editable: true,
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888
      };
      const pixelMap: image.PixelMap = imageSource.createPixelMapSync(options);
      const bitmap = new ImageBitmap(pixelMap);
      this.pixelMaps.push(pixelMap);
      return bitmap;
    } catch (err) {
      console.error(`列车地图图片解码失败: ${JSON.stringify(err)}`);
      return undefined;
    } finally {
      if (imageSource !== undefined) {
        imageSource.release();
      }
    }
  }

  private fetchStartPosition(): void {
    const travelDistance = trainsMapModel.travelDistance(this.sumDistance,
      this.fetchStartTime(this.trainLine), this.trainLine);
    this.calcFirstDistance(this.trainsInfo.lineData, travelDistance);
  }

  private fetchStartTime(line: number): string {
    if (line === TrainsLine.LINE_THREE) {
      const weekday = new Date().getDay();
      if (weekday === 0 || weekday === 6) {
        return CommonConstants.LINE_THREE_WEEKEND_POSITION_START_TIME;
      }
      return CommonConstants.LINE_THREE_START_TIME;
    }
    return line === TrainsLine.LINE_TWO ? CommonConstants.LINE_TWO_START_TIME :
      CommonConstants.LINE_ONE_START_TIME;
  }

  private calcFirstDistance(data: Array<Position>, travelDistance: number): void {
    if (data.length === 0) {
      return;
    }
    const position = trainsMapModel.positionAtDistance(data, travelDistance);
    this.currentIndex = position.segmentIndex;
    this.positionStart = data[this.currentIndex];
    this.positionEnd = data[(this.currentIndex + 1) % data.length];
    this.trainX = position.x;
    this.trainY = position.y;
    // 小火车图片默认朝上，线路角度以向右为 0 度。
    const direction = trainsMapModel.fetchDirection(this.positionStart.x, this.positionStart.y,
      this.positionEnd.x, this.positionEnd.y);
    this.rotateAngle = CommonConstants.BASIC_ROTATE_ANGLE + direction;
  }

  /** 将列车尽量保持在视窗中心，并限制地图不露出边界。 */
  private calcPosition(x: number, y: number, width: number, height: number): void {
    const mapWidth = CommonConstants.CANVAS_WIDTH;
    const mapHeight = CommonConstants.CANVAS_HEIGHT;
    this.bgX = width >= mapWidth ? (width - mapWidth) / 2 :
      Math.max(width - mapWidth, Math.min(0, width / 2 - x));
    this.bgY = height >= mapHeight ? (height - mapHeight) / 2 :
      Math.max(height - mapHeight, Math.min(0, height / 2 - y));
  }

  private drawTrainPosition(): void {
    if (!this.backgroundReady || !this.trainLayerReady ||
      this.canvasWidth <= 0 || this.canvasHeight <= 0) {
      return;
    }
    this.fetchStartPosition();
    this.calcPosition(this.trainX, this.trainY, this.canvasWidth, this.canvasHeight);
    const x = this.trainX + this.bgX;
    const y = this.trainY + this.bgY;

    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    if (this.imgBgBitmap !== undefined) {
      this.context.drawImage(this.imgBgBitmap, this.bgX, this.bgY,
        CommonConstants.CANVAS_WIDTH, CommonConstants.CANVAS_HEIGHT);
    }

    this.contextTrainLine.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    if (this.imgCircle !== undefined) {
      this.contextTrainLine.save();
      this.contextTrainLine.globalAlpha = 0.3;
      this.contextTrainLine.drawImage(this.imgCircle,
        x - CommonConstants.CIRCLE_OFFSET_X,
        y - CommonConstants.CIRCLE_OFFSET_Y,
        CommonConstants.CIRCLE_WIDTH,
        CommonConstants.CIRCLE_HEIGHT);
      this.contextTrainLine.restore();
    }
    if (this.imgTrain !== undefined) {
      this.contextTrainLine.drawImage(this.imgTrain,
        x - CommonConstants.TRAIN_OFFSET_X,
        y - CommonConstants.TRAIN_OFFSET_Y,
        CommonConstants.TRAIN_WIDTH,
        CommonConstants.TRAIN_HEIGHT);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 位图加载失败时仍显示该线路的静态底图。
      Image(this.trainsInfo.imgBg)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      Canvas(this.context)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.backgroundReady = true;
          this.startAnimation();
        })

      Image($r('app.media.ic_train_arrow'))
        .width(CommonConstants.ARROW_WIDTH)
        .height(CommonConstants.ARROW_HEIGHT)
        .position({
          x: this.trainX + this.bgX - CommonConstants.ARROW_OFFSET_X,
          y: this.trainY + this.bgY - CommonConstants.ARROW_OFFSET_Y
        })
        .rotate({ x: 0, y: 0, z: 1, angle: this.rotateAngle })

      Canvas(this.contextTrainLine)
        .width('100%')
        .height('100%')
        .onReady(() => {
          this.trainLayerReady = true;
          this.startAnimation();
        })
    }
      .width('100%')
      .aspectRatio(CommonConstants.CANVAS_ASPECT_RADIO)
      .borderRadius(CommonConstants.CANVAS_BORDER_RADIUS)
      .clip(true)
      .onAreaChange((_oldVal: Area, newVal: Area) => {
        this.canvasWidth = Number(newVal.width);
        this.canvasHeight = Number(newVal.height);
        this.drawTrainPosition();
      })
  }
}
