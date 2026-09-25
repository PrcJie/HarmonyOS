import ZonesItem from '../viewmodel/ZonesItem';
import { ImageView } from './ImageViewComponent';

/** 循环层叠图集，横向滑动切换图片。 */
@Component
export default struct ImageAnimation {
  @Consume('contentData') contentData: ZonesItem;
  @State currentIndex: number = 2;
  private dialogController: CustomDialogController = new CustomDialogController({
    builder: ImageView({ currentImageId: this.currentIndex }),
    customStyle: true,
    alignment: DialogAlignment.Bottom,
    width: '100%',
    height: '100%'
  });

  /** 返回图片相对当前图片的最短环形距离。 */
  private getImgCoefficients(index: number): number {
    const length = this.contentData.imageList.length;
    if (length <= 1) {
      return 0;
    }
    let coefficient = this.currentIndex - index;
    if (coefficient > length / 2) {
      coefficient -= length;
    } else if (coefficient < -length / 2) {
      coefficient += length;
    }
    return coefficient;
  }

  private getOffsetX(index: number): number {
    const coefficient = this.getImgCoefficients(index);
    if (Math.abs(coefficient) === 1) {
      return -70 * coefficient;
    }
    if (Math.abs(coefficient) === 2) {
      return -45 * coefficient;
    }
    return 0;
  }

  private startAnimation(isLeft: boolean): void {
    const length = this.contentData.imageList.length;
    if (length > 0) {
      animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
        this.currentIndex = (this.currentIndex + (isLeft ? 1 : -1) + length) % length;
      });
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      ForEach(this.contentData.imageList, (item: ResourceStr, index: number) => {
        Row() {
          Image(item)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .opacity(1 - 0.1 * Math.min(2, Math.abs(this.getImgCoefficients(index))))
        }
          .aspectRatio(16 / 21)
          .height(this.getImgCoefficients(index) === 0 ? '78%' :
            `${100 - 7 * Math.abs(this.getImgCoefficients(index))}%`)
          .borderRadius(8)
          .clip(true)
          .offset({ x: this.getOffsetX(index), y: 0 })
          .blur(10 * Math.abs(this.getImgCoefficients(index)))
          .zIndex(2 - Math.abs(this.getImgCoefficients(index)))
          .onClick(() => {
            this.currentIndex = index;
            this.dialogController.open();
          })
      }, (_item: ResourceStr, index: number) => `${this.contentData.id}-${index}`)
    }
    .width('100%')
    .height('100%')
    .gesture(
      PanGesture({ direction: PanDirection.Horizontal })
        .onActionEnd((event?: GestureEvent) => {
          if (!event || Math.abs(event.offsetX) < 40) {
            return;
          }
          this.startAnimation(event.offsetX < 0);
        })
    )
  }
}
