const fs = require('fs');
const path = require('path');

// ============================================================================
// High-Contrast Multi-Material Geometry Builder
// ============================================================================

class MultiMeshBuilder {
  constructor() {
    // Separate primitives for maximum visual contrast:
    // 0: Walls, 1: Roofs, 2: Parapet Trims, 3: Plinth Bases
    this.walls = { positions: [], normals: [], indices: [] };
    this.roofs = { positions: [], normals: [], indices: [] };
    this.trims = { positions: [], normals: [], indices: [] };
    this.plinths = { positions: [], normals: [], indices: [] };
  }

  addQuadTo(target, p0, p1, p2, p3, norm) {
    const base = target.positions.length / 3;
    target.positions.push(...p0, ...p1, ...p2, ...p3);
    target.normals.push(...norm, ...norm, ...norm, ...norm);
    target.indices.push(base, base + 1, base + 2, base, base + 2, base + 3);
  }

  // Add a solid box into a specific target primitive
  addBoxTo(target, x0, y0, z0, x1, y1, z1) {
    // Top (+Y)
    this.addQuadTo(target, [x0, y1, z1], [x1, y1, z1], [x1, y1, z0], [x0, y1, z0], [0, 1, 0]);
    // Bottom (-Y)
    this.addQuadTo(target, [x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1], [0, -1, 0]);
    // Front (+Z)
    this.addQuadTo(target, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1]);
    // Back (-Z)
    this.addQuadTo(target, [x1, y0, z0], [x0, y0, z0], [x0, y1, z0], [x1, y1, z0], [0, 0, -1]);
    // Right (+X)
    this.addQuadTo(target, [x1, y0, z1], [x1, y0, z0], [x1, y1, z0], [x1, y1, z1], [1, 0, 0]);
    // Left (-X)
    this.addQuadTo(target, [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0], [-1, 0, 0]);
  }

  // Architectural Building Block with:
  // - Dark grounding Plinth base (0 to plinthH)
  // - Saturated Facade Walls (plinthH to height)
  // - Darker contrasting Roof Slab
  // - Accent Parapet Trim around roof edge
  addBuildingBlock(x0, z0, x1, z1, height, plinthH = 0.5, parapetH = 0.6) {
    // 1. Plinth (dark concrete base)
    if (plinthH > 0) {
      this.addBoxTo(this.plinths, x0 - 0.15, 0, z0 - 0.15, x1 + 0.15, plinthH, z1 + 0.15);
    }

    const wallY0 = plinthH;
    const wallY1 = height;

    // 2. Facade Walls (4 vertical sides)
    this.addQuadTo(this.walls, [x0, wallY0, z1], [x1, wallY0, z1], [x1, wallY1, z1], [x0, wallY1, z1], [0, 0, 1]); // Front
    this.addQuadTo(this.walls, [x1, wallY0, z0], [x0, wallY0, z0], [x0, wallY1, z0], [x1, wallY1, z0], [0, 0, -1]); // Back
    this.addQuadTo(this.walls, [x1, wallY0, z1], [x1, wallY0, z0], [x1, wallY1, z0], [x1, wallY1, z1], [1, 0, 0]); // Right
    this.addQuadTo(this.walls, [x0, wallY0, z0], [x0, wallY0, z1], [x0, wallY1, z1], [x0, wallY1, z0], [-1, 0, 0]); // Left

    // 3. Roof Slab (dark contrasting top face)
    this.addQuadTo(this.roofs, [x0, wallY1, z1], [x1, wallY1, z1], [x1, wallY1, z0], [x0, wallY1, z0], [0, 1, 0]);

    // 4. Parapet Roof Trim (crisp 3D border)
    if (parapetH > 0) {
      const pW = 0.45;
      this.addBoxTo(this.trims, x0, wallY1, z0, x1, wallY1 + parapetH, z0 + pW); // North
      this.addBoxTo(this.trims, x0, wallY1, z1 - pW, x1, wallY1 + parapetH, z1); // South
      this.addBoxTo(this.trims, x0, wallY1, z0, x0 + pW, wallY1 + parapetH, z1); // West
      this.addBoxTo(this.trims, x1 - pW, wallY1, z0, x1, wallY1 + parapetH, z1); // East
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

    this.addBuildingBlock(x0, z0, x1, cz0, height);
    this.addBuildingBlock(x0, cz1, x1, z1, height);
    this.addBuildingBlock(x0, cz0, cx0, cz1, height);
    this.addBuildingBlock(cx1, cz0, x1, cz1, height);
  }

  // U-Shaped Building ("凹"字形)
  addUShapeBuilding(x0, z0, x1, z1, openDir, depthRatio, height) {
    const w = x1 - x0;
    const d = z1 - z0;
    const wingThickness = Math.min(w, d) * depthRatio;

    if (openDir === 'E') {
      this.addBuildingBlock(x0, z0, x0 + wingThickness, z1, height);
      this.addBuildingBlock(x0 + wingThickness, z0, x1, z0 + wingThickness, height);
      this.addBuildingBlock(x0 + wingThickness, z1 - wingThickness, x1, z1, height);
    } else if (openDir === 'W') {
      this.addBuildingBlock(x1 - wingThickness, z0, x1, z1, height);
      this.addBuildingBlock(x0, z0, x1 - wingThickness, z0 + wingThickness, height);
      this.addBuildingBlock(x0, z1 - wingThickness, x1 - wingThickness, z1, height);
    } else if (openDir === 'S') {
      this.addBuildingBlock(x0, z0, x1, z0 + wingThickness, height);
      this.addBuildingBlock(x0, z0 + wingThickness, x0 + wingThickness, z1, height);
      this.addBuildingBlock(x1 - wingThickness, z0 + wingThickness, x1, z1, height);
    } else {
      this.addBuildingBlock(x0, z1 - wingThickness, x1, z1, height);
      this.addBuildingBlock(x0, z0, x0 + wingThickness, z1 - wingThickness, height);
      this.addBuildingBlock(x1 - wingThickness, z0, x1, z1 - wingThickness, height);
    }
  }

  // E-Shaped Building (三翼梳状)
  addEShapeBuilding(x0, z0, x1, z1, height) {
    const spineW = (x1 - x0) * 0.35;
    const wingH = (z1 - z0) * 0.22;
    this.addBuildingBlock(x0, z0, x0 + spineW, z1, height);
    this.addBuildingBlock(x0 + spineW, z0, x1, z0 + wingH, height);
    this.addBuildingBlock(x0 + spineW, (z0 + z1) / 2 - wingH / 2, x1, (z0 + z1) / 2 + wingH / 2, height);
    this.addBuildingBlock(x0 + spineW, z1 - wingH, x1, z1, height);
  }

  // Rotunda / Cylinder Dome
  addCylinderBuilding(cx, cy, cz, radius, height, segments = 32) {
    const yBot = 0.5;
    const yTop = cy + height;

    // Plinth base
    this.addCylinderTo(this.plinths, cx, 0, cz, radius + 0.3, 0.5, segments);

    // Wall & Roof
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

      this.addQuadTo(this.walls, p0, p1, p2, p3, norm);

      // Contrasting Roof Cap
      const tCenter = [cx, yTop, cz];
      const base = this.roofs.positions.length / 3;
      this.roofs.positions.push(...tCenter, ...p3, ...p2);
      this.roofs.normals.push(0, 1, 0, 0, 1, 0, 0, 1, 0);
      this.roofs.indices.push(base, base + 1, base + 2);
    }
  }

  addCylinderTo(target, cx, cy, cz, radius, height, segments = 24) {
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

      this.addQuadTo(target, p0, p1, p2, p3, norm);

      const tCenter = [cx, yTop, cz];
      const base = target.positions.length / 3;
      target.positions.push(...tCenter, ...p3, ...p2);
      target.normals.push(0, 1, 0, 0, 1, 0, 0, 1, 0);
      target.indices.push(base, base + 1, base + 2);
    }
  }

  // Curved Arc Ribbon (for 45 会展中心)
  addCurvedArcBuilding(cx, cz, rInner, rOuter, angleStart, angleEnd, height, segments = 20) {
    const rad0 = (angleStart * Math.PI) / 180;
    const rad1 = (angleEnd * Math.PI) / 180;

    // Plinth
    for (let i = 0; i < segments; i++) {
      const t0 = rad0 + (rad1 - rad0) * (i / segments);
      const t1 = rad0 + (rad1 - rad0) * ((i + 1) / segments);
      const cos0 = Math.cos(t0), sin0 = Math.sin(t0);
      const cos1 = Math.cos(t1), sin1 = Math.sin(t1);

      const pIn0 = [cx + cos0 * rInner, 0.4, cz + sin0 * rInner];
      const pIn1 = [cx + cos1 * rInner, 0.4, cz + sin1 * rInner];
      const pOut0 = [cx + cos0 * rOuter, 0.4, cz + sin0 * rOuter];
      const pOut1 = [cx + cos1 * rOuter, 0.4, cz + sin1 * rOuter];

      const pInTop0 = [pIn0[0], height, pIn0[2]];
      const pInTop1 = [pIn1[0], height, pIn1[2]];
      const pOutTop0 = [pOut0[0], height, pOut0[2]];
      const pOutTop1 = [pOut1[0], height, pOut1[2]];

      // Roof (contrasting)
      this.addQuadTo(this.roofs, pInTop0, pInTop1, pOutTop1, pOutTop0, [0, 1, 0]);
      // Outer wall
      this.addQuadTo(this.walls, pOut0, pOut1, pOutTop1, pOutTop0, [(cos0 + cos1) / 2, 0, (sin0 + sin1) / 2]);
      // Inner wall
      this.addQuadTo(this.walls, pIn1, pIn0, pInTop0, pInTop1, [-(cos0 + cos1) / 2, 0, -(sin0 + sin1) / 2]);
    }
  }
}

