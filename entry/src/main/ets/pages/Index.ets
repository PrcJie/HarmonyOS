import {CommonConstants as Const} from "../common/constants/CommonConstants"
import { startImages } from '../viewmodel/Startmodel';

@Entry
@Component
struct StarPage {
  private swiper : SwiperController = new SwiperController()
  private data : Resource[] = []
  private time : number = -1
  @State countdown : number = Const.COUNTDOWN
  @State showSwiper : boolean = false

  aboutToAppear(): void {
    let  hours = new Date().getHours()
    if (hours >= Const.MORNING_TIME && hours < Const.EVENING_TIME) {
      this.data = startImages.day
    } else if (hours >= Const.EVENING_TIME && hours <= Const.NIGHT_TIME) {
      this.data = startImages.duck
    } else {
      this.data = startImages.night
    }
    setTimeout(()=>{
      this.showSwiper = true
      this.starttTiming()
    },Const.SPLASH_DURATION)
  }
  starttTiming(): void {
    this.clearTiming()
    this.time = setInterval(() => {
      this.countdown--
      if (this.countdown <= 0) {
        this.jumpTOdisapper()
      }
    }, Const.DURATION)
  }
  clearTiming(){
    clearInterval(this.time)
  }
  jumpTOdisapper(){
    this.clearTiming()
    this.getUIContext().getRouter().replaceUrl({ url: 'pages/MainPage' })
  }

  aboutToDisappear(): void {
    this.clearTiming()
  }
  build() {
    Column() {
      Stack(){
        if (this.showSwiper){
          Swiper(this.swiper){
            ForEach(this.data,(item : Resource) =>{
              Image(item)
                .width("100%")
                .height("100%")
                .objectFit(ImageFit.Cover)
            })
          }
          .loop(true)
          .interval(2 * Const.DURATION)
          .autoPlay(true)
          .duration(Const.DURATION)
          .indicatorStyle({
            bottom:$r("app.float.100"),
            color:$r("app.color.swiper_dot_color")
          })
          .curve(Curve.Linear)
          .onChange((index:number) => {
            console.info(index.toString())
          })
          Text(`${this.countdown}秒跳过`)
            .onClick(() =>{
              this.jumpTOdisapper()
            })
            .fontSize($r("app.float.12fp"))
            .fontColor(Color.White)
            .backgroundColor($r("app.color.swiper_jump_bg_color"))
            .width(74)
            .height(28)
            .borderRadius(14)
            .textAlign(TextAlign.Center)
            .position({
              x:"+80%",
              y:"+5%"
            })





        }else {
          Image($r("app.media.splash_bg"))
            .width("100%")
            .height("100%")

          Image($r("app.media.ic_splash"))
            .width($r("app.float.192"))
            .height($r("app.float.192"))
            .offset({
              y:`-${Const.PERCENTAGE_15}`
            })
            .objectFit(ImageFit.Contain)

          Column(){
            Text(Const.SPLASH_DES)
              .fontSize($r("app.float.font_size_24fp"))
              .fontColor(Color.White)
            Text(Const.SPLASH_WELCOME)
              .fontSize($r("app.float.font_size_16fp"))
              .fontColor(Color.White)
            Text(Const.SPLASH_INFO)
              .fontSize($r("app.float.12fp"))
              .fontColor(Color.White)
              .margin({
                top:$r("app.float.85")
              })
          }
          .offset({
            y:Const.PERCENTAGE_25
          })

        }
      }

    }
    .height('100%')
    .width('100%')
  }
}
