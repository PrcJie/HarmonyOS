import router from '@ohos.router';
import { CommonConstants } from '../common/constants/CommonConstants';
import ZonesItem from '../viewmodel/ZonesItem';
import ZonesViewModel from '../viewmodel/ZonesViewModel';

@Component
export struct Zones {
  private changedIndex: boolean = false;
  private zonesList: ZonesItem[] = ZonesViewModel.getZonesList();
  @State aheadIndex: number = 2;
  @State marginBottom: number = 0;

  // 当前卡片为 0，前后两层为 ±1、±2；首尾卡片循环衔接。
  getImgCoefficients(index?: number): number {
    if (index === undefined || this.zonesList.length === 0) {
      return 0;
    }
    const coefficient = this.aheadIndex - index;
    const distance = Math.abs(coefficient);
    if (distance <= 2) {
      return coefficient;
    }
    const wrappedDistance = this.zonesList.length - distance;
    if (wrappedDistance <= 2) {
      return coefficient > 0 ? -wrappedDistance : wrappedDistance;
    }
    return 0;
  }

  getOffsetY(index?: number): number {
    if (index === undefined) {
      return 0;
    }
    const offsetIndex = this.getImgCoefficients(index);
    const distance = Math.abs(offsetIndex);
    let offsetY = this.marginBottom / (distance + 1);
    if (distance === 1) {
      offsetY -= offsetIndex * 100;
    } else if (distance === 2) {
      offsetY -= offsetIndex * 90;
    }
    return offsetY;
  }

  startAnimation(isUp: boolean): void {
    const count = this.zonesList.length;
    if (count === 0) {
      return;
    }
    animateTo({ duration: 300 }, () => {
      this.aheadIndex = (this.aheadIndex + (isUp ? 1 : count - 1)) % count;
      this.marginBottom = 0;
    });
  }

  handlePanGesture(offsetY: number): void {
    if (this.changedIndex) {
      return;
    }
    if (Math.abs(offsetY) < 60) {
      this.marginBottom = offsetY;
      return;
    }
    this.changedIndex = true;
    this.startAnimation(offsetY < 0);
  }

  build() {
    Navigation() {
      Stack() {
        ForEach(this.zonesList, (item: ZonesItem, index: number) => {
          Row() {
            Image(item.thumbnail)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(16)
              .shadow({ radius: 50, color: 'rgba(0,0,0,0.3)', offsetY: 1 })
              .blur(10 * Math.abs(this.getImgCoefficients(index)))
          }
          .width(index !== this.aheadIndex && this.getImgCoefficients(index) === 0 ?
            '66%' : `${86 - 10 * Math.abs(this.getImgCoefficients(index))}%`)
          .aspectRatio(6 / 5)
          .borderRadius(16)
          .offset({ x: 0, y: this.getOffsetY(index) })
          .opacity(index !== this.aheadIndex && this.getImgCoefficients(index) === 0 ?
            0 : 1 - Math.abs(this.getImgCoefficients(index)) * 0.1)
          .zIndex(index !== this.aheadIndex && this.getImgCoefficients(index) === 0 ?
            0 : 3 - Math.abs(this.getImgCoefficients(index)))
          .onClick(() => {
            if (index !== this.aheadIndex) {
              return;
            }
            router.pushUrl({
              url: CommonConstants.CONTENT_URL,
              params: { id: item.id }
            }).catch((error: Error) => {
              console.error(`无法打开区域详情：${error.message}`);
            });
          })
        }, (item: ZonesItem) => item.id.toString())
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.Center)
      .gesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionStart(() => {
            this.changedIndex = false;
          })
          .onActionUpdate((event: GestureEvent) => {
            this.handlePanGesture(event.offsetY);
          })
          .onActionEnd(() => {
            animateTo({ duration: 300 }, () => {
              this.marginBottom = 0;
            });
          })
          .onActionCancel(() => {
            this.marginBottom = 0;
          })
      )
    }
    .backgroundColor($r('app.color.introduction_page_color'))
    .title('区域导览')
    .titleMode(NavigationTitleMode.Full)
    .hideBackButton(true)
  }
}

@Entry
@Component
struct ZonesPage {
  build() {
    Column() {
      Zones()
    }
    .width('100%')
    .height('100%')
  }
}