// ============================================================================
// Enhanced High-Contrast PBR Material Palette
// ============================================================================

// High-contrast, non-glare PBR colors
// roughness: 0.82 ensures NO blinding specular white burnout under sunlight!
const MAT_BUILT_WALL = {
  name: 'Mat_Built_Wall',
  baseColor: [0.94, 0.60, 0.08, 1.0], // Deep warm amber orange
  roughness: 0.8,
  metallic: 0.05
};
const MAT_BUILT_ROOF = {
  name: 'Mat_Built_Roof',
  baseColor: [0.65, 0.32, 0.04, 1.0], // Dark terracotta/umber roof (high contrast against top glare!)
  roughness: 0.85,
  metallic: 0.05
};
const MAT_BUILT_TRIM = {
  name: 'Mat_Built_Trim',
  baseColor: [0.45, 0.20, 0.02, 1.0], // Dark roof parapet border
  roughness: 0.85,
  metallic: 0.05
};

const MAT_PLAN_WALL = {
  name: 'Mat_Plan_Wall',
  baseColor: [0.08, 0.56, 0.88, 1.0], // Deep, vibrant azure blue
  roughness: 0.78,
  metallic: 0.05
};
const MAT_PLAN_ROOF = {
  name: 'Mat_Plan_Roof',
  baseColor: [0.03, 0.32, 0.60, 1.0], // Dark cobalt navy roof (high contrast against sky blue!)
  roughness: 0.85,
  metallic: 0.05
};
const MAT_PLAN_TRIM = {
  name: 'Mat_Plan_Trim',
  baseColor: [0.01, 0.20, 0.42, 1.0], // Deep navy parapet border
  roughness: 0.85,
  metallic: 0.05
};

