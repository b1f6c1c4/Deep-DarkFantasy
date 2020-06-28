#!/usr/bin/node

const fs = require('fs');
const info = JSON.parse(fs.readFileSync(process.argv[2], 'utf-8'));

const hp = parseInt(process.env.H_WIDTH);
const vp = parseInt(process.env.V_HEIGHT);

const dx = Math.max(...info.glyphs.map((g) => g.bbox.width));
const dy = Math.min(...info.glyphs.map((g) => g.bbox.height));
const xMin = Math.floor((hp - dx) / 2);
const xMax = xMin + dx - 1;
const yMin = Math.floor((vp - dy) / 2);
const yMax = yMin + dy - 1;

const blks = dx * dy;
const arr = new Uint8Array(blks);
info.glyphs.forEach((g, i) => {
  const id = g.code - 48;
  const x0 = Math.floor((dx - g.bbox.width) / 2);
  const y0 = Math.floor((dy - g.bbox.height) / 2);
  g.pixels.forEach((l, y) => {
    l.forEach((v, x) => {
      if (v) arr[(x + x0) + (y + y0) * hp] |= 1 << id;
    });
  });
});

console.error(`# OVERLAY_PIXELS=${blks}`);
console.error(`# OVERLAY_TOTAL=${blks * 8 / 1024 / 1024} # Mib`);
console.error(`OVERLAY_XMIN=${xMin}`);
console.error(`OVERLAY_XMAX=${xMax}`);
console.error(`OVERLAY_YMIN=${yMin}`);
console.error(`OVERLAY_YMAX=${yMax}`);

arr.forEach((w) => {
  const s = w.toString(16);
  console.log('0'.repeat(8 - s.length) + s);
});
