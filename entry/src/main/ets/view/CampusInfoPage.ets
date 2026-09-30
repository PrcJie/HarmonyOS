import { Campus } from '../common/Campus';

/** Nav 项目的第 4 个页面：临潼校区信息。 */
@Component
export struct CampusInfoPage {
  @State private isHeroExpanded: boolean = false;

  @Builder
  private campusSectionTitle(symbol: string, title: string) {
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
  private campusFeature(icon: Resource, label: string, color: string) {
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
  private campusInfoRow(label: string, value: string, isLast: boolean) {
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
  private campusPage() {
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
      this.campusPage()

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
