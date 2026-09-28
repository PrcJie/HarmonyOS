const fs = require('fs');
const path = require('path');

// ============================================================================
// Robust 3D Mesh Geometry Builder (Strict CCW Winding, Proper Normals)
// ============================================================================

class MeshBuilder {
  constructor() {
    this.positions = [];
    this.normals = [];
    this.indices = [];
  }

  // Add quad with CCW winding: p0 -> p1 -> p2, p0 -> p2 -> p3
  addQuad(p0, p1, p2, p3, norm) {
    const base = this.positions.length / 3;
    this.positions.push(...p0, ...p1, ...p2, ...p3);
    this.normals.push(...norm, ...norm, ...norm, ...norm);
    this.indices.push(base, base + 1, base + 2, base, base + 2, base + 3);
  }

  // Solid Box with guaranteed CCW outward normals
  addBox(x0, y0, z0, x1, y1, z1) {
    // Top (+Y): looking down from +Y, CCW is (x0,z1) -> (x1,z1) -> (x1,z0) -> (x0,z0)
    this.addQuad(
      [x0, y1, z1], [x1, y1, z1], [x1, y1, z0], [x0, y1, z0],
      [0, 1, 0]
    );
    // Bottom (-Y): looking up from -Y, CCW is (x0,z0) -> (x1,z0) -> (x1,z1) -> (x0,z1)
    this.addQuad(
      [x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1],
      [0, -1, 0]
    );
    // Front (+Z): looking from +Z towards -Z, CCW is (x0,y0) -> (x1,y0) -> (x1,y1) -> (x0,y1)
    this.addQuad(
      [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1],
      [0, 0, 1]
    );
    // Back (-Z): looking from -Z towards +Z, CCW is (x1,y0) -> (x0,y0) -> (x0,y1) -> (x1,y1)
    this.addQuad(
      [x1, y0, z0], [x0, y0, z0], [x0, y1, z0], [x1, y1, z0],
      [0, 0, -1]
    );
    // Right (+X): looking from +X towards -X, CCW is (z1,y0) -> (z0,y0) -> (z0,y1) -> (z1,y1)
    this.addQuad(
      [x1, y0, z1], [x1, y0, z0], [x1, y1, z0], [x1, y1, z1],
      [1, 0, 0]
    );
    // Left (-X): looking from -X towards +X, CCW is (z0,y0) -> (z1,y0) -> (z1,y1) -> (z0,y1)
    this.addQuad(
      [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0],
      [-1, 0, 0]
    );
  }

  // Architectural Building Block with Plinth and Roof Parapet
  addBuildingBlock(x0, z0, x1, z1, height, parapet = 0.5) {
    // Main Body
    this.addBox(x0, 0, z0, x1, height, z1);
    // Parapet roof border (gives realistic architectural shadow)
    if (parapet > 0) {
      const pW = 0.4;
      this.addBox(x0, height, z0, x1, height + parapet, z0 + pW); // North parapet
      this.addBox(x0, height, z1 - pW, x1, height + parapet, z1); // South parapet
      this.addBox(x0, height, z0, x0 + pW, height + parapet, z1); // West parapet
      this.addBox(x1 - pW, height, z0, x1, height + parapet, z1); // East parapet
    }
  }

  // Hollow Courtyard Building ("回"字形)
  addCourtyardBuilding(x0, z0, x1, z1, courtW, courtD, height) {
    const midX = (x0 + x1) / 2;
    const midZ = (z0 + z1) / 2;
    const cx0 = midX - courtW / 2;
    const cx1 = midX + courtW / 2;
    const cz0 = midZ - courtD / 2;
    const cz1 = midZ + courtD / 2;

    // 4 wings around courtyard
    this.addBuildingBlock(x0, z0, x1, cz0, height); // North wing
    this.addBuildingBlock(x0, cz1, x1, z1, height); // South wing
    this.addBuildingBlock(x0, cz0, cx0, cz1, height); // West wing
    this.addBuildingBlock(cx1, cz0, x1, cz1, height); // East wing
  }

  // U-Shaped Building ("凹"字形)
  addUShapeBuilding(x0, z0, x1, z1, openDir, depthRatio, height) {
    // openDir: 'E' (East), 'W' (West), 'S' (South), 'N' (North)
    const w = x1 - x0;
    const d = z1 - z0;
    const wingThickness = Math.min(w, d) * depthRatio;

    if (openDir === 'E') {
      this.addBuildingBlock(x0, z0, x0 + wingThickness, z1, height); // West spine
      this.addBuildingBlock(x0 + wingThickness, z0, x1, z0 + wingThickness, height); // North wing
      this.addBuildingBlock(x0 + wingThickness, z1 - wingThickness, x1, z1, height); // South wing
    } else if (openDir === 'W') {
      this.addBuildingBlock(x1 - wingThickness, z0, x1, z1, height); // East spine
      this.addBuildingBlock(x0, z0, x1 - wingThickness, z0 + wingThickness, height); // North wing
      this.addBuildingBlock(x0, z1 - wingThickness, x1 - wingThickness, z1, height); // South wing
    } else if (openDir === 'S') {
      this.addBuildingBlock(x0, z0, x1, z0 + wingThickness, height); // North spine
      this.addBuildingBlock(x0, z0 + wingThickness, x0 + wingThickness, z1, height); // West wing
      this.addBuildingBlock(x1 - wingThickness, z0 + wingThickness, x1, z1, height); // East wing
    } else { // 'N'
      this.addBuildingBlock(x0, z1 - wingThickness, x1, z1, height); // South spine
      this.addBuildingBlock(x0, z0, x0 + wingThickness, z1 - wingThickness, height); // West wing
      this.addBuildingBlock(x1 - wingThickness, z0, x1, z1 - wingThickness, height); // East wing
    }
  }