const MAT_PLINTH = {
  name: 'Mat_Building_Plinth',
  baseColor: [0.24, 0.28, 0.35, 1.0], // Dark slate foundation plinth
  roughness: 0.9,
  metallic: 0.0
};

const MAT_GROUND = {
  name: 'Mat_Campus_Ground',
  baseColor: [0.80, 0.83, 0.86, 1.0], // Clean cool slate plaza
  roughness: 0.9,
  metallic: 0.0
};
const MAT_GRASS = {
  name: 'Mat_Green_Spaces',
  baseColor: [0.18, 0.58, 0.24, 1.0], // Deep natural park green (high contrast with amber and blue!)
  roughness: 0.92,
  metallic: 0.0
};
const MAT_ROAD = {
  name: 'Mat_Outer_Roads',
  baseColor: [0.32, 0.34, 0.38, 1.0], // Dark asphalt grey
  roughness: 0.85,
  metallic: 0.0
};
const MAT_WATER = {
  name: 'Mat_Landscape_Lake',
  baseColor: [0.06, 0.62, 0.86, 0.95], // Crisp turquoise lake
  roughness: 0.2,
  metallic: 0.1
};
const MAT_TRACK = {
  name: 'Mat_Stadium_Track',
  baseColor: [0.78, 0.18, 0.14, 1.0], // Athletic brick crimson
  roughness: 0.85,
  metallic: 0.0
};
const MAT_PITCH = {
  name: 'Mat_Soccer_Pitch',
  baseColor: [0.12, 0.52, 0.16, 1.0], // Emerald turf
  roughness: 0.9,
  metallic: 0.0
};
const MAT_COURT = {
  name: 'Mat_Basketball_Courts',
  baseColor: [0.18, 0.42, 0.65, 1.0], // Rich blue court
  roughness: 0.85,
  metallic: 0.0
};

// ============================================================================
// Scene Building Assembly
// ============================================================================

const buildingEntities = [];

function registerBuilding(id, name, desc, isBuilt, builder, center) {
  buildingEntities.push({
    id,
    name,
    desc,
    isBuilt,
    builder,
    center
  });
}

// ----------------------------------------------------------------------------
// 1. BASE TERRAIN, ROADS & LANDSCAPING
// ----------------------------------------------------------------------------
const envPrimitives = [];

function addSimpleBox(positions, normals, indices, x0, y0, z0, x1, y1, z1) {
  function addQuad(p0, p1, p2, p3, norm) {
    const base = positions.length / 3;
    positions.push(...p0, ...p1, ...p2, ...p3);
    normals.push(...norm, ...norm, ...norm, ...norm);
    indices.push(base, base + 1, base + 2, base, base + 2, base + 3);
  }
  addQuad([x0, y1, z1], [x1, y1, z1], [x1, y1, z0], [x0, y1, z0], [0, 1, 0]);
  addQuad([x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1], [0, -1, 0]);
  addQuad([x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1]);
  addQuad([x1, y0, z0], [x0, y0, z0], [x0, y1, z0], [x1, y1, z0], [0, 0, -1]);
  addQuad([x1, y0, z1], [x1, y0, z0], [x1, y1, z0], [x1, y1, z1], [1, 0, 0]);
  addQuad([x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0], [-1, 0, 0]);
}

// Base Ground
{
  const p = { positions: [], normals: [], indices: [] };
  addSimpleBox(p.positions, p.normals, p.indices, -85, -0.6, -125, 85, 0, 130);
  envPrimitives.push({ name: 'Campus_Ground_Plaza', data: p, material: MAT_GROUND, center: [0, 0, 0] });
}

// Green Lawns (Deep green, high contrast!)
{
  const p = { positions: [], normals: [], indices: [] };
  addSimpleBox(p.positions, p.normals, p.indices, -65, 0, -100, 65, 0.05, -20);
  addSimpleBox(p.positions, p.normals, p.indices, -65, 0, -18, 65, 0.05, 120);
  envPrimitives.push({ name: 'Campus_Green_Spaces', data: p, material: MAT_GRASS, center: [0, 0, 0] });
}

