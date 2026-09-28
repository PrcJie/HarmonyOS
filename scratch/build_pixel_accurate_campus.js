const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

// 1. Decode PNG to raw RGBA buffer
function decodePng(filePath) {
  const buf = fs.readFileSync(filePath);
  let pos = 8;
  const idatChunks = [];
  let width = 0, height = 0;
  while (pos < buf.length) {
    const len = buf.readUInt32BE(pos);
    const type = buf.toString('ascii', pos + 4, pos + 8);
    const data = buf.subarray(pos + 8, pos + 8 + len);
    if (type === 'IHDR') {
      width = data.readUInt32BE(0);
      height = data.readUInt32BE(4);
    } else if (type === 'IDAT') {
      idatChunks.push(data);
    }
    pos += 12 + len;
  }
  const decompressed = zlib.inflateSync(Buffer.concat(idatChunks));
  const bpp = 4;
  const stride = 1 + width * bpp;
  const rgba = Buffer.alloc(width * height * 4);

  function paeth(a, b, c) {
    const p = a + b - c;
    const pa = Math.abs(p - a);
    const pb = Math.abs(p - b);
    const pc = Math.abs(p - c);
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  }

  for (let y = 0; y < height; y++) {
    const filter = decompressed[y * stride];
    const rowOffset = y * stride + 1;
    for (let x = 0; x < width * bpp; x++) {
      const raw = decompressed[rowOffset + x];
      const a = x >= bpp ? rgba[(y * width * bpp) + x - bpp] : 0;
      const b = y > 0 ? rgba[((y - 1) * width * bpp) + x] : 0;
      const c = (y > 0 && x >= bpp) ? rgba[((y - 1) * width * bpp) + x - bpp] : 0;
      let val = 0;
      if (filter === 0) val = raw;
      else if (filter === 1) val = (raw + a) & 0xff;
      else if (filter === 2) val = (raw + b) & 0xff;
      else if (filter === 3) val = (raw + Math.floor((a + b) / 2)) & 0xff;
      else if (filter === 4) val = (raw + paeth(a, b, c)) & 0xff;
      rgba[(y * width * bpp) + x] = val;
    }
  }
  return { width, height, rgba };
}

const imgPath = 'C:/Users/HUAWEI/.gemini/antigravity/brain/ac3b6f54-45b7-4b49-b78b-e00a6b03f64b/.user_uploaded/media_1790576336724.png';
const { width, height, rgba } = decodePng(imgPath);
console.log('Decoded PNG image:', width, 'x', height);

// 2. Classify pixels
// 0: default/road, 1: Built (yellow), 2: Planned (blue), 3: Green (grass), 4: Water, 5: Stadium track, 6: Pitch
const classGrid = new Uint8Array(width * height);

for (let y = 65; y < 780; y++) {
  for (let x = 100; x < width - 15; x++) {
    const idx = (y * width + x) * 4;
    const r = rgba[idx], g = rgba[idx + 1], b = rgba[idx + 2];

    // Built building (Yellow / Amber)
    if (r > 200 && g > 150 && b < 80) {
      classGrid[y * width + x] = 1;
    }
    // Planned building (Sky Blue)
    else if (r < 170 && g > 150 && b > 200) {
      classGrid[y * width + x] = 2;
    }
    // Water stream / lake (between x: 340-440, y: 310-440)
    else if (x >= 320 && x <= 450 && y >= 310 && y <= 440 && r > 190 && g > 215 && b > 230) {
      classGrid[y * width + x] = 4;
    }
    // Main stadium track (Red/Orange around x: 450-550, y: 470-600)
    else if (x >= 450 && x <= 550 && y >= 470 && y <= 600 && (r > 190 && g > 100 && g < 170 && b < 100)) {
      classGrid[y * width + x] = 5;
    }
    // Stadium football pitch (Bright green inside stadium)
    else if (((x >= 460 && x <= 530 && y >= 480 && y <= 580) || (x >= 250 && x <= 320 && y >= 660 && y <= 750)) && (r < 110 && g > 140 && b < 90)) {
      classGrid[y * width + x] = 6;
    }
    // Green spaces / Lawn
    else if (r < 140 && g > 145 && b < 110) {
      classGrid[y * width + x] = 3;
    }
  }
}