  // E-Shaped Building (Comb shape / 3 wings)
  addEShapeBuilding(x0, z0, x1, z1, height) {
    const spineW = (x1 - x0) * 0.35;
    const wingH = (z1 - z0) * 0.22;
    // West spine
    this.addBuildingBlock(x0, z0, x0 + spineW, z1, height);
    // 3 East wings
    this.addBuildingBlock(x0 + spineW, z0, x1, z0 + wingH, height);
    this.addBuildingBlock(x0 + spineW, (z0 + z1)/2 - wingH/2, x1, (z0 + z1)/2 + wingH/2, height);
    this.addBuildingBlock(x0 + spineW, z1 - wingH, x1, z1, height);
  }

  // Curved Cylinder / Dome (Rotunda)
  addCylinder(cx, cy, cz, radius, height, segments = 24) {
    const yBot = cy;
    const yTop = cy + height;

    for (let i = 0; i < segments; i++) {
      const a0 = (i / segments) * Math.PI * 2;
      const a1 = ((i + 1) / segments) * Math.PI * 2;
      const cos0 = Math.cos(a0), sin0 = Math.sin(a0);
      const cos1 = Math.cos(a1), sin1 = Math.sin(a1);

      const p0 = [cx + cos0 * radius, yBot, cz + sin0 * radius];
      const p1 = [cx + cos1 * radius, yBot, cz + sin1 * radius];
      const p2 = [cx + cos1 * radius, yTop, cz + sin1 * radius];
      const p3 = [cx + cos0 * radius, yTop, cz + sin0 * radius];
      const norm = [(cos0 + cos1) / 2, 0, (sin0 + sin1) / 2];

      this.addQuad(p0, p1, p2, p3, norm);

      // Top cap (CCW looking down)
      const tCenter = [cx, yTop, cz];
      const base = this.positions.length / 3;
      this.positions.push(...tCenter, ...p3, ...p2);
      this.normals.push(0, 1, 0, 0, 1, 0, 0, 1, 0);
      this.indices.push(base, base + 1, base + 2);
    }
  }

  // Curved Arc Ribbon (for 45 会展中心)
  addCurvedArc(cx, cz, rInner, rOuter, angleStart, angleEnd, height, segments = 16) {
    const rad0 = (angleStart * Math.PI) / 180;
    const rad1 = (angleEnd * Math.PI) / 180;

    for (let i = 0; i < segments; i++) {
      const t0 = rad0 + (rad1 - rad0) * (i / segments);
      const t1 = rad0 + (rad1 - rad0) * ((i + 1) / segments);

      const cos0 = Math.cos(t0), sin0 = Math.sin(t0);
      const cos1 = Math.cos(t1), sin1 = Math.sin(t1);

      const pIn0 = [cx + cos0 * rInner, 0, cz + sin0 * rInner];
      const pIn1 = [cx + cos1 * rInner, 0, cz + sin1 * rInner];
      const pOut0 = [cx + cos0 * rOuter, 0, cz + sin0 * rOuter];
      const pOut1 = [cx + cos1 * rOuter, 0, cz + sin1 * rOuter];

      const pInTop0 = [pIn0[0], height, pIn0[2]];
      const pInTop1 = [pIn1[0], height, pIn1[2]];
      const pOutTop0 = [pOut0[0], height, pOut0[2]];
      const pOutTop1 = [pOut1[0], height, pOut1[2]];

      // Roof quad
      this.addQuad(pInTop0, pInTop1, pOutTop1, pOutTop0, [0, 1, 0]);
      // Outer curved wall
      this.addQuad(pOut0, pOut1, pOutTop1, pOutTop0, [(cos0 + cos1)/2, 0, (sin0 + sin1)/2]);
      // Inner curved wall
      this.addQuad(pIn1, pIn0, pInTop0, pInTop1, [-(cos0 + cos1)/2, 0, -(sin0 + sin1)/2]);
    }
  }
}

// ============================================================================
// Precise Campus Geometry Assembly
// ============================================================================

// PBR Material Colors matching the original map legend
const MAT_BUILT = {
  name: 'Mat_Built_Buildings',
  baseColor: [0.96, 0.72, 0.18, 1.0], // 🟨 Warm amber golden built buildings
  roughness: 0.55,
  metallic: 0.1
};
const MAT_PLAN = {
  name: 'Mat_Planned_Buildings',
  baseColor: [0.38, 0.72, 0.96, 1.0], // 🟦 Contemporary sky blue planned buildings
  roughness: 0.45,
  metallic: 0.15
};
const MAT_GROUND = {
  name: 'Mat_Campus_Ground',
  baseColor: [0.88, 0.89, 0.85, 1.0], // Paved walkways & plazas
  roughness: 0.85,
  metallic: 0.0
};
const MAT_GRASS = {
  name: 'Mat_Green_Spaces',
  baseColor: [0.36, 0.72, 0.32, 1.0], // 🟩 Vibrant campus lawns
  roughness: 0.9,
  metallic: 0.0
};
const MAT_ROAD = {
  name: 'Mat_Outer_Roads',
  baseColor: [0.52, 0.53, 0.56, 1.0], // Asphalt avenues
  roughness: 0.8,
  metallic: 0.05
};
const MAT_WATER = {
  name: 'Mat_Landscape_Lake',
  baseColor: [0.42, 0.78, 0.92, 0.92], // Scenic lake water
  roughness: 0.15,
  metallic: 0.1
};
const MAT_TRACK = {
  name: 'Mat_Stadium_Track',
  baseColor: [0.86, 0.34, 0.26, 1.0], // Terracotta stadium track
  roughness: 0.75,
  metallic: 0.0
};
const MAT_PITCH = {
  name: 'Mat_Soccer_Pitch',
  baseColor: [0.24, 0.65, 0.28, 1.0], // Turf green
  roughness: 0.85,
  metallic: 0.0
};
const MAT_COURT = {
  name: 'Mat_Basketball_Courts',
  baseColor: [0.32, 0.56, 0.74, 1.0], // Blue-cyan outdoor sports court
  roughness: 0.8,
  metallic: 0.0
};

const nodesList = [];

function registerEntity(id, name, desc, isBuilt, builder, material, center) {
  nodesList.push({
    id,
    name,
    desc,
    isBuilt,
    mesh: {
      positions: builder.positions,
      normals: builder.normals,
      indices: builder.indices
    },
    material,
    center
  });
}