// Outer Roads
{
  const p = { positions: [], normals: [], indices: [] };
  addSimpleBox(p.positions, p.normals, p.indices, -85, 0, -120, 85, 0.08, -108); // 陕鼓大道
  addSimpleBox(p.positions, p.normals, p.indices, -84, 0, -115, -68, 0.08, -25); // 凤凰大道
  addSimpleBox(p.positions, p.normals, p.indices, 68, 0, -115, 84, 0.08, 125);   // 大学路
  addSimpleBox(p.positions, p.normals, p.indices, -75, 0, 118, 84, 0.08, 128);   // 规划一路
  envPrimitives.push({ name: 'Outer_Avenues', data: p, material: MAT_ROAD, center: [0, 0, 0] });
}

// Lake (Water)
{
  const p = { positions: [], normals: [], indices: [] };
  addSimpleBox(p.positions, p.normals, p.indices, 12, 0.06, -2, 28, 0.12, 26);
  envPrimitives.push({ name: 'Landscape_Lake', data: p, material: MAT_WATER, center: [20, 0, 12] });
}

// Stadium Track & Pitch & Stands
{
  const pTrack = { positions: [], normals: [], indices: [] };
  addSimpleBox(pTrack.positions, pTrack.normals, pTrack.indices, 38, 0, 24, 68, 0.14, 66);
  envPrimitives.push({ name: '11_主体育场_田径跑道', data: pTrack, material: MAT_TRACK, center: [53, 0, 45], id: 11 });

  const pPitch = { positions: [], normals: [], indices: [] };
  addSimpleBox(pPitch.positions, pPitch.normals, pPitch.indices, 43, 0.14, 30, 63, 0.22, 60);
  envPrimitives.push({ name: '11_主体育场_足球坪', data: pPitch, material: MAT_PITCH, center: [53, 0, 45] });

  const pStand = { positions: [], normals: [], indices: [] };
  addSimpleBox(pStand.positions, pStand.normals, pStand.indices, 35, 0, 26, 38, 5, 64);
  addSimpleBox(pStand.positions, pStand.normals, pStand.indices, 34, 5, 25, 39, 6.2, 65);
  addSimpleBox(pStand.positions, pStand.normals, pStand.indices, 68, 0, 26, 71, 5, 64);
  addSimpleBox(pStand.positions, pStand.normals, pStand.indices, 67, 5, 25, 72, 6.2, 65);
  envPrimitives.push({ name: '11_主体育场_观礼看台', data: pStand, material: MAT_BUILT_WALL, center: [53, 6, 45] });
}

// Secondary Stadium
{
  const pTrack = { positions: [], normals: [], indices: [] };
  addSimpleBox(pTrack.positions, pTrack.normals, pTrack.indices, -20, 0, 82, 0, 0.14, 114);
  envPrimitives.push({ name: '23_副体育场_跑道', data: pTrack, material: MAT_TRACK, center: [-10, 0, 98], id: 23 });

  const pPitch = { positions: [], normals: [], indices: [] };
  addSimpleBox(pPitch.positions, pPitch.normals, pPitch.indices, -17, 0.14, 86, -3, 0.22, 110);
  envPrimitives.push({ name: '23_副体育场_足球场', data: pPitch, material: MAT_PITCH, center: [-10, 0, 98] });
}

// Outdoor Courts (24)
{
  const p = { positions: [], normals: [], indices: [] };
  addSimpleBox(p.positions, p.normals, p.indices, -46, 0, 70, -24, 0.12, 108);
  envPrimitives.push({ name: '24_室外篮球排球场群', data: p, material: MAT_COURT, center: [-35, 0, 89], id: 24 });
}

// Pool (27)
{
  const p = { positions: [], normals: [], indices: [] };
  addSimpleBox(p.positions, p.normals, p.indices, 5, 0, 96, 13, 0.15, 112);
  envPrimitives.push({ name: '27_游泳池', data: p, material: MAT_WATER, center: [9, 0, 104], id: 27 });
}

// ----------------------------------------------------------------------------
// 2. DETAILED ARCHITECTURAL BUILDINGS (WITH ROOF CONTRAST!)
// ----------------------------------------------------------------------------

// 08. 图书馆 (中央标志性穹顶 + 扇形大跨翼楼)
{
  const b = new MultiMeshBuilder();
  b.addCylinderBuilding(0, 0, 0, 9, 20, 32);
  // Crescent fan wings
  const rad0 = (-65 * Math.PI) / 180, rad1 = (65 * Math.PI) / 180;
  for (let i = 0; i < 20; i++) {
    const t0 = rad0 + (rad1 - rad0) * (i / 20);
    const t1 = rad0 + (rad1 - rad0) * ((i + 1) / 20);
    const c0 = Math.cos(t0), s0 = Math.sin(t0), c1 = Math.cos(t1), s1 = Math.sin(t1);
    const pIn0 = [c0 * 9, 0.5, s0 * 9], pIn1 = [c1 * 9, 0.5, s1 * 9];
    const pOut0 = [c0 * 18, 0.5, s0 * 18], pOut1 = [c1 * 18, 0.5, s1 * 18];
    const pInT0 = [pIn0[0], 13, pIn0[2]], pInT1 = [pIn1[0], 13, pIn1[2]];
    const pOutT0 = [pOut0[0], 13, pOut0[2]], pOutT1 = [pOut1[0], 13, pOut1[2]];
    b.addQuadTo(b.roofs, pInT0, pInT1, pOutT1, pOutT0, [0, 1, 0]);
    b.addQuadTo(b.walls, pOut0, pOut1, pOutT1, pOutT0, [(c0 + c1)/2, 0, (s0 + s1)/2]);
    b.addQuadTo(b.walls, pIn1, pIn0, pInT0, pInT1, [-(c0 + c1)/2, 0, -(s0 + s1)/2]);
  }
  b.addBuildingBlock(-12, -10, -4, -2, 13);
  b.addBuildingBlock(4, -10, 12, -2, 13);
  registerBuilding(8, '08_图书馆', '中央标志性扇形/圆顶主图书馆 (高20米)', true, b, [0, 20, 0]);
}