// 3. Extract connected components for buildings (classes 1 and 2)
const visited = new Uint8Array(width * height);
const buildingComponents = [];

for (let y = 65; y < 770; y++) {
  for (let x = 100; x < width - 15; x++) {
    const idx = y * width + x;
    const type = classGrid[idx];
    if ((type === 1 || type === 2) && !visited[idx]) {
      const q = [idx];
      visited[idx] = 1;
      let minX = x, maxX = x, minY = y, maxY = y;
      let sumX = 0, sumY = 0;
      const pixels = [];

      let head = 0;
      while (head < q.length) {
        const curr = q[head++];
        pixels.push(curr);
        const cx = curr % width;
        const cy = Math.floor(curr / width);
        sumX += cx;
        sumY += cy;
        if (cx < minX) minX = cx;
        if (cx > maxX) maxX = cx;
        if (cy < minY) minY = cy;
        if (cy > maxY) maxY = cy;

        const neighbors = [curr - 1, curr + 1, curr - width, curr + width];
        for (const n of neighbors) {
          if (n >= 0 && n < classGrid.length && !visited[n] && classGrid[n] === type) {
            visited[n] = 1;
            q.push(n);
          }
        }
      }

      // Filter noise (smaller than 15 pixels)
      if (pixels.length >= 15) {
        const compW = maxX - minX + 1;
        const compH = maxY - minY + 1;
        const mask = new Uint8Array(compW * compH);
        for (const p of pixels) {
          const px = p % width - minX;
          const py = Math.floor(p / width) - minY;
          mask[py * compW + px] = 1;
        }

        buildingComponents.push({
          type: type === 1 ? 'built' : 'planned',
          area: pixels.length,
          centroid: [Math.round(sumX / pixels.length), Math.round(sumY / pixels.length)],
          minX, maxX, minY, maxY,
          compW, compH,
          mask
        });
      }
    }
  }
}

console.log('Total building footprints extracted:', buildingComponents.length);

// 4. Generate 3D Extrusion Mesh from binary mask
const originX = 350;
const originZ = 420;
const scale = 0.35; // meters per pixel

