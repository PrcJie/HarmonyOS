/**
 *  区域介绍单元类
 *
 *  延伸改造说明（Day3AM）：
 *  1. 文字、颜色资源原为 $r('app.string.xxx') / $r('app.color.xxx') 引用，
 *     现直接硬编码为具体字符串 / '#RRGGBB' 颜色值；
 *  2. 图片资源（缩略图、轮播图、建筑图等）无法硬编码，
 *     保持 $r('app.media.xxx') 资源引用不变；
 *  3. 文字字段类型由 ResourceStr 收窄为 string（ResourceStr 是
 *     Resource | string 的联合类型，收窄后仍兼容给 Text 等组件使用），
 *     图片字段保持 ResourceStr 以承接资源对象。
 *
 *  上午卡片堆叠页只用到 id / title / thumbnail / backgroundColor 四个字段，
 *  其余字段为下午详情页（SwiperListItem / SubTitleItem / BuildListItem）预留。
 *
 * @author 却家庭
 * @version 1.0
 * @date 2024.06.02
 */
export default class ZonesItem {
  // 区域编号（0~11，Zones 跳转详情页时作为路由参数传递）
  id: number = 0;
  // 区域名称（延伸改造：原为 $r('app.string.area_name_a')，现硬编码）
  title: string = 'A区牛津';
  // 区域副标题（延伸改造：原为 $r('app.string.area_sub_name_a')，现硬编码）
  subTitle: string = '追求极致的殿堂';
  // 建成年代说明（延伸改造：原为 $r('app.string.create_year_2015')，现硬编码）
  createTime: string = '始建于2015年';
  // 区域介绍正文段落（延伸改造：原为 $r('app.string.introduction_paragraph_*')，现硬编码）
  content: string[] = [];
  // 卡片缩略图（图片资源，保持 $r('app.media.xxx') 引用不变）
  thumbnail: ResourceStr = $r('app.media.ic_thumbnail_a');
  // 详情页首图轮播的大图（图片资源，保持引用不变）
  swiperPic: ResourceStr = $r('app.media.ic_A');
  // 详情页子标题块的上/下配图（图片资源，保持引用不变）
  subPicTop: ResourceStr = $r('app.media.ic_A_photo_top');
  subPicBottom: ResourceStr = $r('app.media.ic_A_photo_bottom');
  // 详情页标题装饰图标（图片资源，保持引用不变）
  titleIcon: ResourceStr = $r('app.media.ic_title_top_A');
  // 详情页图集列表（图片资源，保持引用不变）
  imageList: ResourceStr[] = [];
  // 建筑信息文本（延伸改造：原为 $r('app.string.build_information_a')，现硬编码）
  buildingInformation: string = 'A区总建筑面积达107637m2，其中地上建筑面积65625m2，地下建筑面积42011m2，定位为研发办公楼，设计容纳人数2343人，地下停车位694个，地上停车位50个，车位比例达32%。';
  // 建筑图（图片资源，保持引用不变）
  buildingPic: ResourceStr = $r('app.media.ic_building_A');
  // 地理位置图：暗色版（图片资源，保持引用不变）
  geographyPic: ResourceStr = $r('app.media.ic_geography_dark_A');
  // 地理位置图：亮色版（图片资源，保持引用不变）
  geographyPicLight: ResourceStr = $r('app.media.ic_geography_lighter_A');
  // 区域主题背景色（延伸改造：原为 $r('app.color.introduction_page_green')，现硬编码为 '#RRGGBB'）
  backgroundColor: string = '#346B41';
  // 星轨装饰图：亮色/暗色两张（图片资源，保持引用不变）
  starLinePic: ResourceStr[] = [];
}