// 01. 北门
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(-10, -96, 10, -90, 6, 0.5, 0.8);
  registerBuilding(1, '01_北门', '主校区北门礼仪入口牌坊', true, b, [0, 7.5, -93]);
}

// 04, 05. 教学楼 C、D (凹字形朝东院落)
{
  const b4 = new MultiMeshBuilder();
  b4.addUShapeBuilding(12, -70, 28, -52, 'E', 0.32, 15);
  registerBuilding(4, '04_教学楼C座', '东北教学楼C座 (凹字形通透庭院)', true, b4, [20, 15, -61]);

  const b5 = new MultiMeshBuilder();
  b5.addUShapeBuilding(12, -48, 28, -30, 'E', 0.32, 15);
  registerBuilding(5, '05_教学楼D座', '东北教学楼D座 (凹字形通透庭院)', true, b5, [20, 15, -39]);
}

// 02, 03. 教学楼 A、B
{
  const b3 = new MultiMeshBuilder();
  b3.addBuildingBlock(33, -68, 45, -60, 15);
  b3.addBuildingBlock(39, -60, 45, -50, 15);
  registerBuilding(3, '03_教学楼B座', '东北教学楼B座 (L形折角翼楼)', true, b3, [39, 15, -59]);

  const b2 = new MultiMeshBuilder();
  b2.addBuildingBlock(33, -46, 47, -38, 15);
  b2.addBuildingBlock(39, -38, 47, -26, 15);
  registerBuilding(2, '02_教学楼A座', '东北教学楼A座 (主教学楼大楼)', true, b2, [40, 15, -36]);
}

// 07, 06. 教学实验楼 B、A
{
  const b7 = new MultiMeshBuilder();
  b7.addCourtyardBuilding(-28, -66, -10, -48, 8, 8, 15);
  registerBuilding(7, '07_教学实验楼B座', '西北教学实验楼B座 (回字形内天井院落)', true, b7, [-19, 15, -57]);

  const b6 = new MultiMeshBuilder();
  b6.addBuildingBlock(-30, -46, -12, -38, 15);
  b6.addBuildingBlock(-24, -38, -18, -30, 15);
  b6.addBuildingBlock(-30, -30, -12, -22, 15);
  registerBuilding(6, '06_教学实验楼A座', '西北教学实验楼A座 (工字形现代实验大楼)', true, b6, [-21, 15, -34]);
}

// 18, 19, 15, 16, 17. 学生宿舍群
{
  const b18 = new MultiMeshBuilder();
  b18.addUShapeBuilding(-46, 10, -28, 24, 'S', 0.35, 17);
  registerBuilding(18, '18_1号学生公寓楼', '1号学生公寓楼 (凹字形朝南采光庭院)', true, b18, [-37, 17, 17]);

  const b19 = new MultiMeshBuilder();
  b19.addEShapeBuilding(-46, 28, -26, 42, 17);
  registerBuilding(19, '19_2号学生公寓楼', '2号学生公寓楼 (E字形多翼大体量公寓)', true, b19, [-36, 17, 35]);

  const b15 = new MultiMeshBuilder();
  b15.addBuildingBlock(-46, 46, -30, 54, 17);
  b15.addBuildingBlock(-40, 54, -26, 62, 17);
  registerBuilding(15, '15_4号学生公寓楼', '4号学生公寓楼 (错层采光阶梯公寓)', true, b15, [-36, 17, 54]);

  const b16 = new MultiMeshBuilder();
  b16.addBuildingBlock(-24, 52, -10, 60, 17);
  registerBuilding(16, '16_5号学生公寓楼', '5号学生公寓楼', true, b16, [-17, 17, 56]);

  const b17 = new MultiMeshBuilder();
  b17.addBuildingBlock(-24, 26, -10, 32, 17);
  b17.addBuildingBlock(-20, 32, -14, 40, 17);
  b17.addBuildingBlock(-24, 40, -10, 46, 17);
  registerBuilding(17, '17_3号学生公寓楼', '3号学生公寓楼 (工字形联排公寓)', true, b17, [-17, 17, 36]);
}

// 37. 综合服务楼及食堂
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(-4, 22, 10, 38, 13);
  b.addBuildingBlock(-1, 38, 7, 44, 10);
  registerBuilding(37, '37_综合服务楼及食堂', '综合服务楼及一期食堂综合体', true, b, [3, 13, 33]);
}

// 13, 14. 6号、7号学生公寓楼
{
  const b13 = new MultiMeshBuilder();
  b13.addUShapeBuilding(-4, 48, 12, 60, 'S', 0.35, 17);
  registerBuilding(13, '13_6号学生公寓楼', '6号学生公寓楼 (凹字形通透院落)', true, b13, [4, 17, 54]);

  const b14 = new MultiMeshBuilder();
  b14.addUShapeBuilding(-4, 64, 12, 76, 'S', 0.35, 17);
  registerBuilding(14, '14_7号学生公寓楼', '7号学生公寓楼 (凹字形通透院落)', true, b14, [4, 17, 70]);
}