function extrudeMaskToMesh(comp, heightVal, baseY = 0) {
  const { minX, minY, compW, compH, mask } = comp;
  const positions = [];
  const normals = [];
  const indices = [];

  function addQuad(p0, p1, p2, p3, norm) {
    const base = positions.length / 3;
    positions.push(...p0, ...p1, ...p2, ...p3);
    normals.push(...norm, ...norm, ...norm, ...norm);
    indices.push(base, base + 1, base + 2, base, base + 2, base + 3);
  }

  // Top roof (horizontal quads, merged along X)
  for (let y = 0; y < compH; y++) {
    let runStart = -1;
    for (let x = 0; x <= compW; x++) {
      const inMask = x < compW && mask[y * compW + x] === 1;
      if (inMask && runStart === -1) {
        runStart = x;
      } else if (!inMask && runStart !== -1) {
        const x0 = (minX + runStart - originX) * scale;
        const x1 = (minX + x - originX) * scale;
        const z0 = (minY + y - originZ) * scale;
        const z1 = (minY + y + 1 - originZ) * scale;
        addQuad([x0, heightVal, z0], [x1, heightVal, z0], [x1, heightVal, z1], [x0, heightVal, z1], [0, 1, 0]);
        runStart = -1;
      }
    }
  }

  // North walls (merged along X)
  for (let y = 0; y < compH; y++) {
    let runStart = -1;
    for (let x = 0; x <= compW; x++) {
      const isWall = x < compW && mask[y * compW + x] === 1 && (y === 0 || mask[(y - 1) * compW + x] === 0);
      if (isWall && runStart === -1) runStart = x;
      else if (!isWall && runStart !== -1) {
        const x0 = (minX + runStart - originX) * scale;
        const x1 = (minX + x - originX) * scale;
        const z = (minY + y - originZ) * scale;
        addQuad([x1, baseY, z], [x0, baseY, z], [x0, heightVal, z], [x1, heightVal, z], [0, 0, -1]);
        runStart = -1;
      }
    }
  }

  // South walls (merged along X)
  for (let y = 0; y < compH; y++) {
    let runStart = -1;
    for (let x = 0; x <= compW; x++) {
      const isWall = x < compW && mask[y * compW + x] === 1 && (y === compH - 1 || mask[(y + 1) * compW + x] === 0);
      if (isWall && runStart === -1) runStart = x;
      else if (!isWall && runStart !== -1) {
        const x0 = (minX + runStart - originX) * scale;
        const x1 = (minX + x - originX) * scale;
        const z = (minY + y + 1 - originZ) * scale;
        addQuad([x0, baseY, z], [x1, baseY, z], [x1, heightVal, z], [x0, heightVal, z], [0, 0, 1]);
        runStart = -1;
      }
    }
  }

  // West walls (merged along Y)
  for (let x = 0; x < compW; x++) {
    let runStart = -1;
    for (let y = 0; y <= compH; y++) {
      const isWall = y < compH && mask[y * compW + x] === 1 && (x === 0 || mask[y * compW + x - 1] === 0);
      if (isWall && runStart === -1) runStart = y;
      else if (!isWall && runStart !== -1) {
        const z0 = (minY + runStart - originZ) * scale;
        const z1 = (minY + y - originZ) * scale;
        const x0 = (minX + x - originX) * scale;
        addQuad([x0, baseY, z0], [x0, baseY, z1], [x0, heightVal, z1], [x0, heightVal, z0], [-1, 0, 0]);
        runStart = -1;
      }
    }
  }

  // East walls (merged along Y)
  for (let x = 0; x < compW; x++) {
    let runStart = -1;
    for (let y = 0; y <= compH; y++) {
      const isWall = y < compH && mask[y * compW + x] === 1 && (x === compW - 1 || mask[y * compW + x + 1] === 0);
      if (isWall && runStart === -1) runStart = y;
      else if (!isWall && runStart !== -1) {
        const z0 = (minY + runStart - originZ) * scale;
        const z1 = (minY + y - originZ) * scale;
        const x1 = (minX + x + 1 - originX) * scale;
        addQuad([x1, baseY, z1], [x1, baseY, z0], [x1, heightVal, z0], [x1, heightVal, z1], [1, 0, 0]);
        runStart = -1;
      }
    }
  }

  return { positions, normals, indices };
}