// ----------------------------------------------------------------------------
// 1. BASE TERRAIN & ENVIRONMENT
// ----------------------------------------------------------------------------
{
  const b = new MeshBuilder();
  // Large main ground slab
  b.addBox(-85, -0.6, -125, 85, 0, 130);
  registerEntity(null, 'Campus_Ground_Plaza', '校园硬化广场地面', true, b, MAT_GROUND, [0, 0, 0]);
}

// Green Lawns
{
  const b = new MeshBuilder();
  // North academic lawn
  b.addBox(-65, 0, -100, 65, 0.05, -20);
  // South living lawn
  b.addBox(-65, 0, -18, 65, 0.05, 120);
  registerEntity(null, 'Campus_Green_Spaces', '校园绿化与草坪景观', true, b, MAT_GRASS, [0, 0, 0]);
}

// Outer Perimeter Roads (陕鼓大道, 凤凰大道, 大学路, 规划一路)
{
  const b = new MeshBuilder();
  b.addBox(-85, 0, -120, 85, 0.08, -108); // 陕鼓大道 (North)
  b.addBox(-84, 0, -115, -68, 0.08, -25); // 凤凰大道 (NW diagonal)
  b.addBox(68, 0, -115, 84, 0.08, 125);   // 大学路 (East)
  b.addBox(-75, 0, 118, 84, 0.08, 128);   // 规划一路 (South)
  registerEntity(null, 'Outer_Avenues', '城市主干道与环校大道', true, b, MAT_ROAD, [0, 0, 0]);
}

// Central Lake (景观湖泊水系)
{
  const b = new MeshBuilder();
  b.addBox(12, 0.06, -2, 28, 0.12, 26);
  registerEntity(null, 'Landscape_Lake', '中央景观湖泊与生态水系', true, b, MAT_WATER, [20, 0, 12]);
}

// ----------------------------------------------------------------------------
// 2. ICONIC LANDMARKS (08 图书馆, 01 北门, 11 主体育场)
// ----------------------------------------------------------------------------

// 08. 图书馆 (中央标志性穹顶 + 扇形翼楼 + 北侧展厅)
{
  const b = new MeshBuilder();
  // Central Rotunda Dome (中央圆拱大厅)
  b.addCylinder(0, 0, 0, 9, 20, 32);
  // South Crescent Fan Wings (南向大跨度扇形展厅)
  b.addCurvedArc(0, 0, 9, 18, -65, 65, 13, 20);
  // North Entrance Pavilions (北侧双子翼楼)
  b.addBuildingBlock(-12, -10, -4, -2, 13);
  b.addBuildingBlock(4, -10, 12, -2, 13);
  registerEntity(8, '08_图书馆', '中央标志性扇形/圆顶主图书馆', true, b, MAT_BUILT, [0, 20, 0]);
}

// 01. 北门 (礼仪牌坊与校前广场)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-10, -96, 10, -90, 6, 0.8);
  b.addBox(-12, 6, -97, 12, 7.5, -89); // Roof eaves
  registerEntity(1, '01_北门', '主校区北门礼仪入口牌坊', true, b, MAT_BUILT, [0, 7.5, -93]);
}

// 11. 主体育场 (田径场 + 看台 + 足球草坪)
{
  const bTrack = new MeshBuilder();
  // Running track slab
  bTrack.addBox(38, 0, 24, 68, 0.14, 66);
  registerEntity(11, '11_主体育场_田径跑道', '标准400米塑胶跑道', true, bTrack, MAT_TRACK, [53, 0, 45]);

  const bPitch = new MeshBuilder();
  // Inner pitch
  bPitch.addBox(43, 0.14, 30, 63, 0.22, 60);
  registerEntity(null, '11_主体育场_足球坪', '天然草坪标准足球场', true, bPitch, MAT_PITCH, [53, 0, 45]);

  const bStand = new MeshBuilder();
  // West & East Grandstands with canopy
  bStand.addBox(35, 0, 26, 38, 5, 64);
  bStand.addBox(34, 5, 25, 39, 6.2, 65); // West canopy
  bStand.addBox(68, 0, 26, 71, 5, 64);
  bStand.addBox(67, 5, 25, 72, 6.2, 65); // East canopy
  registerEntity(null, '11_主体育场_观礼看台', '主体育场东西双侧观礼看台', true, bStand, MAT_BUILT, [53, 6, 45]);
}

// ----------------------------------------------------------------------------
// 3. NORTHEAST ACADEMIC QUADRANGLE (04, 05, 03, 02 教学楼 A/B/C/D)
// ----------------------------------------------------------------------------

// 04. 教学楼 C 座 ("凹"字形朝东开口庭院)
{
  const b = new MeshBuilder();
  b.addUShapeBuilding(12, -70, 28, -52, 'E', 0.32, 15);
  registerEntity(4, '04_教学楼C座', '东北教学楼C座 (凹字形通透庭院)', true, b, MAT_BUILT, [20, 15, -61]);
}

// 05. 教学楼 D 座 ("凹"字形朝东开口庭院)
{
  const b = new MeshBuilder();
  b.addUShapeBuilding(12, -48, 28, -30, 'E', 0.32, 15);
  registerEntity(5, '05_教学楼D座', '东北教学楼D座 (凹字形通透庭院)', true, b, MAT_BUILT, [20, 15, -39]);
}

// 03. 教学楼 B 座 (折角现代教学楼)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(33, -68, 45, -60, 15);
  b.addBuildingBlock(39, -60, 45, -50, 15);
  registerEntity(3, '03_教学楼B座', '东北教学楼B座 (L形折角翼楼)', true, b, MAT_BUILT, [39, 15, -59]);
}

// 02. 教学楼 A 座 (大体量拐角综合教学楼)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(33, -46, 47, -38, 15);
  b.addBuildingBlock(39, -38, 47, -26, 15);
  registerEntity(2, '02_教学楼A座', '东北教学楼A座 (主教学楼大楼)', true, b, MAT_BUILT, [40, 15, -36]);
}