// 22. 学生浴室
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(-24, 64, -12, 74, 8);
  registerBuilding(22, '22_学生浴室', '学生公共浴室中心', true, b, [-18, 8, 69]);
}

// 38, 12. 8号学生公寓楼 & 东区学生公寓
{
  const b38 = new MultiMeshBuilder();
  b38.addBuildingBlock(16, 24, 30, 32, 17);
  b38.addBuildingBlock(22, 32, 30, 40, 17);
  registerBuilding(38, '38_8号学生公寓楼', '8号学生公寓楼', true, b38, [23, 17, 32]);

  const b12 = new MultiMeshBuilder();
  b12.addBuildingBlock(16, 44, 24, 60, 17);
  b12.addBuildingBlock(24, 52, 32, 60, 17);
  registerBuilding(12, '12_学生公寓楼', '东区学生公寓楼', true, b12, [24, 17, 52]);
}

// 20. 学生食堂, 21. 开水房
{
  const b20 = new MultiMeshBuilder();
  b20.addBuildingBlock(16, 64, 34, 76, 12, 0.6);
  registerBuilding(20, '20_学生食堂', '园区主力学生大食堂', true, b20, [25, 12, 70]);

  const b21 = new MultiMeshBuilder();
  b21.addBuildingBlock(12, 66, 15, 74, 5);
  registerBuilding(21, '21_开水房', '便民开水供应房', true, b21, [13.5, 5, 70]);
}

// 09. 大学生活动中心
{
  const b = new MultiMeshBuilder();
  b.addCylinderBuilding(32, 0, 15, 7.5, 14, 24);
  b.addBuildingBlock(28, 8, 38, 16, 10);
  registerBuilding(9, '09_大学生活动中心', '湖畔大学生活动与交流中心', true, b, [33, 14, 14]);
}

// 31. 南锅炉房, 36. 器材仓库
{
  const b31 = new MultiMeshBuilder();
  b31.addBuildingBlock(6, 84, 12, 92, 6);
  registerBuilding(31, '31_南锅炉房', '南区供暖锅炉房', true, b31, [9, 6, 88]);

  const b36 = new MultiMeshBuilder();
  b36.addBuildingBlock(-24, 88, -21, 104, 4);
  registerBuilding(36, '36_体育器材仓库', '体育器材与保障中心', true, b36, [-22.5, 4, 96]);
}

// 34. 教师公寓楼群 (8栋朝南联排住宅)
{
  const b = new MultiMeshBuilder();
  const zStarts = [88, 96, 104, 112];
  for (let r = 0; r < 4; r++) {
    const z = zStarts[r];
    b.addBuildingBlock(18, z, 42, z + 5, 15, 0.4);
    b.addBuildingBlock(46, z, 70, z + 5, 15, 0.4);
  }
  registerBuilding(34, '34_教师公寓楼群', '东南生活区8栋并联向阳多层住宅楼群', true, b, [44, 15, 100]);
}

// 35. 勤工助学基地, 33. 校医院
{
  const b35 = new MultiMeshBuilder();
  b35.addBuildingBlock(18, 80, 28, 86, 9);
  registerBuilding(35, '35_勤工助学基地', '勤工助学基地综合楼', true, b35, [23, 9, 83]);

  const bHosp = new MultiMeshBuilder();
  bHosp.addBuildingBlock(64, 68, 71, 76, 10);
  registerBuilding(33, '33_校医院', '校园医疗保障中心与校医院', true, bHosp, [67.5, 10, 72]);
}

// 32, 40, 39
{
  const b32 = new MultiMeshBuilder();
  b32.addBuildingBlock(-48, -24, -43, -16, 6);
  registerBuilding(32, '32_北锅炉房', '北区供暖与保障锅炉房', true, b32, [-45.5, 6, -20]);

  const b40 = new MultiMeshBuilder();
  b40.addBuildingBlock(-64, -20, -50, -8, 10);
  registerBuilding(40, '40_工程训练中心', '实践与工程训练中心大楼', true, b40, [-57, 10, -14]);

  const b39 = new MultiMeshBuilder();
  b39.addBuildingBlock(-62, 0, -57, 8, 5);
  registerBuilding(39, '39_中心配电室', '全校中心配电与电力枢纽', true, b39, [-59.5, 5, 4]);
}

// ----------------------------------------------------------------------------
// 3. PLANNED BUILDINGS (待建建筑物群 🟦 41~51)
// ----------------------------------------------------------------------------

// 45. 会展接待中心 (大跨度弧形现代曲面建筑)
{
  const b = new MultiMeshBuilder();
  b.addCurvedArcBuilding(-30, -60, 20, 28, 135, 205, 15, 24);
  registerBuilding(45, '45_会展接待中心', '西北大型弧形曲面会展与国际交流中心', false, b, [-44, 15, -76]);
}

// 44. 预留学院楼 F
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(-32, -74, -12, -66, 15);
  b.addBuildingBlock(-20, -66, -12, -60, 15);
  registerBuilding(44, '44_预留学院楼F', '规划学院教学实验综合楼F', false, b, [-22, 15, -67]);
}