// 5. Match building component to known campus buildings based on (centroidX, centroidY)
// Known landmark coordinates mapping from the legend
const landmarkDefs = [
  { id: 8, name: '08_图书馆', cx: 359, cy: 349, height: 18, desc: '中央标志性扇形/穹顶主图书馆' },
  { id: 4, name: '04_教学楼C座', cx: 405, cy: 196, height: 14, desc: '东北教学楼C座 (凹字形庭院)' },
  { id: 5, name: '05_教学楼D座', cx: 404, cy: 250, height: 14, desc: '东北教学楼D座 (凹字形庭院)' },
  { id: 3, name: '03_教学楼B座', cx: 462, cy: 228, height: 14, desc: '东北教学楼B座' },
  { id: 2, name: '02_教学楼A座', cx: 454, cy: 285, height: 14, desc: '东北教学楼A座' },
  { id: 7, name: '07_教学实验楼B座', cx: 305, cy: 233, height: 14, desc: '西北教学实验楼B座 (回字形庭院)' },
  { id: 6, name: '06_教学实验楼A座', cx: 258, cy: 295, height: 14, desc: '西北教学实验楼A座' },
  { id: 9, name: '09_大学生活动中心', cx: 450, cy: 435, height: 12, desc: '湖畔大学生活动中心' },
  { id: 18, name: '18_1号学生公寓楼', cx: 216, cy: 465, height: 16, desc: '1号学生公寓楼 (凹字形)' },
  { id: 19, name: '19_2号学生公寓楼', cx: 212, cy: 512, height: 16, desc: '2号学生公寓楼 (E字形)' },
  { id: 15, name: '15_4号学生公寓楼', cx: 210, cy: 558, height: 16, desc: '4号学生公寓楼' },
  { id: 16, name: '16_5号学生公寓楼', cx: 254, cy: 578, height: 16, desc: '5号学生公寓楼' },
  { id: 17, name: '17_3号学生公寓楼', cx: 272, cy: 504, height: 16, desc: '3号学生公寓楼 (工字形)' },
  { id: 37, name: '37_综合服务楼及食堂', cx: 326, cy: 497, height: 12, desc: '综合服务楼及食堂' },
  { id: 13, name: '13_6号学生公寓楼', cx: 318, cy: 562, height: 16, desc: '6号学生公寓楼 (凹字形)' },
  { id: 14, name: '14_7号学生公寓楼', cx: 316, cy: 624, height: 16, desc: '7号学生公寓楼 (凹字形)' },
  { id: 22, name: '22_学生浴室', cx: 257, cy: 622, height: 7, desc: '学生浴室' },
  { id: 38, name: '38_8号学生公寓楼', cx: 403, cy: 497, height: 16, desc: '8号学生公寓楼' },
  { id: 12, name: '12_学生公寓楼', cx: 403, cy: 575, height: 16, desc: '学生公寓楼' },
  { id: 20, name: '20_学生食堂', cx: 406, cy: 631, height: 10, desc: '大型学生主食堂' },
  { id: 21, name: '21_开水房', cx: 372, cy: 633, height: 5, desc: '开水房' },
  { id: 31, name: '31_南锅炉房', cx: 345, cy: 692, height: 6, desc: '南锅炉房' },
  { id: 27, name: '27_游泳池', cx: 342, cy: 736, height: 4, desc: '游泳池场馆' },
  { id: 35, name: '35_勤工助学基地', cx: 403, cy: 673, height: 8, desc: '勤工助学基地' },
  { id: 33, name: '33_校医院', cx: 539, cy: 625, height: 8, desc: '校医院' },
  { id: 32, name: '32_北锅炉房', cx: 202, cy: 395, height: 6, desc: '北锅炉房' },
  { id: 40, name: '40_工程训练中心', cx: 165, cy: 408, height: 9, desc: '工程训练中心' },
  { id: 39, name: '39_中心配电室', cx: 163, cy: 446, height: 5, desc: '中心配电室' },
  // Planned (Blue)
  { id: 45, name: '45_会展接待中心', cx: 247, cy: 153, height: 14, desc: '圆弧形会展接待中心' },
  { id: 44, name: '44_预留学院楼F', cx: 288, cy: 187, height: 14, desc: '预留学院楼F' },
  { id: 43, name: '43_预留学院楼A', cx: 256, cy: 232, height: 14, desc: '预留学院楼A (回字形)' },
  { id: 42, name: '42_预留学院楼B', cx: 259, cy: 343, height: 14, desc: '预留学院楼B (回字形)' },
  { id: 41, name: '41_预留学院楼G', cx: 271, cy: 393, height: 14, desc: '预留学院楼G' },
  { id: 46, name: '46_预留校前行政楼', cx: 420, cy: 129, height: 22, desc: '标志性行政楼主楼' },
  { id: 47, name: '47_博物馆', cx: 508, cy: 128, height: 16, desc: '大型现代博物馆' },
  { id: 48, name: '48_预留学院楼C', cx: 527, cy: 218, height: 14, desc: '预留学院楼C (双回廊)' },
  { id: 49, name: '49_预留学院楼D', cx: 527, cy: 260, height: 14, desc: '预留学院楼D (双回廊)' },
  { id: 50, name: '50_预留学院楼E', cx: 522, cy: 308, height: 14, desc: '预留学院楼E' },
  { id: 51, name: '51_预留文体楼', cx: 520, cy: 408, height: 18, desc: '大型球体多功能文体中心' }
];

function matchLandmark(comp) {
  let best = null;
  let bestDist = 45; // pixel tolerance
  for (const def of landmarkDefs) {
    const dx = comp.centroid[0] - def.cx;
    const dy = comp.centroid[1] - def.cy;
    const dist = Math.sqrt(dx * dx + dy * dy);
    if (dist < bestDist) {
      bestDist = dist;
      best = def;
    }
  }
  return best;
}

// 6. Assemble 3D Scene Nodes
const sceneElements = [];

