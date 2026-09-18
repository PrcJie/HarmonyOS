import { BottonTabslist } from "../viewmodel/BottonTabsModel"
import { CommonConstants } from "../common/constants/CommonConstants"

@Entry
@Component
struct MainPage {
  @State bottomTabIndex : number = 0
  @State selectedTabIndex : number = 0
  private  controller : TabsController = new TabsController()

  @Builder Tabbnider(index : number , name:string){
    Column(){
      Image(this.selectedTabIndex === index ? BottonTabslist[index].iconSelected : BottonTabslist[index].icon)
        .width(CommonConstants.ICON_SIZE)
        .height(CommonConstants.ICON_SIZE)
        .objectFit(ImageFit.Contain)
      Text(BottonTabslist[index].text)
        .fontSize(16)
        .fontColor(this.selectedTabIndex === index ? $r("app.color.bottom_tabs_font_color_selected") : $r("app.color.bottom_tabs_font_color"))
        .margin({
          top:5
        })
    }
    .width("100%")
    .height("100%")
    .justifyContent(FlexAlign.Center)
    .border({width:{top:CommonConstants.BORDER_WIDTH},color:$r("app.color.color_border")})
    .backgroundColor($r("app.color.bottom_tabs_background_color"))
  }

  build() {
    Flex({
      direction : FlexDirection.Column,alignItems:ItemAlign.End,justifyContent:FlexAlign.End
    }){
      Tabs({barPosition:BarPosition.End,index : this.bottomTabIndex,controller:this.controller}){
        TabContent(){
          Column(){
            Text("地图浏览")
              .fontSize(16)
              .textAlign(TextAlign.Start)
          }

        }
        .tabBar(this.Tabbnider(0,"Map"))

        TabContent(){
          Text("区域导航")
            .fontSize(16)
            .textAlign(TextAlign.Start)
        }
        .tabBar(this.Tabbnider(1,"Zone"))

        TabContent(){
          Text("园区火车")
            .fontSize(16)
            .textAlign(TextAlign.Start)
        }
        .tabBar(this.Tabbnider(2,"Train"))

        TabContent(){
          Text("个人信息")
            .fontSize(16)
            .textAlign(TextAlign.Start)
        }
        .tabBar(this.Tabbnider(3,"User"))

      }
      .width("100%")
      .height("100%")
      .vertical(false)
      .scrollable(false)
      .barHeight(CommonConstants.BAR_HEIGHT)
      .onAnimationStart((_index:number, targetIndex:number) =>{
        this.selectedTabIndex = targetIndex
      })
      .onChange((index:number) =>{
        this.bottomTabIndex = index
        this.selectedTabIndex = index
      })
    }
  }
}