// 43, 42. 预留学院楼 A、B ("回"字形)
{
  const b43 = new MultiMeshBuilder();
  b43.addCourtyardBuilding(-46, -66, -32, -50, 6, 6, 15);
  registerBuilding(43, '43_预留学院楼A', '规划学院教学楼A (回字形院落)', false, b43, [-39, 15, -58]);

  const b42 = new MultiMeshBuilder();
  b42.addCourtyardBuilding(-46, -46, -32, -30, 6, 6, 15);
  registerBuilding(42, '42_预留学院楼B', '规划学院教学楼B (回字形院落)', false, b42, [-39, 15, -38]);
}

// 41. 预留学院楼 G
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(-44, -26, -30, -18, 15);
  b.addBuildingBlock(-38, -18, -30, -10, 15);
  registerBuilding(41, '41_预留学院楼G', '规划学院教学楼G', false, b, [-37, 15, -18]);
}

// 46. 预留校前行政楼 (主立面标志性高层 24m)
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(15, -92, 27, -80, 24, 0.8, 1.0);
  b.addBuildingBlock(27, -88, 33, -80, 14);
  registerBuilding(46, '46_预留校前行政楼', '校区主入口标志性行政管理主楼 (高24米)', false, b, [21, 24, -86]);
}

// 47. 博物馆
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(40, -94, 68, -80, 16, 0.8, 0.8);
  b.addBuildingBlock(52, -80, 68, -72, 12);
  registerBuilding(47, '47_博物馆', '东北角大型现代综合博物馆与文化展馆', false, b, [54, 16, -83]);
}

// 48, 49. 预留学院楼 C、D (双回廊)
{
  const b48 = new MultiMeshBuilder();
  b48.addCourtyardBuilding(48, -68, 66, -50, 8, 8, 15);
  registerBuilding(48, '48_预留学院楼C', '东部规划学院综合大楼C (回字形)', false, b48, [57, 15, -59]);

  const b49 = new MultiMeshBuilder();
  b49.addCourtyardBuilding(48, -48, 66, -30, 8, 8, 15);
  registerBuilding(49, '49_预留学院楼D', '东部规划学院综合大楼D (回字形)', false, b49, [57, 15, -39]);
}

// 50. 预留学院楼 E
{
  const b = new MultiMeshBuilder();
  b.addBuildingBlock(48, -26, 66, -18, 15);
  b.addBuildingBlock(56, -18, 66, -10, 15);
  registerBuilding(50, '50_预留学院楼E', '东部规划学院教学实验楼E', false, b, [57, 15, -18]);
}

// 51. 预留文体楼 (大剧院 / 球形多功能文体中心)
{
  const b = new MultiMeshBuilder();
  b.addCylinderBuilding(54, 0, 4, 11, 20, 32);
  b.addBuildingBlock(44, -6, 64, 0, 8);
  b.addBuildingBlock(44, 8, 64, 14, 8);
  registerBuilding(51, '51_预留文体楼', '东区多功能综合文体中心与演艺剧场大巨蛋', false, b, [54, 20, 4]);
}

console.log('Total buildings configured:', buildingEntities.length);

// ============================================================================
// Assemble GLB with Multi-Primitive Meshes (Walls, Roofs, Trims, Plinths)
// ============================================================================

let binBuffers = [];
let byteOffset = 0;
let bufferViews = [];
let accessors = [];
let materials = [];
let meshes = [];
let nodes = [];
let sceneNodes = [];

const materialIndexMap = new Map();

function getMaterialIndex(matDef) {
  if (materialIndexMap.has(matDef.name)) return materialIndexMap.get(matDef.name);
  const idx = materials.length;
  materials.push({
    name: matDef.name,
    doubleSided: true,
    pbrMetallicRoughness: {
      baseColorFactor: matDef.baseColor,
      metallicFactor: matDef.metallic || 0.0,
      roughnessFactor: matDef.roughness || 0.8
    }
  });
  materialIndexMap.set(matDef.name, idx);
  return idx;
}

function appendBufferData(dataObj, matDef) {
  if (!dataObj || dataObj.positions.length === 0) return null;

  const posArr = new Float32Array(dataObj.positions);
  const posBuf = Buffer.from(posArr.buffer);
  const normArr = new Float32Array(dataObj.normals);
  const normBuf = Buffer.from(normArr.buffer);
  const indArr = new Uint16Array(dataObj.indices);
  const indBuf = Buffer.from(indArr.buffer);

  // Position
  const posBv = bufferViews.length;
  bufferViews.push({ buffer: 0, byteOffset, byteLength: posBuf.length, target: 34962 });
  binBuffers.push(posBuf);
  byteOffset += posBuf.length;

  let minX = Infinity, minY = Infinity, minZ = Infinity;
  let maxX = -Infinity, maxY = -Infinity, maxZ = -Infinity;
  for (let p = 0; p < dataObj.positions.length; p += 3) {
    minX = Math.min(minX, dataObj.positions[p]);
    minY = Math.min(minY, dataObj.positions[p + 1]);
    minZ = Math.min(minZ, dataObj.positions[p + 2]);
    maxX = Math.max(maxX, dataObj.positions[p]);
    maxY = Math.max(maxY, dataObj.positions[p + 1]);
    maxZ = Math.max(maxZ, dataObj.positions[p + 2]);
  }

  const posAcc = accessors.length;
  accessors.push({
    bufferView: posBv,
    byteOffset: 0,
    componentType: 5126,
    count: dataObj.positions.length / 3,
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
    count: dataObj.normals.length / 3,
    type: 'VEC3'
  });

  // Indices
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
    count: dataObj.indices.length,
    type: 'SCALAR'
  });

  return {
    attributes: { POSITION: posAcc, NORMAL: normAcc },
    indices: indAcc,
    material: getMaterialIndex(matDef)
  };
}

