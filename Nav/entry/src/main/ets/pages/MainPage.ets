import { Campus } from '../common/Campus';
import { Map } from '../view/MapView';
import { Zones } from '../view/ZonesComponent';

@Entry
@Component
struct MainPage {
  @State selectedTabIndex: number = 0;
  @State private isHeroExpanded: boolean = false;
  private tabsController: TabsController = new TabsController();

  onBackPress(): boolean {
    if (this.isHeroExpanded) {
      this.isHeroExpanded = false;
      return true;
    }
    return false;
  }

  @Builder
  tabItem(index: number, label: string, normalIcon: Resource, selectedIcon: Resource) {
    Column() {
      Image(this.selectedTabIndex === index ? selectedIcon : normalIcon)
        .width(25)
        .height(25)
        .objectFit(ImageFit.Contain)
      Text(label)
        .fontSize(12)
        .fontColor(this.selectedTabIndex === index ? '#165A82' : '#647381')
        .margin({ top: 3 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  travelPage() {
    Column() {
      Text('到达临潼校区')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .width('100%')
      Text(Campus.ADDRESS)
        .fontSize(15)
        .margin({ top: 16 })
        .width('100%')
      Text('北门 · 陕鼓大道方向')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 24 })
        .width('100%')
      Text(`${Campus.NORTH_GATE_LATITUDE}, ${Campus.NORTH_GATE_LONGITUDE}`)
        .fontSize(13)
        .fontColor('#667785')
        .margin({ top: 6 })
        .width('100%')
      Text('地铁 9 号线 · 西工程大·西科大（临潼校区）站')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .margin({ top: 24 })
        .width('100%')
      Text('位于校区北侧，可从北门进入校园。')
        .fontSize(13)
        .fontColor('#667785')
        .margin({ top: 6 })
        .width('100%')
    }
    .padding(20)
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  campusSectionTitle(symbol: string, title: string) {
    Row({ space: 10 }) {
      Text(symbol)
        .fontSize(23)
        .fontColor('#2B8BD0')
        .width(28)
        .textAlign(TextAlign.Center)
      Text(title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor('#172B3B')
    }
    .width('100%')
  }

  @Builder
  campusFeature(icon: Resource, label: string, color: string) {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Image(icon)
          .width(29)
          .height(29)
          .objectFit(ImageFit.Contain)
      }
      .width(50)
      .height(50)
      .borderRadius(25)
      .backgroundColor(color)
      Text(label)
        .fontSize(12)
        .fontColor('#283C49')
        .margin({ top: 8 })
    }
    .width('25%')
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  campusInfoRow(label: string, value: string, isLast: boolean) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#61727E')
        .width(70)
      Text(value)
        .fontSize(13)
        .fontColor('#4E5F6D')
        .textAlign(TextAlign.End)
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 12, bottom: 12 })

    if (!isLast) {
      Divider()
        .strokeWidth(1)
        .color('#EAF0F3')
    }
  }

  @Builder
  campusPage() {
    Scroll() {
      Column({ space: 14 }) {
        Stack({ alignContent: Alignment.BottomStart }) {
          Image($rawfile('xpu_gate_source.png'))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)

          Column() {
            Text('走进临潼校园')
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(Campus.NAME)
              .fontSize(12)
              .fontColor('#EAF5FC')
              .margin({ top: 5 })
          }
          .width('100%')
          .padding({ top: 22, bottom: 16, left: 18, right: 18 })
          .alignItems(HorizontalAlign.Start)
          .backgroundColor('#B3123C57')
        }
        .width('100%')
        .height(142)
        .borderRadius(13)
        .clip(true)
        .onClick(() => {
          this.isHeroExpanded = true;
        })

        Column() {
          this.campusSectionTitle('▧', '校区简介')
          Text('西安工程大学临潼校区位于陕西省西安市临潼区陕鼓大道58号。北门面向陕鼓大道；校内有图书馆、大学生活动中心等导览地点。')
            .fontSize(14)
            .fontColor('#50616D')
            .lineHeight(23)
            .margin({ top: 14 })
            .width('100%')
        }
        .width('100%')
        .padding(18)
        .alignItems(HorizontalAlign.Start)
        .borderRadius(13)
        .backgroundColor(Color.White)
        .shadow({ radius: 14, color: '#140F5275', offsetY: 4 })

        Column() {
          this.campusSectionTitle('◎', '校园生活')
          Row() {
            this.campusFeature($r('app.media.campus_gate'), '北门', '#4C9CE7')
            this.campusFeature($r('app.media.campus_book'), '图书馆', '#43B6A4')
            this.campusFeature($r('app.media.campus_activity'), '活动中心', '#F4A13B')
            this.campusFeature($r('app.media.campus_sports'), '运动场', '#8B79DF')
          }
          .width('100%')
          .margin({ top: 18 })
        }
        .width('100%')
        .padding({ top: 18, bottom: 20, left: 12, right: 12 })
        .alignItems(HorizontalAlign.Start)
        .borderRadius(13)
        .backgroundColor(Color.White)
        .shadow({ radius: 14, color: '#140F5275', offsetY: 4 })

        Column() {
          this.campusSectionTitle('▥', '校区概况')
          Column() {
            this.campusInfoRow('校区名称', Campus.NAME, false)
            this.campusInfoRow('校区地址', Campus.ADDRESS, false)
            this.campusInfoRow('主要入口', '北门 · 陕鼓大道方向', false)
            this.campusInfoRow('导览地点', '图书馆 · 大学生活动中心', true)
          }
          .width('100%')
          .margin({ top: 10 })
        }
        .width('100%')
        .padding(18)
        .alignItems(HorizontalAlign.Start)
        .borderRadius(13)
        .backgroundColor(Color.White)
        .shadow({ radius: 14, color: '#140F5275', offsetY: 4 })
      }
      .width('100%')
      .padding({ top: 16, bottom: 28, left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor('#F2F6F8')
  }

  build() {
    Stack() {
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
        } else {
          Column() {
            Text(Campus.NAME)
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(Campus.ADDRESS)
              .fontSize(12)
              .fontColor('#DFECF3')
              .margin({ top: 4 })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12, left: 16, right: 16 })
          .alignItems(HorizontalAlign.Start)
          .backgroundColor('#165A82')
        }

        Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
          TabContent() {
            Map()
          }
          .tabBar(this.tabItem(0, '地图', $rawfile('ic_home.png'), $rawfile('ic_home_selected.png')))

          TabContent() {
            Zones()
          }
          .tabBar(this.tabItem(1, '区域', $rawfile('ic_find.png'), $rawfile('ic_find_selected.png')))

          TabContent() {
            this.travelPage()
          }
          .tabBar(this.tabItem(2, '出行', $rawfile('ic_drive.png'), $rawfile('ic_drive_selected.png')))

          TabContent() {
            this.campusPage()
          }
          .tabBar(this.tabItem(3, '校区', $rawfile('ic_user.png'), $rawfile('ic_user_selected.png')))
        }
        .layoutWeight(1)
        .width('100%')
        .vertical(false)
        .scrollable(false)
        .barHeight(62)
        .onChange((index: number) => {
          this.selectedTabIndex = index;
          this.isHeroExpanded = false;
        })
      }
      .width('100%')
      .height('100%')

      if (this.isHeroExpanded) {
        Image($rawfile('xpu_gate_source.png'))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .backgroundColor(Color.Black)
          .onClick(() => {
            this.isHeroExpanded = false;
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}