// ----------------------------------------------------------------------------
// 4. NORTHWEST SCIENCE & LABS (07, 06 教学实验楼 B、A)
// ----------------------------------------------------------------------------

// 07. 教学实验楼 B 座 ("回"字形四方中空内天井)
{
  const b = new MeshBuilder();
  b.addCourtyardBuilding(-28, -66, -10, -48, 8, 8, 15);
  registerEntity(7, '07_教学实验楼B座', '西北教学实验楼B座 (回字形内天井院落)', true, b, MAT_BUILT, [-19, 15, -57]);
}

// 06. 教学实验楼 A 座 (工字形/双翼综合实验大楼)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-30, -46, -12, -38, 15);
  b.addBuildingBlock(-24, -38, -18, -30, 15);
  b.addBuildingBlock(-30, -30, -12, -22, 15);
  registerEntity(6, '06_教学实验楼A座', '西北教学实验楼A座 (工字形现代实验大楼)', true, b, MAT_BUILT, [-21, 15, -34]);
}

// ----------------------------------------------------------------------------
// 5. SOUTHWEST STUDENT DORMITORIES & CANTEENS (12~19, 20, 22, 37, 38)
// ----------------------------------------------------------------------------

// 18. 1号学生公寓楼 ("凹"字形朝南)
{
  const b = new MeshBuilder();
  b.addUShapeBuilding(-46, 10, -28, 24, 'S', 0.35, 17);
  registerEntity(18, '18_1号学生公寓楼', '1号学生公寓楼 (凹字形朝南采光庭院)', true, b, MAT_BUILT, [-37, 17, 17]);
}

// 19. 2号学生公寓楼 (三翼梳状大型公寓楼)
{
  const b = new MeshBuilder();
  b.addEShapeBuilding(-46, 28, -26, 42, 17);
  registerEntity(19, '2号学生公寓楼', '2号学生公寓楼 (E字形多翼大体量公寓)', true, b, MAT_BUILT, [-36, 17, 35]);
}

// 15. 4号学生公寓楼 (折线阶梯形)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-46, 46, -30, 54, 17);
  b.addBuildingBlock(-40, 54, -26, 62, 17);
  registerEntity(15, '15_4号学生公寓楼', '4号学生公寓楼 (错层采光阶梯公寓)', true, b, MAT_BUILT, [-36, 17, 54]);
}

// 16. 5号学生公寓楼
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-24, 52, -10, 60, 17);
  registerEntity(16, '16_5号学生公寓楼', '5号学生公寓楼', true, b, MAT_BUILT, [-17, 17, 56]);
}

// 17. 3号学生公寓楼 ("工"字形)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-24, 26, -10, 32, 17);
  b.addBuildingBlock(-20, 32, -14, 40, 17);
  b.addBuildingBlock(-24, 40, -10, 46, 17);
  registerEntity(17, '17_3号学生公寓楼', '3号学生公寓楼 (工字形联排公寓)', true, b, MAT_BUILT, [-17, 17, 36]);
}

// 37. 综合服务楼及食堂 (中心生活综合体)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-4, 22, 10, 38, 13);
  b.addBuildingBlock(-1, 38, 7, 44, 10);
  registerEntity(37, '37_综合服务楼及食堂', '综合服务楼及一期食堂综合体', true, b, MAT_BUILT, [3, 13, 33]);
}

// 13. 6号学生公寓楼 ("凹"字形朝南)
{
  const b = new MeshBuilder();
  b.addUShapeBuilding(-4, 48, 12, 60, 'S', 0.35, 17);
  registerEntity(13, '13_6号学生公寓楼', '6号学生公寓楼 (凹字形通透院落)', true, b, MAT_BUILT, [4, 17, 54]);
}

// 14. 7号学生公寓楼 ("凹"字形朝南)
{
  const b = new MeshBuilder();
  b.addUShapeBuilding(-4, 64, 12, 76, 'S', 0.35, 17);
  registerEntity(14, '14_7号学生公寓楼', '7号学生公寓楼 (凹字形通透院落)', true, b, MAT_BUILT, [4, 17, 70]);
}

// 22. 学生浴室
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-24, 64, -12, 74, 8);
  registerEntity(22, '22_学生浴室', '学生公共浴室中心', true, b, MAT_BUILT, [-18, 8, 69]);
}

// 38. 8号学生公寓楼 (阶梯折角)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(16, 24, 30, 32, 17);
  b.addBuildingBlock(22, 32, 30, 40, 17);
  registerEntity(38, '38_8号学生公寓楼', '8号学生公寓楼', true, b, MAT_BUILT, [23, 17, 32]);
}

// 12. 学生公寓楼 (L形)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(16, 44, 24, 60, 17);
  b.addBuildingBlock(24, 52, 32, 60, 17);
  registerEntity(12, '12_学生公寓楼', '东区学生公寓楼', true, b, MAT_BUILT, [24, 17, 52]);
}

// 20. 学生食堂 (大型餐饮双层主楼)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(16, 64, 34, 76, 12, 0.6);
  registerEntity(20, '20_学生食堂', '园区主力学生大食堂', true, b, MAT_BUILT, [25, 12, 70]);
}

// 21. 开水房
{
  const b = new MeshBuilder();
  b.addBuildingBlock(12, 66, 15, 74, 5);
  registerEntity(21, '21_开水房', '便民开水供应房', true, b, MAT_BUILT, [13.5, 5, 70]);
}

// 09. 大学生活动中心 (湖畔曲水建筑)
{
  const b = new MeshBuilder();
  b.addCylinder(32, 0, 15, 7.5, 14, 24);
  b.addBuildingBlock(28, 8, 38, 16, 10);
  registerEntity(9, '09_大学生活动中心', '湖畔大学生活动与交流中心', true, b, MAT_BUILT, [33, 14, 14]);
}

// ----------------------------------------------------------------------------
// 6. SECONDARY STADIUM & OUTDOOR COURTS (23, 24, 27, 31, 36)
// ----------------------------------------------------------------------------