// Base terrain ground (covers campus)
function createFlatBox(x0, y0, z0, x1, y1, z1) {
  return {
    positions: [
      x0, y1, z0,  x1, y1, z0,  x1, y1, z1,  x0, y1, z1,
      x0, y0, z0,  x1, y0, z0,  x1, y0, z1,  x0, y0, z1,
    ],
    normals: [
      0, 1, 0,  0, 1, 0,  0, 1, 0,  0, 1, 0,
      0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0,
    ],
    indices: [0, 1, 2, 0, 2, 3, 4, 6, 5, 4, 7, 6]
  };
}

// Base ground
sceneElements.push({
  name: 'Base_Ground',
  mesh: createFlatBox(-100, -0.6, -145, 100, 0, 145),
  color: [0.82, 0.86, 0.82, 1.0],
  roughness: 0.8
});

// Outer roads (陕鼓大道, 凤凰大道, 大学路, 规划一路)
sceneElements.push({
  name: 'Road_Shaangu',
  mesh: createFlatBox(-95, 0, -135, 95, 0.08, -118),
  color: [0.55, 0.55, 0.58, 1.0],
  roughness: 0.85
});
sceneElements.push({
  name: 'Road_Fenghuang',
  mesh: createFlatBox(-95, 0, -130, -70, 0.08, -30),
  color: [0.55, 0.55, 0.58, 1.0],
  roughness: 0.85
});
sceneElements.push({
  name: 'Road_Daxue',
  mesh: createFlatBox(72, 0, -130, 88, 0.08, 135),
  color: [0.55, 0.55, 0.58, 1.0],
  roughness: 0.85
});
sceneElements.push({
  name: 'Road_Guihua',
  mesh: createFlatBox(-85, 0, 126, 88, 0.08, 138),
  color: [0.55, 0.55, 0.58, 1.0],
  roughness: 0.85
});

// Central Ceremonial Axis (北门至图书馆广场)
sceneElements.push({
  name: 'Ceremonial_Axis',
  mesh: createFlatBox(-7, 0, -100, 7, 0.06, 0),
  color: [0.92, 0.92, 0.90, 1.0],
  roughness: 0.7
});

// 1. 北门牌楼
sceneElements.push({
  name: '01_北门_主牌坊',
  mesh: createFlatBox(-10, 0, -102, 10, 5, -97),
  color: [0.93, 0.65, 0.16, 1.0],
  roughness: 0.6
});

// 11. 主体育场 (田径场标准椭圆与看台)
const trackX0 = (455 - originX) * scale;
const trackX1 = (555 - originX) * scale;
const trackZ0 = (475 - originZ) * scale;
const trackZ1 = (600 - originZ) * scale;

sceneElements.push({
  name: '11_主体育场_田径跑道',
  mesh: createFlatBox(trackX0, 0, trackZ0, trackX1, 0.14, trackZ1),
  color: [0.86, 0.36, 0.28, 1.0], // 跑道红
  roughness: 0.7
});
sceneElements.push({
  name: '11_主体育场_天然草坪',
  mesh: createFlatBox(trackX0 + 4, 0, trackZ0 + 7, trackX1 - 4, 0.2, trackZ1 - 7),
  color: [0.26, 0.68, 0.30, 1.0], // 草坪绿
  roughness: 0.8
});
sceneElements.push({
  name: '11_主体育场_西看台',
  mesh: createFlatBox(trackX0 - 4, 0, trackZ0 + 3, trackX0, 4.5, trackZ1 - 3),
  color: [0.9, 0.92, 0.95, 1.0],
  roughness: 0.5
});
sceneElements.push({
  name: '11_主体育场_东看台',
  mesh: createFlatBox(trackX1, 0, trackZ0 + 3, trackX1 + 4, 4.5, trackZ1 - 3),
  color: [0.9, 0.92, 0.95, 1.0],
  roughness: 0.5
});

// 23. 副体育场
const subX0 = (255 - originX) * scale;
const subX1 = (315 - originX) * scale;
const subZ0 = (660 - originZ) * scale;
const subZ1 = (755 - originZ) * scale;

sceneElements.push({
  name: '23_副体育场_跑道',
  mesh: createFlatBox(subX0, 0, subZ0, subX1, 0.14, subZ1),
  color: [0.86, 0.36, 0.28, 1.0],
  roughness: 0.7
});
sceneElements.push({
  name: '23_副体育场_草坪',
  mesh: createFlatBox(subX0 + 3, 0, subZ0 + 5, subX1 - 3, 0.2, subZ1 - 5),
  color: [0.26, 0.68, 0.30, 1.0],
  roughness: 0.8
});

