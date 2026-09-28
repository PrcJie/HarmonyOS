import { image } from '@kit.ImageKit';
import { CommonConstants } from '../common/constants/CommonConstants';
import { Position, TrainsLine, TrainsMap } from '../viewmodel/TrainsMap';
import trainsMapModel from '../viewmodel/TrainsMapModel';

/** 将线路底图和按班次推算的列车位置绘制在同一坐标系中。 */
@Component
export struct TrainsTrack {
  private setting: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.setting);

  @Prop trainsInfo: TrainsMap = new TrainsMap();
  @Prop trainLine: number = TrainsLine.LINE_ONE;

  private imgBgBitmap: ImageBitmap | undefined = undefined;
  private imgTrain: ImageBitmap | undefined = undefined;
  private imgCircle: ImageBitmap | undefined = undefined;
  private pixelMaps: Array<image.PixelMap> = [];
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;
  private canvasReady: boolean = false;
  private intervalId: number = -1;

  private sumDistance: number = 0;
  private delay: number = 0;
  private currentIndex: number = 0;
  private trainX: number = 0;
  private trainY: number = 0;
  private rotateAngle: number = 0;
  private positionStart: Position = new Position();
  private positionEnd: Position = new Position();

  aboutToAppear(): void {
    this.imgBgBitmap = this.loadImageBitmap(this.trainsInfo.imgBg);
    this.imgTrain = this.loadImageBitmap($r('app.media.ic_train'));
    this.imgCircle = this.loadImageBitmap($r('app.media.ic_circle'));

    this.sumDistance = trainsMapModel.calDistance(this.trainsInfo.lineData);
    this.delay = trainsMapModel.calDelay(this.sumDistance, this.trainLine);
    this.fetchStartPosition();
    if (this.delay > 0) {
      const refreshMs = Math.max(16, Math.min(50, this.delay));
      this.intervalId = setInterval(() => {
        this.fetchStartPosition();
        this.drawTrack();
      }, refreshMs);
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
    this.rotateAngle = (direction + 90) * Math.PI / 180;
  }

  private drawTrack(): void {
    if (!this.canvasReady || this.canvasWidth <= 0 || this.canvasHeight <= 0) {
      return;
    }
    const scaleX = this.canvasWidth / CommonConstants.CANVAS_WIDTH;
    const scaleY = this.canvasHeight / CommonConstants.CANVAS_HEIGHT;
    const x = this.trainX * scaleX;
    const y = this.trainY * scaleY;
    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    if (this.imgBgBitmap !== undefined) {
      this.context.drawImage(this.imgBgBitmap, 0, 0, this.canvasWidth, this.canvasHeight);
    }
    if (this.imgCircle !== undefined) {
      this.context.drawImage(this.imgCircle,
        x - CommonConstants.CIRCLE_OFFSET_X * scaleX,
        y - CommonConstants.CIRCLE_OFFSET_Y * scaleY,
        CommonConstants.CIRCLE_WIDTH * scaleX,
        CommonConstants.CIRCLE_HEIGHT * scaleY);
    }
    if (this.imgTrain !== undefined) {
      this.context.save();
      this.context.translate(x, y);
      this.context.rotate(this.rotateAngle);
      this.context.drawImage(this.imgTrain,
        -CommonConstants.TRAIN_OFFSET_X * scaleX,
        -CommonConstants.TRAIN_OFFSET_Y * scaleY,
        CommonConstants.TRAIN_WIDTH * scaleX,
        CommonConstants.TRAIN_HEIGHT * scaleY);
      this.context.restore();
    }
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.canvasReady = true;
        this.drawTrack();
      })
      .onAreaChange((_oldVal: Area, newVal: Area) => {
        this.canvasWidth = Number(newVal.width);
        this.canvasHeight = Number(newVal.height);
        this.drawTrack();
      })
  }
}