// 23. 副体育场
{
  const bTrack = new MeshBuilder();
  bTrack.addBox(-20, 0, 82, 0, 0.14, 114);
  registerEntity(23, '23_副体育场_跑道', '副运动场环形塑胶跑道', true, bTrack, MAT_TRACK, [-10, 0, 98]);

  const bPitch = new MeshBuilder();
  bPitch.addBox(-17, 0.14, 86, -3, 0.22, 110);
  registerEntity(null, '23_副体育场_足球场', '副场天然草坪', true, bPitch, MAT_PITCH, [-10, 0, 98]);
}

// 24. 篮球场群
{
  const b = new MeshBuilder();
  b.addBox(-46, 0, 70, -24, 0.12, 108);
  registerEntity(24, '24_室外篮球排球场群', '室外多片标准塑胶篮球场、排球场、乒乓球场', true, b, MAT_COURT, [-35, 0, 89]);
}

// 36. 体育器材仓库
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-24, 88, -21, 104, 4);
  registerEntity(36, '36_体育器材仓库', '体育器材与保障中心', true, b, MAT_BUILT, [-22.5, 4, 96]);
}

// 31. 南锅炉房, 27. 游泳池
{
  const b = new MeshBuilder();
  b.addBuildingBlock(6, 84, 12, 92, 6);
  registerEntity(31, '31_南锅炉房', '南区供暖锅炉房', true, b, MAT_BUILT, [9, 6, 88]);

  const bPool = new MeshBuilder();
  bPool.addBox(5, 0, 96, 13, 0.15, 112);
  registerEntity(27, '27_游泳池', '露天/室内综合游泳场馆', true, bPool, MAT_WATER, [9, 0, 104]);
}

// ----------------------------------------------------------------------------
// 7. SOUTHEAST FACULTY HOUSING ROWS (34 教师公寓群 8栋向阳排楼)
// ----------------------------------------------------------------------------
{
  const b = new MeshBuilder();
  const zStarts = [88, 96, 104, 112];
  // West cluster (4 rows)
  for (let r = 0; r < 4; r++) {
    const z = zStarts[r];
    b.addBuildingBlock(18, z, 42, z + 5, 15, 0.4);
  }
  // East cluster (4 rows)
  for (let r = 0; r < 4; r++) {
    const z = zStarts[r];
    b.addBuildingBlock(46, z, 70, z + 5, 15, 0.4);
  }
  registerEntity(34, '34_教师公寓楼群', '东南生活区8栋并联向阳多层住宅楼群', true, b, MAT_BUILT, [44, 15, 100]);
}

// 35. 勤工助学基地, 33. 校医院
{
  const b = new MeshBuilder();
  b.addBuildingBlock(18, 80, 28, 86, 9);
  registerEntity(35, '35_勤工助学基地', '勤工助学基地综合楼', true, b, MAT_BUILT, [23, 9, 83]);

  const bHosp = new MeshBuilder();
  bHosp.addBuildingBlock(64, 68, 71, 76, 10);
  registerEntity(33, '33_校医院', '校园医疗保障中心与校医院', true, bHosp, MAT_BUILT, [67.5, 10, 72]);
}

// 32. 北锅炉房, 40. 工程训练中心, 39. 中心配电室
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-48, -24, -43, -16, 6);
  registerEntity(32, '32_北锅炉房', '北区供暖与保障锅炉房', true, b, MAT_BUILT, [-45.5, 6, -20]);

  const b40 = new MeshBuilder();
  b40.addBuildingBlock(-64, -20, -50, -8, 10);
  registerEntity(40, '40_工程训练中心', '实践与工程训练中心大楼', true, b40, MAT_BUILT, [-57, 10, -14]);

  const b39 = new MeshBuilder();
  b39.addBuildingBlock(-62, 0, -57, 8, 5);
  registerEntity(39, '39_中心配电室', '全校中心配电与电力枢纽', true, b39, MAT_BUILT, [-59.5, 5, 4]);
}

// ----------------------------------------------------------------------------
// 8. PLANNED BUILDINGS (待建建筑物群 🟦 41~51)
// ----------------------------------------------------------------------------

// 45. 会展接待中心 (大跨度弧形现代曲面建筑)
{
  const b = new MeshBuilder();
  b.addCurvedArc(-30, -60, 20, 28, 135, 205, 15, 20);
  registerEntity(45, '45_会展接待中心', '西北大型弧形曲面会展与国际交流中心', false, b, MAT_PLAN, [-44, 15, -76]);
}

// 44. 预留学院楼 F (阶梯弧形)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-32, -74, -12, -66, 15);
  b.addBuildingBlock(-20, -66, -12, -60, 15);
  registerEntity(44, '44_预留学院楼F', '规划学院教学实验综合楼F', false, b, MAT_PLAN, [-22, 15, -67]);
}

// 43. 预留学院楼 A ("回"字形中空庭院)
{
  const b = new MeshBuilder();
  b.addCourtyardBuilding(-46, -66, -32, -50, 6, 6, 15);
  registerEntity(43, '43_预留学院楼A', '规划学院教学楼A (回字形院落)', false, b, MAT_PLAN, [-39, 15, -58]);
}

// 42. 预留学院楼 B ("回"字形中空庭院)
{
  const b = new MeshBuilder();
  b.addCourtyardBuilding(-46, -46, -32, -30, 6, 6, 15);
  registerEntity(42, '42_预留学院楼B', '规划学院教学楼B (回字形院落)', false, b, MAT_PLAN, [-39, 15, -38]);
}

// 41. 预留学院楼 G (L形)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(-44, -26, -30, -18, 15);
  b.addBuildingBlock(-38, -18, -30, -10, 15);
  registerEntity(41, '41_预留学院楼G', '规划学院教学楼G', false, b, MAT_PLAN, [-37, 15, -18]);
}

// 46. 预留校前行政楼 (主立面标志性高层)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(15, -92, 27, -80, 24, 0.8);
  b.addBuildingBlock(27, -88, 33, -80, 14); // East podium wing
  registerEntity(46, '46_预留校前行政楼', '校区主入口标志性行政管理主楼 (高24米)', false, b, MAT_PLAN, [21, 24, -86]);
}