// 24. 篮球场群
const courtX0 = (175 - originX) * scale;
const courtX1 = (240 - originX) * scale;
const courtZ0 = (595 - originZ) * scale;
const courtZ1 = (720 - originZ) * scale;

sceneElements.push({
  name: '24_室外篮球排球场群',
  mesh: createFlatBox(courtX0, 0, courtZ0, courtX1, 0.12, courtZ1),
  color: [0.35, 0.55, 0.72, 1.0], // 篮球场青蓝
  roughness: 0.75
});

// 34. 教师公寓楼排 (右下角向阳排楼群)
// We preserve exact footprints extracted from the pixel mask!

// Process all building footprints extracted from the map
let matchedCount = 0;
let unnamedCount = 1;

buildingComponents.forEach((comp, idx) => {
  const match = matchLandmark(comp);
  let name = '';
  let height = comp.type === 'built' ? 14 : 15;
  let desc = '';
  let id = null;

  if (match) {
    name = match.name;
    height = match.height;
    desc = match.desc;
    id = match.id;
    matchedCount++;
  } else {
    if (comp.centroid[1] > 660 && comp.centroid[0] > 440) {
      name = `34_教师公寓东区_${unnamedCount++}`;
      desc = '向阳多层教师公寓楼';
      height = 14;
    } else if (comp.centroid[1] > 660 && comp.centroid[0] > 360) {
      name = `34_教师公寓中区_${unnamedCount++}`;
      desc = '向阳多层教师公寓楼';
      height = 14;
    } else {
      name = `${comp.type === 'built' ? '已建建筑' : '待建建筑'}_${unnamedCount++}`;
      desc = '校园功能单体建筑';
    }
  }

  // Extrude exact polygon mesh from pixel mask!
  const meshData = extrudeMaskToMesh(comp, height, 0);

  // Material color:
  // Built: Warm golden orange [0.93, 0.65, 0.16, 1.0]
  // Planned: Cyan modern sky blue [0.38, 0.70, 0.94, 1.0]
  const color = comp.type === 'built' ? [0.93, 0.65, 0.16, 1.0] : [0.38, 0.70, 0.94, 1.0];

  sceneElements.push({
    id: id,
    name: name,
    desc: desc,
    mesh: meshData,
    color: color,
    roughness: 0.6,
    centroid: [
      (comp.centroid[0] - originX) * scale,
      height,
      (comp.centroid[1] - originZ) * scale
    ],
    isBuilt: comp.type === 'built'
  });
});

console.log('Assembled elements:', sceneElements.length, 'Matched named landmarks:', matchedCount);

// 7. Assemble Binary GLB
let binBuffers = [];
let byteOffset = 0;
let bufferViews = [];
let accessors = [];
let materials = [];
let meshes = [];
let nodes = [];
let sceneNodes = [];

