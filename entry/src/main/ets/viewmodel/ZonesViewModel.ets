import ZonesItem from './ZonesItem';

/**
 *  区域介绍显示模型类
 *
 *  延伸改造说明（Day3AM）：
 *  1. 12 个区域（A~L、M，跳过 I）的文字与颜色资源原为
 *     $r('app.string.xxx') / $r('app.color.xxx') 引用，现全部硬编码为具体值；
 *  2. 图片资源（缩略图、轮播图、图集、建筑图、星轨图等）无法硬编码，
 *     保持 $r('app.media.xxx') 资源引用不变；
 *  3. 取数方法 getZonesList / getZonesByIndex 与参考工程保持一致。
 *
 * @author 却家庭
 * @version 1.0
 * @date 2024.06.02
 */
class ZonesViewModel {
  // 返回全部区域列表（供 Zones 组件 ForEach 渲染堆叠卡片）
  getZonesList(): ZonesItem[] {
    return defaultList;
  }

  // 按下标取单个区域（供详情页根据路由参数取数据）
  getZonesByIndex(index: number): ZonesItem {
    return defaultList[index];
  }
}

// 单例导出：整个应用共享同一份数据模型，避免重复实例化
let zonesViewModel = new ZonesViewModel();

export default zonesViewModel as ZonesViewModel;

/* 12 个区域的原始数据（文字/颜色已硬编码，图片保持 $r('app.media.xxx') 引用）
 * 每个区域字段含义：
 *   id                 区域编号（路由传参用）
 *   title / subTitle   区域名称与副标题（原 $r('app.string.area_name_x') 等）
 *   createTime         建成年代（原 $r('app.string.create_year_2015')）
 *   content            介绍正文两段（原 $r('app.string.introduction_paragraph_*')）
 *   buildingInformation 建筑信息（原 $r('app.string.build_information_x')）
 *   backgroundColor    主题背景色（原 $r('app.color.introduction_*')）
 *   其余 thumbnail / swiperPic / imageList 等均为图片资源引用，保持不变 */