// 47. 博物馆 (现代大跨度文化场馆)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(40, -94, 68, -80, 16, 0.8);
  b.addBuildingBlock(52, -80, 68, -72, 12);
  registerEntity(47, '47_博物馆', '东北角大型现代综合博物馆与文化展馆', false, b, MAT_PLAN, [54, 16, -83]);
}

// 48. 预留学院楼 C (双连廊庭院综合楼)
{
  const b = new MeshBuilder();
  b.addCourtyardBuilding(48, -68, 66, -50, 8, 8, 15);
  registerEntity(48, '48_预留学院楼C', '东部规划学院综合大楼C (回字形)', false, b, MAT_PLAN, [57, 15, -59]);
}

// 49. 预留学院楼 D (双连廊庭院综合楼)
{
  const b = new MeshBuilder();
  b.addCourtyardBuilding(48, -48, 66, -30, 8, 8, 15);
  registerEntity(49, '49_预留学院楼D', '东部规划学院综合大楼D (回字形)', false, b, MAT_PLAN, [57, 15, -39]);
}

// 50. 预留学院楼 E (L形折角)
{
  const b = new MeshBuilder();
  b.addBuildingBlock(48, -26, 66, -18, 15);
  b.addBuildingBlock(56, -18, 66, -10, 15);
  registerEntity(50, '50_预留学院楼E', '东部规划学院教学实验楼E', false, b, MAT_PLAN, [57, 15, -18]);
}

// 51. 预留文体楼 (大剧院 / 球形多功能文体中心)
{
  const b = new MeshBuilder();
  // Central Great Arena Dome
  b.addCylinder(54, 0, 4, 11, 20, 32);
  // North & South Entrance Podiums
  b.addBuildingBlock(44, -6, 64, 0, 8);
  b.addBuildingBlock(44, 8, 64, 14, 8);
  registerEntity(51, '51_预留文体楼', '东区多功能综合文体中心与演艺剧场大巨蛋', false, b, MAT_PLAN, [54, 20, 4]);
}

console.log('Total 3D entities generated:', nodesList.length);

// ============================================================================
// 9. ASSEMBLE BINARY GLB 2.0 WITH doubleSided: true
// ============================================================================

let binBuffers = [];
let byteOffset = 0;
let bufferViews = [];
let accessors = [];
let materials = [];
let meshes = [];
let nodes = [];
let sceneNodes = [];

// Cache materials to avoid redundant definitions
const matMap = new Map();

nodesList.forEach((item, i) => {
  const meshData = item.mesh;

  const posArr = new Float32Array(meshData.positions);
  const posBuf = Buffer.from(posArr.buffer);

  const normArr = new Float32Array(meshData.normals);
  const normBuf = Buffer.from(normArr.buffer);

  const indArr = new Uint16Array(meshData.indices);
  const indBuf = Buffer.from(indArr.buffer);

  // Position
  const posBv = bufferViews.length;
  bufferViews.push({ buffer: 0, byteOffset, byteLength: posBuf.length, target: 34962 });
  binBuffers.push(posBuf);
  byteOffset += posBuf.length;

  let minX = Infinity, minY = Infinity, minZ = Infinity;
  let maxX = -Infinity, maxY = -Infinity, maxZ = -Infinity;
  for (let p = 0; p < meshData.positions.length; p += 3) {
    minX = Math.min(minX, meshData.positions[p]);
    minY = Math.min(minY, meshData.positions[p + 1]);
    minZ = Math.min(minZ, meshData.positions[p + 2]);
    maxX = Math.max(maxX, meshData.positions[p]);
    maxY = Math.max(maxY, meshData.positions[p + 1]);
    maxZ = Math.max(maxZ, meshData.positions[p + 2]);
  }

  const posAcc = accessors.length;
  accessors.push({
    bufferView: posBv,
    byteOffset: 0,
    componentType: 5126,
    count: meshData.positions.length / 3,
    type: 'VEC3',
    min: [minX, minY, minZ],
    max: [maxX, maxY, maxZ]
  });

  // Normal
  const normBv = bufferViews.length;
  bufferViews.push({ buffer: 0, byteOffset, byteLength: normBuf.length, target: 34962 });
  binBuffers.push(normBuf);
  byteOffset += normBuf.length;

  const normAcc = accessors.length;
  accessors.push({
    bufferView: normBv,
    byteOffset: 0,
    componentType: 5126,
    count: meshData.normals.length / 3,
    type: 'VEC3'
  });

  // Indices with 4-byte padding
  const pad = (4 - (byteOffset % 4)) % 4;
  if (pad > 0) {
    binBuffers.push(Buffer.alloc(pad));
    byteOffset += pad;
  }

  const indBv = bufferViews.length;
  bufferViews.push({ buffer: 0, byteOffset, byteLength: indBuf.length, target: 34963 });
  binBuffers.push(indBuf);
  byteOffset += indBuf.length;

  const pad2 = (4 - (byteOffset % 4)) % 4;
  if (pad2 > 0) {
    binBuffers.push(Buffer.alloc(pad2));
    byteOffset += pad2;
  }

  const indAcc = accessors.length;
  accessors.push({
    bufferView: indBv,
    byteOffset: 0,
    componentType: 5123,
    count: meshData.indices.length,
    type: 'SCALAR'
  });

  // Material with doubleSided: true!
  const matName = item.material.name;
  let matIndex = matMap.get(matName);
  if (matIndex === undefined) {
    matIndex = materials.length;
    materials.push({
      name: matName,
      doubleSided: true, // Prevent any culling!
      pbrMetallicRoughness: {
        baseColorFactor: item.material.baseColor,
        metallicFactor: item.material.metallic,
        roughnessFactor: item.material.roughness
      }
    });
    matMap.set(matName, matIndex);
  }

  // Mesh
  const meshIndex = meshes.length;
  meshes.push({
    name: item.name + '_Mesh',
    primitives: [{
      attributes: { POSITION: posAcc, NORMAL: normAcc },
      indices: indAcc,
      material: matIndex
    }]
  });

  // Node
  const nodeIndex = nodes.length;
  nodes.push({
    name: item.name,
    mesh: meshIndex
  });
  sceneNodes.push(nodeIndex);
});