// 1. Add Environment Primitives
envPrimitives.forEach(env => {
  const prim = appendBufferData(env.data, env.material);
  if (prim) {
    const meshIdx = meshes.length;
    meshes.push({ name: env.name + '_Mesh', primitives: [prim] });
    const nodeIdx = nodes.length;
    nodes.push({ name: env.name, mesh: meshIdx });
    sceneNodes.push(nodeIdx);
  }
});

// 2. Add Multi-Primitive Buildings
buildingEntities.forEach(b => {
  const primitives = [];

  const wallMat = b.isBuilt ? MAT_BUILT_WALL : MAT_PLAN_WALL;
  const roofMat = b.isBuilt ? MAT_BUILT_ROOF : MAT_PLAN_ROOF;
  const trimMat = b.isBuilt ? MAT_BUILT_TRIM : MAT_PLAN_TRIM;

  const pWall = appendBufferData(b.builder.walls, wallMat);
  if (pWall) primitives.push(pWall);

  const pRoof = appendBufferData(b.builder.roofs, roofMat);
  if (pRoof) primitives.push(pRoof);

  const pTrim = appendBufferData(b.builder.trims, trimMat);
  if (pTrim) primitives.push(pTrim);

  const pPlinth = appendBufferData(b.builder.plinths, MAT_PLINTH);
  if (pPlinth) primitives.push(pPlinth);

  if (primitives.length > 0) {
    const meshIdx = meshes.length;
    meshes.push({ name: b.name + '_Mesh', primitives });
    const nodeIdx = nodes.length;
    nodes.push({ name: b.name, mesh: meshIdx });
    sceneNodes.push(nodeIdx);
  }
});

const totalBinBuffer = Buffer.concat(binBuffers);
const gltfJson = {
  asset: { version: '2.0', generator: 'High-Contrast Architectural Campus Model Generator' },
  scenes: [{ name: 'CampusScene', nodes: sceneNodes }],
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
console.log('Saved high-contrast architectural campus.glb to:', targetGlb, 'Size:', glbBuffer.length, 'bytes');

// Update preview_3d_campus.html
const b64 = glbBuffer.toString('base64');
const hudItems = buildingEntities.map(b => ({
  id: b.id,
  name: b.name,
  desc: b.desc,
  isBuilt: b.isBuilt,
  center: b.center
}));

const htmlContent = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>大学数字校园 3D 建筑沙盘 (高对比度强化版)</title>
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
      background: rgba(15, 23, 42, 0.92);
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
    .dot-built { width: 14px; height: 14px; background: #ea580c; border: 2px solid #7c2d12; border-radius: 3px; }
    .dot-planned { width: 14px; height: 14px; background: #0284c7; border: 2px solid #082f49; border-radius: 3px; }
    .dot-track { width: 14px; height: 14px; background: #dc2626; border-radius: 3px; }
    .dot-green { width: 14px; height: 14px; background: #16a34a; border-radius: 3px; }

    #sidebar {
      position: absolute;
      top: 16px;
      right: 16px;
      bottom: 20px;
      width: 300px;
      background: rgba(15, 23, 42, 0.92);
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
      font-weight: 600;
    }
    .tag-built { background: rgba(234, 88, 12, 0.25); color: #fb923c; border: 1px solid rgba(234, 88, 12, 0.4); }
    .tag-plan { background: rgba(2, 132, 199, 0.25); color: #38bdf8; border: 1px solid rgba(2, 132, 199, 0.4); }

    #footer-tip {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      color: #cbd5e1;
      background: rgba(15, 23, 42, 0.88);
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
      background: rgba(15, 23, 42, 0.95);
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
    <h3>🏛️ 大学数字校园 3D 沙盘 (高对比度强化版)</h3>
    <p>深色屋顶封盖 + 墙面对比 + 基座阴影 | 格式: <code>campus.glb</code></p>
    <div class="legend">
      <div class="legend-item"><span class="dot-built"></span>已建建筑物 (深琥珀+陶土顶)</div>
      <div class="legend-item"><span class="dot-planned"></span>待建建筑物 (科技蓝+深青顶)</div>
      <div class="legend-item"><span class="dot-green"></span>自然深绿绿化</div>
      <div class="legend-item"><span class="dot-track"></span>标准红胶田径场</div>
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
    scene.background = new THREE.Color(0xd0dbe6);
    scene.fog = new THREE.FogExp2(0xd0dbe6, 0.0028);

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

    // 平衡的环境天光与直射日光，避免顶面曝白
    const hemiLight = new THREE.HemisphereLight(0xffffff, 0x64748b, 0.85);
    scene.add(hemiLight);

    const sunLight = new THREE.DirectionalLight(0xfff7ed, 0.95);
    sunLight.position.set(70, 160, 60);
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

    // 载入生成的 high contrast campus.glb
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
console.log('Successfully written high-contrast architectural campus files!');
