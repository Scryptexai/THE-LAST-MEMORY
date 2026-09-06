// Analisis statis GDScript (Godot 4.x) tanpa editor: parse + tipe + identifier
// tak terdefinisi + akses anggota kelas engine. Butuh: npm i @gdscript-analyzer/core
// Pakai: node tools/analyze_gd.mjs [--strict]   (dari root repo; keluar 1 bila ada error)
import fs from "fs";
import path from "path";
import { createRequire } from "module";

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname), "..");
let AnalysisHandle;
try {
	({ AnalysisHandle } = createRequire(import.meta.url)("@gdscript-analyzer/core"));
} catch (e) {
	console.log("(analyze_gd: @gdscript-analyzer/core tidak terpasang — lewati; npm i @gdscript-analyzer/core)");
	process.exit(0);
}
const strict = process.argv.includes("--strict");
const az = new AnalysisHandle();
az.setProjectConfig(fs.readFileSync(path.join(ROOT, "project.godot"), "utf8"));
const files = [];
(function walk(d) {
	for (const f of fs.readdirSync(d)) {
		const p = path.join(d, f);
		if (fs.statSync(p).isDirectory()) walk(p);
		else if (p.endsWith(".gd")) files.push(p);
	}
})(path.join(ROOT, "scripts"));
for (const f of files) {
	az.openDocument("file://" + f, fs.readFileSync(f, "utf8"), "res://" + path.relative(ROOT, f));
}
az.setWorkspaceComplete(true);
az.setWarningOverride(strict ? "strict" : "engine-defaults");
// Peringatan yang tidak dianggap masalah (sesuai gaya proyek).
const IGNORE = new Set(["UNUSED_SIGNAL", "INTEGER_DIVISION"]);
// Akses dinamis lewat Node bertipe umum (autoload/duck typing) memang disengaja.
const SOFT = /inferred type "(Node|Node3D|Control)"/;
let errors = 0, warns = 0;
for (const f of files) {
	const src = fs.readFileSync(f, "utf8");
	const rel = path.relative(ROOT, f);
	// Parse error ditandai node ERROR di pohon sintaks.
	const tree = az.syntaxTree("file://" + f) || "";
	const parseErrs = (tree.match(/\bERROR@/g) || []).length;
	if (parseErrs) { console.log(`${rel}: ${parseErrs} PARSE ERROR`); errors += parseErrs; }
	for (const d of az.diagnostics("file://" + f)) {
		if (IGNORE.has(d.code)) continue;
		if (d.severity !== "error" && SOFT.test(d.message)) continue;
		const line = src.slice(0, d.range.start).split("\n").length;
		if (d.severity === "error") errors++; else warns++;
		if (d.severity === "error" || strict) console.log(`${rel}:${line} [${d.severity}] ${d.code}: ${d.message}`);
	}
}
console.log(`GDSCRIPT ANALYZE: ${files.length} files, ${errors} error, ${warns} warning`);
process.exit(errors ? 1 : 0);
