import { AnimationItem } from '../../viewmodel/AnimationItem'
export class Animation {
  //根据列表滚动距离,同步章节标题图标和地理位置图片
  public static changeTitleIcon(animationItem: AnimationItem) {
    let imageHeightVP = (animationItem.screenHeight * animationItem.imageHeight) / 100;
    let firstStarLine = imageHeightVP + 350 + animationItem.styleHeight - 80;
    let secondStarLine = firstStarLine + 500;
    // 以 Scroller 的实际纵向偏移为准,避免每次滚动重复累加造成页面组件偏移
    animationItem.offsetSum = animationItem.scrollerForList.currentOffset().yOffset;
    if (animationItem.offsetSum > 10) {
      animationItem.listPosition = 1;
    }
    // 越过首条线后的半个内容块时切换地图配图
    if (animationItem.offsetSum > firstStarLine + 500 / 2) {
      if (animationItem.geographicPicType !== 'geography_light') {
        animationItem.geographicPicType = 'geography_light';
      }
    }
    if (animationItem.offsetSum <= firstStarLine + 500 / 2) {
      if (animationItem.geographicPicType !== 'geography_dark') {
        animationItem.geographicPicType = 'geography_dark';
      }
    }
    if (animationItem.currentListIndex === 2) {
      // 将当前滚动区间映射到设计、建筑和地理三个章节
      let targetIndex = 0;
      if (animationItem.offsetSum >= secondStarLine) {
        targetIndex = 2;
      } else if (animationItem.offsetSum > firstStarLine) {
        targetIndex = 1;
      }
      let targetTitles: Array<string> = ['DESIGN STYLE', 'BUILDING INFORMATION', 'GEOGRAPHIC LOCATION'];
      // 同一时刻只显示当前章节对应的图标
      let targetScales: Array<Array<number>> = [[1, 0, 0], [0, 1, 0], [0, 0, 1]];
      if (animationItem.iconTitle !== targetTitles[targetIndex]) {
        animationItem.iconTitle = targetTitles[targetIndex];
      }
      let targetScale = targetScales[targetIndex];
      let isSame = animationItem.scaleIcon.length === targetScale.length;
      for (let i = 0; isSame && i < targetScale.length; i++) {
        if (animationItem.scaleIcon[i] !== targetScale[i]) {
          isSame = false;
        }
      }
      if (!isSame) {
        animationItem.scaleIcon = targetScale;
      }
    }
  }
  //优先滚动偏移缩放首图,再把剩余偏移还给列表
  public static controlImageScale(animationItem: AnimationItem, offset: number, state: ScrollState): number {
    if (animationItem.screenHeight <= 0) {
      return offset;
    }
    // 把滚动距离换算为屏幕高度的百分比,首图最小保留 40%
    if ((offset > 0) && (animationItem.imageHeight > 40)) {
      let offsetHeight = (Math.abs(offset) * 100) / Number(animationItem.screenHeight);
      let heightOffset = animationItem.imageHeight - 40 > offsetHeight ?
        offsetHeight : animationItem.imageHeight - 40;
      animationItem.imageHeight = animationItem.imageHeight - heightOffset;
      animationItem.arrowIconOpacity = Math.max(0, 1 - (100 - animationItem.imageHeight) / 60);
      return offset - heightOffset * animationItem.screenHeight / 100;
    }
    if ((animationItem.listPosition === 0) && (offset < 0) && (animationItem.imageHeight < 100)) {
      let offsetHeight = (Math.abs(offset) * 100) / Number(animationItem.screenHeight);
      let heightOffset = 100 - animationItem.imageHeight > offsetHeight ?
        offsetHeight : 100 - animationItem.imageHeight;
      const imageHeight: number = animationItem.imageHeight;
      animationItem.imageHeight = imageHeight + heightOffset;
      animationItem.arrowIconOpacity = Math.min(1, 1 - (100 - animationItem.imageHeight) / 60);
      return offset + heightOffset * animationItem.screenHeight / 100;
    }
    if ((state === ScrollState.Scroll) && (offset < -40) && (animationItem.imageHeight === 100)) {
      return 0;
    }
    return offset;
  }
}