sceneElements.forEach((item, i) => {
  const meshData = item.mesh;

  const posArr = new Float32Array(meshData.positions);
  const posBuf = Buffer.from(posArr.buffer);

  const normArr = new Float32Array(meshData.normals);
  const normBuf = Buffer.from(normArr.buffer);

  const indArr = new Uint16Array(meshData.indices);
  const indBuf = Buffer.from(indArr.buffer);

  // 1. Position
  const posBvIndex = bufferViews.length;
  bufferViews.push({
    buffer: 0,
    byteOffset: byteOffset,
    byteLength: posBuf.length,
    target: 34962
  });
  binBuffers.push(posBuf);
  byteOffset += posBuf.length;

  let minX = Infinity, minY = Infinity, minZ = Infinity;
  let maxX = -Infinity, maxY = -Infinity, maxZ = -Infinity;
  for (let p = 0; p < meshData.positions.length; p += 3) {
    const px = meshData.positions[p];
    const py = meshData.positions[p + 1];
    const pz = meshData.positions[p + 2];
    if (px < minX) minX = px;
    if (py < minY) minY = py;
    if (pz < minZ) minZ = pz;
    if (px > maxX) maxX = px;
    if (py > maxY) maxY = py;
    if (pz > maxZ) maxZ = pz;
  }

  const posAccIndex = accessors.length;
  accessors.push({
    bufferView: posBvIndex,
    byteOffset: 0,
    componentType: 5126,
    count: meshData.positions.length / 3,
    type: 'VEC3',
    min: [minX, minY, minZ],
    max: [maxX, maxY, maxZ]
  });

  // 2. Normal
  const normBvIndex = bufferViews.length;
  bufferViews.push({
    buffer: 0,
    byteOffset: byteOffset,
    byteLength: normBuf.length,
    target: 34962
  });
  binBuffers.push(normBuf);
  byteOffset += normBuf.length;

  const normAccIndex = accessors.length;
  accessors.push({
    bufferView: normBvIndex,
    byteOffset: 0,
    componentType: 5126,
    count: meshData.normals.length / 3,
    type: 'VEC3'
  });

  // 3. Index buffer with 4-byte alignment
  const pad = (4 - (byteOffset % 4)) % 4;
  if (pad > 0) {
    binBuffers.push(Buffer.alloc(pad));
    byteOffset += pad;
  }

  const indBvIndex = bufferViews.length;
  bufferViews.push({
    buffer: 0,
    byteOffset: byteOffset,
    byteLength: indBuf.length,
    target: 34963
  });
  binBuffers.push(indBuf);
  byteOffset += indBuf.length;

  const pad2 = (4 - (byteOffset % 4)) % 4;
  if (pad2 > 0) {
    binBuffers.push(Buffer.alloc(pad2));
    byteOffset += pad2;
  }

  const indAccIndex = accessors.length;
  accessors.push({
    bufferView: indBvIndex,
    byteOffset: 0,
    componentType: 5123,
    count: meshData.indices.length,
    type: 'SCALAR'
  });

  // Material
  const matIndex = materials.length;
  materials.push({
    name: item.name + '_Mat',
    pbrMetallicRoughness: {
      baseColorFactor: item.color,
      metallicFactor: 0.1,
      roughnessFactor: item.roughness || 0.65
    }
  });

  // Mesh
  const meshIndex = meshes.length;
  meshes.push({
    name: item.name + '_Mesh',
    primitives: [{
      attributes: {
        POSITION: posAccIndex,
        NORMAL: normAccIndex
      },
      indices: indAccIndex,
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
  asset: { version: '2.0', generator: 'Pixel-Accurate Campus Map 3D Converter' },
  scenes: [{ name: 'CampusScene', nodes: sceneNodes }],
  scene: 0,
  nodes: nodes,
  meshes: meshes,
  materials: materials,
  accessors: accessors,
  bufferViews: bufferViews,
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

// Write GLB file
const targetGlb = path.join(__dirname, '..', 'entry', 'src', 'main', 'resources', 'rawfile', '3d', 'campus.glb');
fs.writeFileSync(targetGlb, glbBuffer);
console.log('Successfully saved pixel-accurate campus.glb to:', targetGlb, 'Size:', glbBuffer.length, 'bytes');

// 8. Generate HTML Interactive Viewer with complete building cards and camera targets
const b64 = glbBuffer.toString('base64');

// Building list for HUD
const buildingItems = sceneElements
  .filter(e => e.centroid !== undefined)
  .map(e => ({
    name: e.name,
    desc: e.desc || '',
    isBuilt: e.isBuilt,
    center: e.centroid
  }));

const htmlContent = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>大学数字校园 3D 沙盘 (与规划图 100% 格式对齐)</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      overflow: hidden;
      background: #0f172a;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif;
      user-select: none;
    }
    #header {
      position: absolute;
      top: 16px;
      left: 16px;
      color: #fff;
      background: rgba(15, 23, 42, 0.9);
      backdrop-filter: blur(12px);
      padding: 16px 22px;
      border-radius: 12px;
      border: 1px solid rgba(255,255,255,0.12);
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
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
    .dot-built { width: 12px; height: 12px; background: #eab308; border-radius: 3px; }
    .dot-planned { width: 12px; height: 12px; background: #38bdf8; border-radius: 3px; }
    .dot-track { width: 12px; height: 12px; background: #dc2626; border-radius: 3px; }

    #sidebar {
      position: absolute;
      top: 16px;
      right: 16px;
      bottom: 20px;
      width: 290px;
      background: rgba(15, 23, 42, 0.9);
      backdrop-filter: blur(12px);
      border-radius: 12px;
      border: 1px solid rgba(255,255,255,0.12);
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
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
      background: rgba(56, 189, 248, 0.18);
      transform: translateX(-2px);
      color: #fff;
    }
    .tag {
      font-size: 10px;
      padding: 2px 6px;
      border-radius: 4px;
      font-weight: 500;
    }
    .tag-built { background: rgba(234, 179, 8, 0.2); color: #facc15; }
    .tag-plan { background: rgba(56, 189, 248, 0.2); color: #38bdf8; }

    #footer-tip {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      color: #cbd5e1;
      background: rgba(15, 23, 42, 0.85);
      backdrop-filter: blur(8px);
      padding: 8px 24px;
      border-radius: 20px;
      border: 1px solid rgba(255,255,255,0.12);
      font-size: 12px;
      pointer-events: none;
    }

    #info-modal {
      position: absolute;
      bottom: 70px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(15, 23, 42, 0.95);
      border: 1px solid #38bdf8;
      border-radius: 12px;
      padding: 16px 24px;
      color: #fff;
      display: none;
      box-shadow: 0 12px 36px rgba(0,0,0,0.6);
      z-index: 20;
      text-align: center;
      min-width: 240px;
    }
  </style>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/GLTFLoader.js"></script>
</head>
<body>
  <div id="header">
    <h3>🏛️ 大学数字校园 3D 模型沙盘</h3>
    <p>基于规划原图像素级轮廓拉伸 | 格式: <code>campus.glb</code></p>
    <div class="legend">
      <div class="legend-item"><span class="dot-built"></span>已建建筑物 (黄色)</div>
      <div class="legend-item"><span class="dot-planned"></span>待建建筑物 (蓝色)</div>
      <div class="legend-item"><span class="dot-track"></span>主/副体育场跑道</div>
    </div>
  </div>

  <div id="sidebar">
    <div id="sidebar-header">
      <span>📍 校园建筑导览</span>
      <span style="font-size:11px;color:#94a3b8">${buildingItems.length} 个单体</span>
    </div>
    <input type="text" id="search-box" placeholder="搜索建筑名称..." />
    <div id="building-list"></div>
  </div>

  <div id="info-modal">
    <div id="modal-title" style="font-size:16px;font-weight:bold;color:#38bdf8;margin-bottom:6px;"></div>
    <div id="modal-desc" style="font-size:12px;color:#94a3b8;line-height:1.4;"></div>
  </div>

  <div id="footer-tip">
    🖱️ 鼠标左键：360°旋转 | 滚轮：拉近缩放 | 鼠标右键：平移 | 点击任意建筑：自动运镜聚焦
  </div>

  <script>
    const buildingsData = ${JSON.stringify(buildingItems)};

    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0xdde8f3);
    scene.fog = new THREE.FogExp2(0xdde8f3, 0.0032);

    const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 1200);
    camera.position.set(0, 150, 180);

    const renderer = new THREE.WebGLRenderer({ antialias: true });
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

    // 光照设置
    const hemiLight = new THREE.HemisphereLight(0xffffff, 0x8ba2b8, 0.95);
    scene.add(hemiLight);

    const sunLight = new THREE.DirectionalLight(0xfffaee, 0.95);
    sunLight.position.set(90, 180, 70);
    sunLight.castShadow = true;
    sunLight.shadow.mapSize.width = 2048;
    sunLight.shadow.mapSize.height = 2048;
    sunLight.shadow.camera.near = 10;
    sunLight.shadow.camera.far = 400;
    sunLight.shadow.camera.left = -120;
    sunLight.shadow.camera.right = 120;
    sunLight.shadow.camera.top = 150;
    sunLight.shadow.camera.bottom = -150;
    scene.add(sunLight);

    // 载入生成的精准 campus.glb
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

    // 点击 3D 拾取
    const raycaster = new THREE.Raycaster();
    const mouse = new THREE.Vector2();

    window.addEventListener('click', function(e) {
      if (e.clientX > window.innerWidth - 310) return;
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
console.log('Successfully updated preview HTML at:', targetHtml);
