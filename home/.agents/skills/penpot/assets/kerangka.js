// Kerangka helper untuk skrip build Penpot. Salin dan sesuaikan.
//
// Isi yang paling penting ada di `attach()`: setiap appendChild ke parent TANPA flex layout
// wajib diikuti setParentXY(child, 0, 0). Tanpa itu anaknya tetap di koordinat absolut 0,0
// halaman dan semua layar menumpuk jadi satu. Ini berlaku untuk board biasa MAUPUN instance
// komponen.
//
// Jalankan sebagai body sebuah fungsi: `return` di akhir itu sah.

const page = penpot.currentPage;
const root = page.root;

// Prasyarat: pastikan system sudah ada, dan gagal dengan pesan jelas kalau belum.
const TY = {}; penpot.library.local.typographies.forEach(t => { TY[t.name] = t; });
const KOMP = {}; penpot.library.local.components.forEach(c => { KOMP[c.name] = c; });
const kurang = ["meta"].filter(n => !TY[n]).concat(["Chip"].filter(n => !KOMP[n]));
if (kurang.length) throw new Error("jalankan skrip system dulu. Kurang: " + kurang.join(", "));

// Bersihkan area layar saja — jangan sentuh area design system (y >= 2000).
root.children.filter(c => c.y < 2000).forEach(c => c.remove());

const C = { bg:"#F7F3EA", surface:"#FFFDF8", ink:"#1B1A17", inkSoft:"#4A453D", muted:"#6F685D",
            hairline:"#E7DFD0", accent:"#D9A441", progress:"#2FA36B", broken:"#C2703D" };

// ATURAN: `vs:"fix"` WAJIB disertai tinggi eksplisit (`h`). Tanpa itu board memakai tinggi
// bawaan dan kontennya mengambang di dalam kotak raksasa.
const box = (parent, name, o) => {
  o = o || {};
  const b = penpot.createBoard();
  parent.appendChild(b);
  penpotUtils.setParentXY(b, 0, 0);              // <- jebakan nomor satu
  b.name = name;
  if (o.w > 0 && o.h > 0) b.resize(o.w, o.h);
  b.fills = o.bg ? [{ fillColor: o.bg, fillOpacity: 1 }] : [];
  const fl = b.addFlexLayout();
  fl.dir = o.dir || "column"; fl.rowGap = o.rg || 0; fl.columnGap = o.cg || 0;
  fl.horizontalSizing = o.hs || "fill"; fl.verticalSizing = o.vs || "auto";
  if (o.px != null) fl.horizontalPadding = o.px;
  if (o.py != null) fl.verticalPadding = o.py;
  if (o.align) fl.alignItems = o.align;
  if (o.justify) fl.justifyContent = o.justify;
  if (o.r != null) b.borderRadius = o.r;
  if (o.stroke) b.strokes = o.stroke;
  return b;
};

// `t` = nama tipografi. lineHeight DISET ULANG karena applyTypography melewatkannya —
// tanpa baris ini seluruh skala line-height jadi hiasan dan semua teks kembali ke 1.2.
const txt = (parent, chars, o) => {
  o = o || {};
  const t = penpot.createText(chars);
  parent.appendChild(t);
  penpotUtils.setParentXY(t, 0, 0);
  t.name = o.name || chars.slice(0, 22);
  const ty = TY[o.t];
  if (ty) { t.applyTypography(ty); t.lineHeight = ty.lineHeight; }
  else { if (o.size) t.fontSize = String(o.size); if (o.weight) t.fontWeight = String(o.weight); }
  if (o.dir) t.direction = o.dir;
  t.align = o.align || "left";
  t.fills = [{ fillColor: o.color || C.ink, fillOpacity: 1 }];
  if (o.hug) { t.growType = "auto-width"; if (t.layoutChild) t.layoutChild.horizontalSizing = "auto"; }
  else { t.growType = "auto-height"; if (t.layoutChild) t.layoutChild.horizontalSizing = "fill"; }
  return t;
};

const sp = (parent, h, fill) => box(parent, "sp", { w:1, h:Math.max(2, h), hs:"fill", vs: fill ? "fill" : "fix" });
const hsp = (parent) => box(parent, "hsp", { dir:"row", w:1, h:2, hs:"fill", vs:"fix" });

// Instance komponen + penimpaan isi lewat nama anak yang stabil.
const taruh = (parent, nama, varian) => {
  const s = KOMP[nama].instance();
  parent.appendChild(s);
  penpotUtils.setParentXY(s, 0, 0);              // <- jebakan nomor enam
  if (varian) { try { s.switchVariant(0, varian); } catch (e) {} }
  return s;
};
const isi = (pert, nama, chars) => {
  const t = penpotUtils.findShapes(s => s.type === "text" && s.name === nama, pert)[0];
  if (t) t.characters = chars;
  return t;
};

// ---- verifikasi: SELALU di panggilan terpisah, karena layout-nya asinkron ----
// Pakai isContainedIn, JANGAN aritmetika boardY. Lewati elemen tersembunyi.
const luar = [];
root.children.filter(c => c.y < 2000).forEach(b => {
  penpotUtils.analyzeDescendants(b, (r, d) => {
    if (d.hidden) return;
    if (!penpotUtils.isContainedIn(d, b)) luar.push(b.name + " / " + d.name);
  });
});
return luar.length ? luar : "ok";