const defaultList: ZonesItem[] = [
  {
    id: 0,
    title: 'A区牛津',
    subTitle: '追求极致的殿堂',
    thumbnail: $r('app.media.ic_thumbnail_a'),
    swiperPic: $r('app.media.ic_A'),
    createTime: '始建于2015年',
    content: ['牛津是英国泰晤士河谷地的主要城市，传说在古代是牛群涉水而过的地方，因此取名“牛津”。坐落其中的牛津大学是英语世界中最古老的大学，也是世界上现存第二古老的高等教育机构。',
    'A区参考了牛津大学庄严的建筑风格和特征来进行创建，结合以灰色板石为材料的大坡度尖屋顶、米色莱姆石外墙、草坪里院和回廊，使整个街区都可以感受到犹如知识殿堂般的氛围。'],
    subPicTop: $r('app.media.ic_A_photo_top'),
    subPicBottom: $r('app.media.ic_A_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_A'),
    imageList: [$r('app.media.ic_A_1'), $r('app.media.ic_A_2'), $r('app.media.ic_A_3'), $r('app.media.ic_A_4'),
    $r('app.media.ic_A_5')],
    buildingInformation: 'A区总建筑面积达107637m2，其中地上建筑面积65625m2，地下建筑面积42011m2，定位为研发办公楼，设计容纳人数2343人，地下停车位694个，地上停车位50个，车位比例达32%。',
    buildingPic: $r('app.media.ic_building_A'),
    geographyPic: $r('app.media.ic_geography_dark_A'),
    geographyPicLight: $r('app.media.ic_geography_lighter_A'),
    // 原 $r('app.color.introduction_page_green')
    backgroundColor: '#346B41',
    starLinePic: [$r('app.media.ic_starLine_A_light'), $r('app.media.ic_starLine_A_dark')]
  },
  {
    id: 1,
    title: 'B区布鲁日',
    subTitle: '欧洲水城',
    thumbnail: $r('app.media.ic_thumbnail_b'),
    swiperPic: $r('app.media.ic_B'),
    createTime: '始建于2015年',
    content: ['布鲁日是比利时西北部的文化名城，是典型的中世纪古城：城区河道环绕，水巷纵横，并有运河通往北海岸外港，游客可以乘坐小艇观赏水城全貌。该地属温带海洋性气候，全年温和多雨，气候湿润，建筑以阶梯式陡坡屋顶为主。',
    'B区参考布鲁日连绵小建筑物的街区特点，结合红砖外墙、阶梯式陡坡屋顶和独具特色的钟塔、拱形石桥，形成了与自然环境完美契合的空间。'],
    subPicTop: $r('app.media.ic_B_photo_top'),
    subPicBottom: $r('app.media.ic_B_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_B'),
    imageList: [$r('app.media.ic_B_1'), $r('app.media.ic_B_2'), $r('app.media.ic_B_3'), $r('app.media.ic_B_4'),
    $r('app.media.ic_B_5')],
    buildingInformation: 'B区总建筑面积达107637m2，其中地上建筑面积65625m2，地下建筑面积42011m2，定位为研发办公楼，设计容纳人数2343人，地下停车位694个，地上停车位50个，车位比例达32%。',
    buildingPic: $r('app.media.ic_building_G'),
    geographyPic: $r('app.media.ic_geography_dark_B'),
    geographyPicLight: $r('app.media.ic_geography_lighter_B'),
    // 原 $r('app.color.introduction_b_page_blue')
    backgroundColor: '#82B9FB',
    starLinePic: [$r('app.media.ic_starLine_B_light'), $r('app.media.ic_starLine_B_dark')]
  },
  {
    id: 2,
    title: 'C区卢森堡',
    subTitle: '迷你童话小镇',
    thumbnail: $r('app.media.ic_thumbnail_c'),
    swiperPic: $r('app.media.ic_C'),
    createTime: '始建于2015年',
    content: ['卢森堡，因被法国、德国和比利时三国包围，国土小，古堡多，又有“袖珍王国”、“千堡之国”的称呼。卢森堡地形富于变化，地势险要，是一个高度发达的资本主义国家。',
    'C区借鉴卢森堡石墙和自然悬崖围绕的地貌特征，重现有着高低相间地形、错落有致的街巷，将2至3层的建筑布局在基地的低洼部分，4至5层的建筑布置在基地的高地部分，形成“丰富的街路空间”，再现一个童话般的小镇。'],
    subPicTop: $r('app.media.ic_C_photo_top'),
    subPicBottom: $r('app.media.ic_C_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_C'),
    imageList: [$r('app.media.ic_C_1'), $r('app.media.ic_C_2'), $r('app.media.ic_C_3'), $r('app.media.ic_C_4'),
    $r('app.media.ic_C_5')],
    buildingInformation: 'C区总建筑面积达107637m2，其中地上建筑面积65625m2，地下建筑面积42011m2，定位为研发办公楼，设计容纳人数2343人，地下停车位694个，地上停车位50个，车位比例达32%。',
    buildingPic: $r('app.media.ic_building_C'),
    geographyPic: $r('app.media.ic_geography_dark_C'),
    geographyPicLight: $r('app.media.ic_geography_lighter_C'),
    // 原 $r('app.color.introduction_c_page_blue')
    backgroundColor: '#84C6E2',
    starLinePic: [$r('app.media.ic_starLine_C_light'), $r('app.media.ic_starLine_C_dark')]
  },
  {
    id: 3,
    title: 'D区温德米尔',
    subTitle: '英格兰湖光山色',
    thumbnail: $r('app.media.ic_thumbnail_d'),
    swiperPic: $r('app.media.ic_D'),
    createTime: '始建于2015年',
    content: ['温德米尔位于英格兰西北海岸，是英格兰最大的自然湖区，英格兰最受欢迎的度假胜地之一，被英国人自己称为“后花园”。温德米尔是英格兰国家公园的一部分，夏季有游艇娱乐活动，是著名的旅游中心。',
    'D区参考温德米尔群山与湖畔融为一体的特色，形成了连绵到湖畔水面的草坪广场，自然石材砌就的墙面，组合呈现出田园风情。'],
    subPicTop: $r('app.media.ic_D_photo_top'),
    subPicBottom: $r('app.media.ic_D_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_D'),
    imageList: [$r('app.media.ic_D_1'), $r('app.media.ic_D_2'), $r('app.media.ic_D_3'), $r('app.media.ic_D_4'),
    $r('app.media.ic_D_5')],
    buildingInformation: 'D区总建筑面积达107637m2，其中地上建筑面积65625m2，地下建筑面积42011m2，定位为研发办公楼，设计容纳人数2343人，地下停车位694个，地上停车位50个，车位比例达32%。',
    buildingPic: $r('app.media.ic_building_D'),
    geographyPic: $r('app.media.ic_geography_dark_D'),
    geographyPicLight: $r('app.media.ic_geography_lighter_D'),
    // 原 $r('app.color.introduction_d_page_blue')
    backgroundColor: '#8EA9D2',
    starLinePic: [$r('app.media.ic_starLine_D_light'), $r('app.media.ic_starLine_D_dark')]
  },
  {
    id: 4,
    title: 'E区格拉纳达',
    subTitle: '文明交汇之城',
    thumbnail: $r('app.media.ic_thumbnail_e'),
    swiperPic: $r('app.media.ic_E'),
    createTime: '始建于2015年',
    content: ['西班牙格拉纳达，位于内华达山山麓，达若河和赫尼尔河汇合处，主要以穆斯林、地中海风格为主。这里曾是阿拉伯人在伊比利亚半岛上的最后一个王国的首都，也有基督教文艺复兴时期的建筑瑰宝，有着星罗棋布的历史文化遗产和传说。',
    'E区借鉴格拉纳达建筑风格，整个组团布局在自然地形的小山丘上，建筑参考极致精巧的阿尔罕布拉宫的一些设计要素，结合西班牙街区的特有风格，形成了别具一格、闪烁着东方魅力的建筑设计和街区气息。'],
    subPicTop: $r('app.media.ic_E_photo_top'),
    subPicBottom: $r('app.media.ic_E_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_E'),
    imageList: [$r('app.media.ic_E_1'), $r('app.media.ic_E_2'), $r('app.media.ic_E_3'), $r('app.media.ic_E_4'),
    $r('app.media.ic_E_5')],
    buildingInformation: 'E区总建筑面积达107637m2，其中地上建筑面积65625m2，地下建筑面积42011m2，定位为研发办公楼，设计容纳人数2343人，地下停车位694个，地上停车位50个，车位比例达32%。',
    buildingPic: $r('app.media.ic_building_E'),
    geographyPic: $r('app.media.ic_geography_dark_E'),
    geographyPicLight: $r('app.media.ic_geography_lighter_E'),
    // 原 $r('app.color.introduction_page_orange_dark')
    backgroundColor: '#B88668',
    starLinePic: [$r('app.media.ic_starLine_E_lighter'), $r('app.media.ic_starLine_E_dark')]
  },
  {
    id: 5,
    title: 'F区巴黎',
    subTitle: '文化之都，法式浪漫',
    thumbnail: $r('app.media.ic_thumbnail_f'),
    swiperPic: $r('app.media.ic_F'),
    createTime: '始建于2015年',
    content: ['巴黎作为法国的首都和最大城市，也是法国的政治、经济、文化和商业中心，是世界五个国际大都市之一，位于法国北部巴黎盆地的中央，横跨塞纳河两岸。巴黎建都已有1400多年的历史，又叫“浪漫之都”，被认为是现代奥林匹克运动的起点。',
    'F区建筑参考巴黎风格，呈现出浪漫的法国哥特式风情，设计理念借鉴了巴黎国际大学城富丽堂皇的建筑特色，通过华丽的装饰、极富特色的法式凸窗以及米黄的莱姆石，抽象出最为法式的雅致考究，彰显了浓郁的欧洲风情。'],
    subPicTop: $r('app.media.ic_F_photo_top'),
    subPicBottom: $r('app.media.ic_F_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_F'),
    imageList: [$r('app.media.ic_F_1'), $r('app.media.ic_F_2'), $r('app.media.ic_F_3'), $r('app.media.ic_F_4'),
    $r('app.media.ic_F_5')],
    buildingInformation: 'F区总建筑面积达118944m2，其中地上建筑面积63134m2，地下建筑面积55810m2，定位为行政中心，设计容纳人数2255人，地下停车位786个，地上停车位0个，车位比例达34.9%。',
    buildingPic: $r('app.media.ic_building_F'),
    geographyPic: $r('app.media.ic_geography_lighter_F'),
    geographyPicLight: $r('app.media.ic_geography_lighter_F'),
    // 原 $r('app.color.introduction_page_orange_light')
    backgroundColor: '#E5A77D',
    starLinePic: [$r('app.media.ic_starLine_F_lighter'), $r('app.media.ic_starLine_F_dark')]
  },
  {
    id: 6,
    title: 'G区维罗纳',
    subTitle: '最浪漫的小镇',
    thumbnail: $r('app.media.ic_thumbnail_g'),
    swiperPic: $r('app.media.ic_G'),
    createTime: '始建于2015年',
    content: ['维罗纳是意大利最古老、最美丽的城市之一，是仅次于威尼斯的第二大城市，盛产葡萄酒和著名的维罗纳大理石。维罗纳也被称作是爱之城，莎士比亚笔下的罗密欧与朱丽叶的爱情故事就发生在这里。',
    'G区整体建筑设计风格为意大利风格，吸取罗密欧和朱丽叶的浪漫之意，号称最浪漫的小镇。有着威尼斯水城的旅游特色，是唯一一个被水四面环绕的小镇，7座桥让你恍若穿越，充满意大利人的天真烂漫气息。建筑材料主要采用陶砖陶瓦、黄沙岩石头等。'],
    subPicTop: $r('app.media.ic_G_photo_top'),
    subPicBottom: $r('app.media.ic_G_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_G'),
    imageList: [$r('app.media.ic_G_1'), $r('app.media.ic_G_2'), $r('app.media.ic_G_3'), $r('app.media.ic_G_4'),
    $r('app.media.ic_G_5')],
    buildingInformation: 'G区总建筑面积达120231m2，其中地上建筑面积61718m2，地下建筑面积58513m2，定位为研发办公楼，设计容纳人数2204人，车位比例达43.6%。',
    buildingPic: $r('app.media.ic_building_G'),
    geographyPic: $r('app.media.ic_geography_dark_G'),
    geographyPicLight: $r('app.media.ic_geography_lighter_G'),
    // 原 $r('app.color.introduction_page_blue')
    backgroundColor: '#244050',
    starLinePic: [$r('app.media.ic_starLine_G_light'), $r('app.media.ic_starLine_G_dark')]
  },
  {
    id: 7,
    title: 'H区科伦洛夫',
    subTitle: '最美丽的小镇',
    thumbnail: $r('app.media.ic_thumbnail_h'),
    swiperPic: $r('app.media.ic_H'),
    createTime: '始建于2015年',
    content: ['克伦诺夫是捷克共和国的一个小城镇，在德语中意为“高低不平的草地”，被称为欧洲最美丽的古老小镇，该镇于1992年被联合国教科文组织列为世界文化遗产和自然遗产。',
    'H区设计理念参考了捷克克伦诺夫的城堡、教堂、修道院等大型建筑的建筑特色，整合蜿蜒曲折、壮丽秀美的河流，构成了让人心旷神怡的步行空间，带有古朴典雅风情。'],
    subPicTop: $r('app.media.ic_H_photo_top'),
    subPicBottom: $r('app.media.ic_H_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_H'),
    imageList: [$r('app.media.ic_H_1'), $r('app.media.ic_H_2'), $r('app.media.ic_H_3'), $r('app.media.ic_H_4'),
    $r('app.media.ic_H_5')],
    buildingInformation: 'H区总建筑面积达120231m2，其中地上建筑面积61718m2，地下建筑面积58513m2，定位为研发办公楼，设计容纳人数2204人，车位比例达43.6%。',
    buildingPic: $r('app.media.ic_building_H'),
    geographyPic: $r('app.media.ic_geography_dark_H'),
    geographyPicLight: $r('app.media.ic_geography_lighter_H'),
    // 原 $r('app.color.introduction_page_blue_light')
    backgroundColor: '#83AEDB',
    starLinePic: [$r('app.media.ic_starLine_H_light'), $r('app.media.ic_starLine_H_dark')]
  },
  {
    id: 8,
    title: 'J区弗里堡',
    subTitle: '意大利中世纪小城',
    thumbnail: $r('app.media.ic_thumbnail_j'),
    swiperPic: $r('app.media.ic_J'),
    createTime: '始建于2015年',
    content: ['弗里堡位于瑞士德语区和法语区的交界处，保留了中世纪风貌，哥特式建筑赋予了这座古城无与伦比的风格与魅力，有瑞士保存最完好的由石头铺成的小径、坡路和天主教教堂。它位于瑞士高原的一座山上，老城区只有约100米宽，比紧挨着的谷底高出40米。',
    'J区借鉴了弗里堡的中世纪古城风格，以白墙红瓦的淡色系建筑为主。根据用地起伏、靠近松山湖水域的地理位置特点，结合瑞士具有历史性的古城和修道院建筑特色，通过棕红色瓦斜坡屋顶和绿色砂岩外墙等特征，打造了面向湖畔的斜面风景。'],
    subPicTop: $r('app.media.ic_J_photo_top'),
    subPicBottom: $r('app.media.ic_J_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_J'),
    imageList: [$r('app.media.ic_J_1'), $r('app.media.ic_J_2'), $r('app.media.ic_J_3'), $r('app.media.ic_J_4'),
    $r('app.media.ic_J_5')],
    buildingInformation: 'J区总建筑面积达90907m2，其中地上建筑面积50007m2，地下建筑面积40899m2，定位为行政中心，设计容纳人数1786人，地下停车位636个，地上停车位7个，车位比例达36%。',
    buildingPic: $r('app.media.ic_building_J'),
    geographyPic: $r('app.media.ic_geography_dark_J'),
    geographyPicLight: $r('app.media.ic_geography_lighter_J'),
    // 原 $r('app.color.introduction_page_red')
    backgroundColor: '#AF525A',
    starLinePic: [$r('app.media.ic_starLine_J_lighter'), $r('app.media.ic_starLine_J_dark')]
  },
  {
    id: 9,
    title: 'K区勃艮第',
    subTitle: '葡萄酒圣地',
    thumbnail: $r('app.media.ic_thumbnail_k'),
    swiperPic: $r('app.media.ic_K'),
    createTime: '始建于2015年',
    content: ['勃艮第地区位于法国巴黎南部，日照充足，是世界闻名的葡萄酒产区，主要出产酒体从中等到丰满的红葡萄酒，以及干白葡萄酒。勃艮第生产的葡萄酒单宁和酒精含量较低，酸度中高。',
    'K区以勃艮第为模板，借鉴了枫德内修道院、昂诺克西奥街区以及以棕红色屋顶为特征的瑟米尔，利用现代工艺和手法将其进行重塑，形成了特有的建筑风貌。'],
    subPicTop: $r('app.media.ic_K_photo_top'),
    subPicBottom: $r('app.media.ic_K_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_K'),
    imageList: [$r('app.media.ic_K_1'), $r('app.media.ic_K_2'), $r('app.media.ic_K_3'), $r('app.media.ic_K_4'),
    $r('app.media.ic_K_5')],
    buildingInformation: 'K区总建筑面积达99828m2，其中地上建筑面积38187m2，地下建筑面积61641m2，定位为研发办公楼，设计容纳人数1364人，地下停车位1061个，地上停车位7个，车位比例达77.8%。',
    buildingPic: $r('app.media.ic_building_K'),
    geographyPic: $r('app.media.ic_geography_dark_K'),
    geographyPicLight: $r('app.media.ic_geography_lighter_K'),
    // 原 $r('app.color.introduction_page_green_lighter')
    backgroundColor: '#769D33',
    starLinePic: [$r('app.media.ic_starLine_K_light'), $r('app.media.ic_starLine_K_dark')]
  },
  {
    id: 10,
    title: 'L区海德尔堡',
    subTitle: '历史悠久的文化名城',
    thumbnail: $r('app.media.ic_thumbnail_l'),
    swiperPic: $r('app.media.ic_L'),
    createTime: '始建于2015年',
    content: ['海德堡是德国一个传统和现代混合的充满活力的城市，拥有欧洲最古老的教育机构之一——海德堡大学，其成立于1386年，著名思想家黑格尔曾在海德堡大学学习与工作。如今的海德堡声望不减当年，由于城内1∕5人口为学生，海德堡是全德平均年龄最小的城市。红褐色古城堡是海德堡城的标志。',
    'L区建筑以海德堡建筑风格为主，大多为白墙红瓦的老城建筑。设计参考了在人文科学上闻名、并在德国具有最悠久历史的海德堡大学，以红砂岩外墙和传统街区构成建筑群，布置在小山丘上细致而雄伟的城堡与由网格状道路构成的街区形成了鲜明的对比。'],
    subPicTop: $r('app.media.ic_L_photo_top'),
    subPicBottom: $r('app.media.ic_L_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_L'),
    imageList: [$r('app.media.ic_L_1'), $r('app.media.ic_L_2'), $r('app.media.ic_L_3'), $r('app.media.ic_L_4'),
    $r('app.media.ic_L_5')],
    buildingInformation: 'L区总建筑面积达123823m2，其中地上建筑面积58934m2，地下建筑面积64890m2，定位为研发办公楼，设计容纳人数2105人，地下停车位1213个，地上停车位0个，车位比例达57.6%。',
    buildingPic: $r('app.media.ic_building_L'),
    geographyPic: $r('app.media.ic_geography_dark_L'),
    geographyPicLight: $r('app.media.ic_geography_lighter_L'),
    // 原 $r('app.color.introduction_page_red_light')
    backgroundColor: '#DC9187',
    starLinePic: [$r('app.media.ic_starLine_L_light'), $r('app.media.ic_starLine_L_dark')]
  },
  {
    id: 11,
    title: 'M区博洛尼亚',
    subTitle: '意大利柱廊之城',
    thumbnail: $r('app.media.ic_thumbnail_m'),
    swiperPic: $r('app.media.ic_M'),
    createTime: '始建于2015年',
    content: ['博洛尼亚是意大利北部的历史文化名城，是意大利最古老的城市之一。博洛尼亚经常被列为意大利生活质量最高的城市之一，这是由于博洛尼亚拥有强大的工业传统和广泛且高度发达的社会福利。这里到处可见环绕建筑物的柱廊，有相对简洁的中世纪作品、构图严格的哥特时期作品、华丽的文艺复兴式作品，还有厚重的巴罗克式作品。',
    'M区取样于博洛尼亚，建筑密集，主要以走廊形式的修筑风格为主。设计理念参考了“柱廊之城”连续不断回廊的设计风格，整合了塔、文艺复兴时期的宫殿、哥特式教堂等古代建筑特色，在每栋大建筑物的前方都建有华丽的柱廊。平时人们可在廊中行走，免受日晒雨淋。'],
    subPicTop: $r('app.media.ic_M_photo_top'),
    subPicBottom: $r('app.media.ic_M_photo_bottom'),
    titleIcon: $r('app.media.ic_title_top_M'),
    imageList: [$r('app.media.ic_M_1'), $r('app.media.ic_M_2'), $r('app.media.ic_M_3'), $r('app.media.ic_M_4'),
    $r('app.media.ic_M_5')],
    buildingInformation: 'M区总建筑面积达112133m2，其中地上建筑面积70672m2，地下建筑面积41461m2，定位为研发办公楼，设计容纳人数2524人，地下停车位679个，地上停车位0个，车位比例达26.9%。',
    buildingPic: $r('app.media.ic_building_M'),
    geographyPic: $r('app.media.ic_geography_dark_M'),
    geographyPicLight: $r('app.media.ic_geography_lighter_M'),
    // 原 $r('app.color.introduction_page_blue_lighter')
    backgroundColor: '#8ECCE7',
    starLinePic: [$r('app.media.ic_starLine_M_light'), $r('app.media.ic_starLine_M_dark')]
  }
]