const totalBinBuffer = Buffer.concat(binBuffers);
const gltfJson = {
  asset: { version: '2.0', generator: 'Architectural Campus 3D Model Generator' },
  scenes: [{ name: 'UniversityCampusScene', nodes: sceneNodes }],
  scene: 0,
  nodes,
  meshes,
  materials,
  accessors,
  bufferViews,
  buffers: [{ byteLength: totalBinBuffer.length }]
};

const jsonStr = JSON.stringify(gltfJson);
let jsonBuf = Buffer.from(jsonStr, 'utf8');
const jsonPad = (4 - (jsonBuf.length % 4)) % 4;
if (jsonPad > 0) {
  jsonBuf = Buffer.concat([jsonBuf, Buffer.alloc(jsonPad, 0x20)]);
}

const totalLength = 12 + 8 + jsonBuf.length + 8 + totalBinBuffer.length;
const header = Buffer.alloc(12);
header.writeUInt32LE(0x46546C67, 0); // 'glTF'
header.writeUInt32LE(2, 4);          // version 2
header.writeUInt32LE(totalLength, 8); // total length

const chunk0Header = Buffer.alloc(8);
chunk0Header.writeUInt32LE(jsonBuf.length, 0);
chunk0Header.writeUInt32LE(0x4E4F534A, 4); // 'JSON'

const chunk1Header = Buffer.alloc(8);
chunk1Header.writeUInt32LE(totalBinBuffer.length, 0);
chunk1Header.writeUInt32LE(0x004E4942, 4); // 'BIN\0'

const glbBuffer = Buffer.concat([header, chunk0Header, jsonBuf, chunk1Header, totalBinBuffer]);

// Save to rawfile/3d/campus.glb
const targetGlb = path.join(__dirname, '..', 'entry', 'src', 'main', 'resources', 'rawfile', '3d', 'campus.glb');
fs.writeFileSync(targetGlb, glbBuffer);
console.log('Saved solid architectural campus.glb to:', targetGlb, 'Size:', glbBuffer.length, 'bytes');

// Update preview_3d_campus.html
const b64 = glbBuffer.toString('base64');
const hudItems = nodesList.filter(n => n.id !== null).map(n => ({
  id: n.id,
  name: n.name,
  desc: n.desc,
  isBuilt: n.isBuilt,
  center: n.center
}));

const htmlContent = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>大学数字校园 3D 建筑沙盘 (高精格式还原版)</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      overflow: hidden;
      background: #111827;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif;
      user-select: none;
    }
    #header {
      position: absolute;
      top: 16px;
      left: 16px;
      color: #fff;
      background: rgba(17, 24, 39, 0.92);
      backdrop-filter: blur(12px);
      padding: 16px 24px;
      border-radius: 12px;
      border: 1px solid rgba(255,255,255,0.15);
      box-shadow: 0 12px 36px rgba(0,0,0,0.5);
      z-index: 10;
    }
    #header h3 { margin: 0 0 6px 0; font-size: 18px; color: #38bdf8; display: flex; align-items: center; gap: 8px; }
    #header p { margin: 0; font-size: 12px; color: #94a3b8; }
    #header .legend {
      display: flex;
      gap: 16px;
      margin-top: 12px;
      font-size: 12px;
    }
    .legend-item { display: flex; align-items: center; gap: 6px; }
    .dot-built { width: 12px; height: 12px; background: #f59e0b; border-radius: 3px; }
    .dot-planned { width: 12px; height: 12px; background: #38bdf8; border-radius: 3px; }
    .dot-track { width: 12px; height: 12px; background: #ef4444; border-radius: 3px; }

    #sidebar {
      position: absolute;
      top: 16px;
      right: 16px;
      bottom: 20px;
      width: 300px;
      background: rgba(17, 24, 39, 0.92);
      backdrop-filter: blur(12px);
      border-radius: 12px;
      border: 1px solid rgba(255,255,255,0.15);
      box-shadow: 0 12px 36px rgba(0,0,0,0.5);
      display: flex;
      flex-direction: column;
      z-index: 10;
      color: #fff;
    }
    #sidebar-header {
      padding: 14px 16px;
      border-bottom: 1px solid rgba(255,255,255,0.1);
      font-size: 14px;
      font-weight: 600;
      color: #38bdf8;
      display: flex;
      justify-content: space-between;
    }
    #search-box {
      margin: 10px 14px 4px 14px;
      padding: 8px 12px;
      border-radius: 6px;
      border: 1px solid rgba(255,255,255,0.15);
      background: rgba(255,255,255,0.06);
      color: #fff;
      font-size: 12px;
      outline: none;
    }
    #search-box:focus { border-color: #38bdf8; }
    #building-list {
      flex: 1;
      overflow-y: auto;
      padding: 10px 14px;
      display: flex;
      flex-direction: column;
      gap: 6px;
    }
    .b-item {
      padding: 8px 10px;
      border-radius: 6px;
      font-size: 12px;
      color: #cbd5e1;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: space-between;
      transition: all 0.2s;
    }
    .b-item:hover {
      background: rgba(56, 189, 248, 0.2);
      transform: translateX(-2px);
      color: #fff;
    }
    .tag {
      font-size: 10px;
      padding: 2px 6px;
      border-radius: 4px;
      font-weight: 500;
    }
    .tag-built { background: rgba(245, 158, 11, 0.2); color: #fbbf24; }
    .tag-plan { background: rgba(56, 189, 248, 0.2); color: #38bdf8; }

    #footer-tip {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      color: #cbd5e1;
      background: rgba(17, 24, 39, 0.88);
      backdrop-filter: blur(8px);
      padding: 8px 24px;
      border-radius: 20px;
      border: 1px solid rgba(255,255,255,0.15);
      font-size: 12px;
      pointer-events: none;
    }

    #info-modal {
      position: absolute;
      bottom: 75px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(17, 24, 39, 0.95);
      border: 1px solid #38bdf8;
      border-radius: 12px;
      padding: 16px 26px;
      color: #fff;
      display: none;
      box-shadow: 0 12px 36px rgba(0,0,0,0.6);
      z-index: 20;
      text-align: center;
      min-width: 260px;
    }
  </style>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
