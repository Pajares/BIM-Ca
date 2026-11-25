import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { Bep } from "@dotbep/core";

const outputDir = resolve("artifacts");
const outputFile = resolve(outputDir, "dotbep-compat-demo.bep");

await mkdir(outputDir, { recursive: true });

const bep = Bep.create({
  name: "Proyecto piloto de edificación pública",
  code: "PILOTO-PE",
  description: "Paquete de prueba de compatibilidad dotBEP-PE"
});
// Bep.create() no transfiere customData; se agrega explícitamente a la instancia.
bep.data.project.customData = {
  country: "PE",
  investmentFramework: "Invierte.pe",
  compatibilityPrototype: true
};

await bep.setSkillResource(
  "bep-authoring",
  "dotbep-pe-test.txt",
  "Recurso adicional de prueba dotBEP-PE."
);

await writeFile(outputFile, await bep.save());
console.log(`Paquete generado: ${outputFile}`);
