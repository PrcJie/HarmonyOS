import { Campus } from '../common/Campus';

const LOGO_DURATION_MS: number = 2000;
const SWIPER_DURATION_SECONDS: number = 6;
const SLIDE_INTERVAL_MS: number = 2000;

@Entry
@Component
struct Index {
  @State private showSwiper: boolean = false;
  @State private countdown: number = SWIPER_DURATION_SECONDS;
  @State private slideTitle: string = '校门广场';

  private logoTimer: number = -1;
  private countdownTimer: number = -1;
  private hasNavigated: boolean = false;

  aboutToAppear(): void {
    this.logoTimer = setTimeout(() => {
      this.showSwiper = true;
      this.startCountdown();
    }, LOGO_DURATION_MS);
  }

  aboutToDisappear(): void {
    this.clearTimers();
  }

  private startCountdown(): void {
    this.countdownTimer = setInterval(() => {
      this.countdown--;
      if (this.countdown <= 0) {
        this.openMainPage();
      }
    }, 1000);
  }

  private clearTimers(): void {
    clearTimeout(this.logoTimer);
    clearInterval(this.countdownTimer);
  }

  private openMainPage(): void {
    if (this.hasNavigated) {
      return;
    }
    this.hasNavigated = true;
    this.clearTimers();
    try {
      this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' });
    } catch (error) {
      this.hasNavigated = false;
      console.error(`打开校园导览失败: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.showSwiper) {
        Swiper() {
          Image($rawfile('swiper_gate_zine.png'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)

          Image($rawfile('swiper_library_zine.png'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)

          Image($rawfile('swiper_activity_zine.png'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
        }
        .width('100%')
        .height('100%')
        .autoPlay(true)
        .interval(SLIDE_INTERVAL_MS)
        .duration(400)
        .curve(Curve.Linear)
        .loop(false)
        .indicator(new DotIndicator()
          .bottom(28)
          .itemWidth(8)
          .itemHeight(8)
          .selectedItemWidth(8)
          .selectedItemHeight(8)
          .color('#BAC6CC')
          .selectedColor('#165A82'))
        .onChange((index: number) => {
          if (index === 1) {
            this.slideTitle = '临潼图书馆';
          } else if (index === 2) {
            this.slideTitle = '大学生活动中心';
          } else {
            this.slideTitle = '校门广场';
          }
        })

        Column() {
          Row() {
            Text('校园导览')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#165A82')

            Blank()

            Text(`${this.countdown} 秒后进入 · 跳过`)
              .fontSize(14)
              .fontColor('#123C57')
              .padding({ top: 8, bottom: 8, left: 12, right: 12 })
              .borderRadius(16)
              .backgroundColor('#E7EDF0')
              .onClick(() => this.openMainPage())
          }
          .width('100%')

          Text(Campus.NAME)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#123C57')
            .margin({ top: 38 })

          Text(this.slideTitle)
            .fontSize(18)
            .fontColor('#165A82')
            .margin({ top: 10 })
        }
        .width('100%')
        .padding({ top: 28, left: 24, right: 24 })
        .alignItems(HorizontalAlign.Start)
      } else {
        Column() {
          Image($rawfile('xpu_official_logo.jpg'))
            .width(176)
            .height(176)
            .objectFit(ImageFit.Contain)

          Text(Campus.NAME)
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#123C57')
            .textAlign(TextAlign.Center)
            .margin({ top: 28 })

          Text('校园导览')
            .fontSize(17)
            .fontColor('#165A82')
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(24)
        .backgroundColor(Color.White)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FCF7EE')
  }
}
