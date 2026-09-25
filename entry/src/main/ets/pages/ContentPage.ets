import router from '@ohos.router';
import ZonesItem from '../viewmodel/ZonesItem';
import ZonesViewModel from '../viewmodel/ZonesViewModel';
import { AnimationItem } from '../viewmodel/AnimationItem';
import { Animation } from '../common/utils/Animation';
import { DeviceScreen } from '../common/utils/DeviceScreen';
import { CommonConstants } from '../common/constants/CommonConstants';
import BuildListItem from '../view/BuildListItem';
import SubTitleItem from '../view/SubTitleItem';
import SwiperListItem from '../view/SwiperListItem';
import StyleListItem from '../view/StyleListItem';

interface ZoneRouteParams {
  id?: number;
}

@Entry
@Component
struct ContentPage {
  private zonesList: ZonesItem[] = ZonesViewModel.getZonesList();
  @Provide('contentData') contentData: ZonesItem = ZonesViewModel.getZonesByIndex(0);
  @Provide('animationItem') animationItem: AnimationItem = new AnimationItem();
  @State currentZonesId: number = 0;
  @State isReachStart: boolean = false;

  aboutToAppear(): void {
    const params = router.getParams() as ZoneRouteParams;
    if (params && typeof params.id === 'number') {
      const index = this.zonesList.findIndex((item: ZonesItem) => item.id === params.id);
      if (index >= 0) {
        this.currentZonesId = index;
        this.contentData = this.zonesList[index];
      }
    }
    const screenHeight = DeviceScreen.getDeviceHeight();
    this.animationItem.screenHeight = screenHeight > 0 ? screenHeight : 640;
  }

  @Builder
  TitleIcon(src: ResourceStr, scale: number) {
    Image(src)
      .width(56)
      .height(36)
      .syncLoad(true)
      .scale({ x: scale, y: scale })
      .opacity(scale)
      .animation({ duration: 500, curve: Curve.EaseOut })
  }

  @Builder
  StickyHeader() {
    Column() {
      Image(this.contentData.subPicBottom)
        .width('100%')
        .height(120)
        .objectFit(ImageFit.Fill)
        .backgroundColor(this.contentData.backgroundColor)

      Stack({ alignContent: Alignment.Bottom }) {
        Image(this.contentData.titleIcon)
          .width(57)
          .height(24)
          .syncLoad(true)
          .margin({ bottom: 23 })

        this.TitleIcon($r('app.media.ic_design_style'), this.animationItem.scaleIcon[0]);
        this.TitleIcon($r('app.media.ic_building'), this.animationItem.scaleIcon[1]);
        this.TitleIcon($r('app.media.ic_geography_icon'), this.animationItem.scaleIcon[2]);
      }
      .width('100%')
      .height(73)

      Text(this.animationItem.iconTitle)
        .fontSize(10)
        .fontColor('#000000')
        .margin({ bottom: 18 })
    }
    .width('100%')
    .height(229)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#F1F3F5')
  }

  @Builder
  ListFooter() {
    Column().height(160)
  }

  private resetAtStart(): void {
    this.animationItem.listPosition = 0;
    if (this.isReachStart) {
      this.animationItem.imageHeight = 100;
      this.animationItem.arrowIconOpacity = 1;
      this.animationItem.offsetSum = 0;
      this.animationItem.iconTitle = 'DESIGN STYLE';
      this.animationItem.scaleIcon = [1, 0, 0];
      this.isReachStart = false;
    }
  }

  private scrollToTop(): void {
    if (this.animationItem.listPosition !== 0) {
      this.animationItem.scrollerForList.scrollTo({
        xOffset: 0,
        yOffset: 0,
        animation: { duration: 500, curve: Curve.EaseOut }
      });
      this.isReachStart = true;
    } else {
      this.animationItem.imageHeight = 100;
      this.animationItem.arrowIconOpacity = 1;
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        List({ scroller: this.animationItem.scrollerForList }) {
          ListItem() {
            SwiperListItem({
              imageHeight: this.animationItem.imageHeight,
              viewportHeight: this.animationItem.screenHeight,
              currentZonesId: this.currentZonesId,
              arrowIconOpacity: this.animationItem.arrowIconOpacity
            })
          }

          ListItem() {
            SubTitleItem()
          }
          .height(350)

          ListItemGroup({ header: this.StickyHeader(), footer: this.ListFooter() }) {
            ListItem() {
              StyleListItem()
            }

            ListItem() {
              BuildListItem({ type: CommonConstants.BUILDING_TEXT })
            }
            .height(500)

            ListItem() {
              BuildListItem({ type: this.animationItem.geographicPicType })
            }
            .height(500)
          }
        }
        .width('100%')
        .height('100%')
        .edgeEffect(EdgeEffect.None)
        .scrollBar(BarState.Off)
        .sticky(StickyStyle.Header)
        .cachedCount(3)
        .onReachStart(() => {
          this.resetAtStart();
        })
        .onScrollIndex((start: number) => {
          this.animationItem.currentListIndex = start;
        })
        .onReachEnd(() => {
          this.animationItem.listPosition = 2;
        })
        .onScroll(() => {
          Animation.changeTitleIcon(this.animationItem);
        })
        .onScrollFrameBegin((offset: number, state: ScrollState) => {
          return { offsetRemain: Animation.controlImageScale(this.animationItem, offset, state) };
        })

        Column({ space: 12 }) {
          Image($r('app.media.ic_up_icon'))
            .width(40)
            .height(40)
            .opacity(1 - this.animationItem.arrowIconOpacity)
            .onClick(() => {
              this.scrollToTop();
            })

          Image($r('app.media.ic_home_back'))
            .width(40)
            .height(40)
            .onClick(() => {
              router.back();
            })
        }
        .margin({ right: 20, bottom: 32 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }

  pageTransition() {
    PageTransitionEnter({ duration: 800 })
      .slide(SlideEffect.Bottom)
      .scale({ x: 0, y: 0, z: 0, centerX: '50%', centerY: '50%' });
    PageTransitionExit({ delay: 300 })
      .slide(SlideEffect.Bottom)
      .scale({ x: 0, y: 0, z: 0, centerX: '50%', centerY: '50%' });
  }
}
