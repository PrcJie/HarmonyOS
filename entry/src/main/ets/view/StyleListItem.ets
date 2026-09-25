import ZonesItem from '../viewmodel/ZonesItem';
import { AnimationItem } from '../viewmodel/AnimationItem';
import ImageAnimation from './ImageAnimation';

@Component
export default struct StyleListItem {
  @Consume('contentData') contentData: ZonesItem;
  @Consume('animationItem') animationItem: AnimationItem;

  build() {
    Column() {
      ForEach(this.contentData.content, (item: string) => {
        Text(item)
          .width('87%')
          .fontSize(14)
          .fontColor('#34404C')
          .margin({ bottom: 24 })
      }, (item: string) => item)

      Column() {
        ImageAnimation()
      }
      .width('87%')
      .height(210)
      .margin({ top: 24, bottom: 48 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .constraintSize({ minHeight: 500 })
    .alignItems(HorizontalAlign.Center)
    .onAreaChange((_oldArea: Area, newArea: Area) => {
      const height = Number(newArea.height);
      if (height > 0 && height !== this.animationItem.styleHeight) {
        this.animationItem.styleHeight = height;
      }
    })
  }
}
