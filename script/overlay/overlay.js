const fs = require('fs');
const path = require('path');
const PNG = require('png-js');
const info = JSON.parse(fs.readFileSync(process.argv[2], 'utf-8'));

const hp = parseInt(process.env.H_WIDTH);
const vp = parseInt(process.env.V_HEIGHT);

async function run() {
  const glyphs = await Promise.all(info.glyphs.map(async (g, i) => {
    const buffer = await fs.promises.readFile(path.join(process.argv[2], '..', g.code.toString(16) + '.png'));
    const png = new PNG(buffer);
    const pixels = await new Promise((resolve) => { png.decode(resolve); });
    const res = {
      code: g.code - 48,
      width: png.width,
      height: png.height,
      pixels,
    };
    for (let i = 0; i < pixels.length / 4; i++) {
      if (!pixels[4 * i + 1]) {
        res.yMin = Math.floor(i / png.width);
        break;
      };
    }
    for (let i = pixels.length / 4 - 1; i >= 0; i--) {
      if (!pixels[4 * i + 1]) {
        res.yMax = Math.floor(i / png.width);
        break;
      };
    }
    return res;
  }));

  const dx = Math.max(...glyphs.map((g) => g.width));
  const xMin = Math.floor((hp - dx) / 2);
  const xMax = xMin + dx - 1;

  const dy = Math.max(...glyphs.map((g) => g.yMax - g.yMin));
  const yMin = Math.floor((vp - dy) / 2);
  const yMax = yMin + dy - 1;

  const blks = dx * dy;
  const arr = new Uint8Array(blks);
  glyphs.forEach((g, i) => {
    const x0 = Math.floor((dx - g.width) / 2);
    const y0 = -g.yMin + Math.floor((vp - (g.yMax - g.yMin)) / 2) - yMin;
    for (let y = g.yMin; y <= g.yMax; y++) {
      for (let x = 0; x < g.width; x++) {
        if (!g.pixels[(y * g.width + x) * 4 + 1]) {
          arr[(x + x0) + (y + y0) * dx] |= 1 << g.code;
        }
      }
    }
  });

  const width = 8;

  const words = Math.ceil(blks / width);
  console.error(`# OVERLAY_PIXELS=${blks}`);
  console.error(`# OVERLAY_WORDS=${words}`);
  console.error(`# OVERLAY_TOTAL=${words * 8 * width / 1024 / 1024} # Mib`);
  console.error(`OVERLAY_XMIN=${xMin}`);
  console.error(`OVERLAY_XMAX=${xMax}`);
  console.error(`OVERLAY_YMIN=${yMin}`);
  console.error(`OVERLAY_YMAX=${yMax}`);

  arr.forEach((w, i) => {
    const s = w.toString(16);
    process.stdout.write('0'.repeat(2 - s.length) + s, 'utf-8');
    if (i % width === width - 1) console.log();
  });

  if (blks % width) {
    console.log('0'.repeat(2 * (width - blks % width)));
  }
}

run();
