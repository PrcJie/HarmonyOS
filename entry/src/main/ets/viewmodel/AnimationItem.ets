@Observed
export class AnimationItem{
  screenHeight : number = 0;
  // 当前列表的纵向滚动距离，供 Animation 根据滚动位置切换标题和图片。
  offsetSum : number = 0
  scrollerForList : Scroller = new  Scroller()
  arrowIconOpacity : number = 1
  imageHeight : number = 100
  styleHeight : number = 500
  listPosition : number = 0
  // 这些状态由 Animation.changeTitleIcon 直接更新，字段名须与动画逻辑一致。
  geographicPicType : string = "geography_light"
  iconTitle : string = "DESIGN STYLE"
  scaleIcon : Array<number> = [1,0,0]
  currentListIndex : number = 0
}