</head>
<body>
  <div id="header">
    <h3>🏛️ 大学数字校园 3D 沙盘 (高精模型)</h3>
    <p>实体建筑多面闭合 | 格式: <code>campus.glb</code></p>
    <div class="legend">
      <div class="legend-item"><span class="dot-built"></span>已建建筑物 (实体黄)</div>
      <div class="legend-item"><span class="dot-planned"></span>待建建筑物 (科技蓝)</div>
      <div class="legend-item"><span class="dot-track"></span>标准田径场/球场</div>
    </div>
  </div>

  <div id="sidebar">
    <div id="sidebar-header">
      <span>📍 校园建筑导览</span>
      <span style="font-size:11px;color:#94a3b8">${hudItems.length} 座单体</span>
    </div>
    <input type="text" id="search-box" placeholder="搜索建筑名称..." />
    <div id="building-list"></div>
  </div>

  <div id="info-modal">
    <div id="modal-title" style="font-size:16px;font-weight:bold;color:#38bdf8;margin-bottom:6px;"></div>
    <div id="modal-desc" style="font-size:12px;color:#94a3b8;line-height:1.4;"></div>
  </div>

  <div id="footer-tip">
    🖱️ 鼠标左键：360°旋转 | 滚轮：拉近缩放 | 鼠标右键：平移 | 点击任意建筑：运镜特写
  </div>

  <script>
    const buildingsData = ${JSON.stringify(hudItems)};

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xdce7f3);
    scene.fog = new THREE.FogExp2(0xdce7f3, 0.003);

    const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 1500);
    camera.position.set(0, 150, 180);

    const renderer = new THREE.WebGLRenderer({ antialias: true, powerPreference: "high-performance" });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    document.body.appendChild(renderer.domElement);

    const controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.maxPolarAngle = Math.PI / 2.15;
    controls.target.set(0, 0, 0);

    // 光照
    const hemiLight = new THREE.HemisphereLight(0xffffff, 0x8fa4b8, 1.0);
    scene.add(hemiLight);

    const sunLight = new THREE.DirectionalLight(0xfffaec, 1.1);
    sunLight.position.set(90, 180, 70);
    sunLight.castShadow = true;
    sunLight.shadow.mapSize.width = 2048;
    sunLight.shadow.mapSize.height = 2048;
    sunLight.shadow.camera.near = 10;
    sunLight.shadow.camera.far = 450;
    sunLight.shadow.camera.left = -120;
    sunLight.shadow.camera.right = 120;
    sunLight.shadow.camera.top = 150;
    sunLight.shadow.camera.bottom = -150;
    scene.add(sunLight);

    // 载入生成的 solid campus.glb
    const b64Data = "data:model/gltf-binary;base64,${b64}";
    const loader = new THREE.GLTFLoader();
    let campusGroup = null;
    const meshMap = new Map();

    loader.load(b64Data, function(gltf) {
      campusGroup = gltf.scene;
      campusGroup.traverse(function(child) {
        if (child.isMesh) {
          child.castShadow = true;
          child.receiveShadow = true;
          // Ensure doubleSided in Three.js renderer as well
          child.material.side = THREE.DoubleSide;
          meshMap.set(child.name.replace('_Mesh', ''), child);
        }
      });
      scene.add(campusGroup);
      renderSidebar(buildingsData);
    });

    function renderSidebar(items) {
      const container = document.getElementById('building-list');
      container.innerHTML = '';
      items.forEach(item => {
        const div = document.createElement('div');
        div.className = 'b-item';
        div.innerHTML = \`
          <span>\${item.name}</span>
          <span class="tag \${item.isBuilt ? 'tag-built' : 'tag-plan'}">\${item.isBuilt ? '已建' : '待建'}</span>
        \`;
        div.onclick = () => focusBuilding(item);
        container.appendChild(div);
      });
    }

    document.getElementById('search-box').addEventListener('input', function(e) {
      const q = e.target.value.trim().toLowerCase();
      const filtered = buildingsData.filter(b => b.name.toLowerCase().includes(q) || b.desc.toLowerCase().includes(q));
      renderSidebar(filtered);
    });

    function focusBuilding(item) {
      const [cx, cy, cz] = item.center;
      const modal = document.getElementById('info-modal');
      document.getElementById('modal-title').innerText = item.name;
      document.getElementById('modal-desc').innerText = item.desc ? item.desc + '<br>坐标: X: ' + cx.toFixed(1) + ', Z: ' + cz.toFixed(1) : '三维位置: X: ' + cx.toFixed(1) + ', Z: ' + cz.toFixed(1);
      modal.style.display = 'block';

      controls.target.set(cx, 0, cz);
      camera.position.set(cx, cy + 30, cz + 45);
      controls.update();
    }

    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();

    window.addEventListener('click', function(e) {
      if (e.clientX > window.innerWidth - 320) return;
      mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
      mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
      raycaster.setFromCamera(mouse, camera);

      if (campusGroup) {
        const intersects = raycaster.intersectObjects(campusGroup.children, true);
        if (intersects.length > 0) {
          const hit = intersects[0].object;
          const cleanName = hit.name.replace('_Mesh', '');
          const item = buildingsData.find(b => b.name === cleanName);
          if (item) {
            focusBuilding(item);
          }
        }
      }
    });

    window.addEventListener('resize', function() {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    });

    function animate() {
      requestAnimationFrame(animate);
      controls.update();
      renderer.render(scene, camera);
    }
    animate();
  </script>
</body>
</html>`;

const targetHtml = path.join(__dirname, '..', 'preview_3d_campus.html');
fs.writeFileSync(targetHtml, htmlContent, 'utf8');
console.log('Successfully written architectural campus files!');
