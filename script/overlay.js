#!/usr/bin/node

const fs = require('fs');
const info = JSON.parse(fs.readFileSync(process.argv[2], 'utf-8'));

const kh = parseInt(process.env.KH);
const kv = parseInt(process.env.KV);
const hp = parseInt(process.env.H_WIDTH);
const vp = parseInt(process.env.V_HEIGHT);
const hb = Math.ceil(hp / kh);
const vb = Math.ceil(vp / kv);
const blks = hb * vb;

const arr = new Uint8Array(blks);
info.glyphs.forEach((g, i) => {
  const id = g.code - 48;
  const x0 = Math.floor((hb - g.bbox.width) / 2);
  const y0 = Math.floor((vb - g.bbox.height) / 2);
  g.pixels.forEach((l, y) => {
    l.forEach((v, x) => {
      if (v) arr[(x + x0) + (y + y0) * hb] |= 1 << id;
    });
  });
});

arr.forEach((w) => {
  const s = w.toString(2);
  console.log('0'.repeat(8 - s.length) + s);
});
