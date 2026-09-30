import { BottonTabslist } from "../viewmodel/BottonTabsModel"
import { CommonConstants } from "../common/constants/CommonConstants"
import { Map } from "../view/MapView"
import { Zones } from "../view/ZonesComponent"
import { Trains } from "../view/TrainsComponent"
import { CampusInfoPage } from "../view/CampusInfoPage"

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
      Column() {
        if (this.selectedTabIndex === 3) {
          Row() {
            Text('校区信息')
              .fontSize(19)
              .fontWeight(FontWeight.Medium)
              .fontColor('#172B3B')
          }
          .width('100%')
          .height(56)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#F8FBFD')
        }

        Tabs({barPosition:BarPosition.End,index : this.bottomTabIndex,controller:this.controller}){
          TabContent(){
            Map()

          }
          .tabBar(this.Tabbnider(0,"Map"))

          TabContent(){
            Zones()
          }
          .tabBar(this.Tabbnider(1,"Zone"))

          TabContent(){
            Trains()
          }
          .tabBar(this.Tabbnider(2,"Train"))

          TabContent(){
            CampusInfoPage()
          }
          .tabBar(this.Tabbnider(3,"Campus"))

        }
        .width("100%")
        .layoutWeight(1)
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
      .width('100%')
      .height('100%')
    }
  }
}
