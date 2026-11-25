import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { afterEach, describe, expect, it } from "vitest";
import { Bep } from "@dotbep/core";

const temporaryDirectories: string[] = [];

afterEach(async () => {
  await Promise.all(
    temporaryDirectories.splice(0).map((directory) =>
      rm(directory, { recursive: true, force: true })
    )
  );
});

describe("@dotbep/core .bep round-trip", () => {
  it("creates, saves, reopens and preserves project metadata", async () => {
    const directory = await mkdtemp(join(tmpdir(), "dotbep-pe-"));
    temporaryDirectories.push(directory);
    const file = join(directory, "roundtrip.bep");

    const original = Bep.create({
      name: "Edificación pública piloto",
      code: "PE-PILOTO-001",
      description: "Prueba de ida y vuelta",
    });
    // Bep.create() copia solo los campos básicos del proyecto; customData se
    // asigna explícitamente después de crear la instancia para probar el schema.
    original.data.project.customData = {
      country: "PE",
      investmentFramework: "Invierte.pe",
      pilot: true
    };

    await writeFile(file, await original.save());

    const reopened = await Bep.open(await readFile(file));
    expect(reopened.data.project.name).toBe("Edificación pública piloto");
    expect(reopened.data.project.code).toBe("PE-PILOTO-001");
    expect(reopened.data.project.customData).toEqual({
      country: "PE",
      investmentFramework: "Invierte.pe",
      pilot: true
    });

    reopened.data.project.description = "Descripción modificada";
    await writeFile(file, await reopened.save());

    const finalBep = await Bep.open(await readFile(file));
    expect(finalBep.data.project.description).toBe("Descripción modificada");
    expect(finalBep.data.project.customData).toEqual({
      country: "PE",
      investmentFramework: "Invierte.pe",
      pilot: true
    });
  });

  it("preserves a skill resource through save and reopen", async () => {
    const directory = await mkdtemp(join(tmpdir(), "dotbep-pe-resource-"));
    temporaryDirectories.push(directory);
    const file = join(directory, "resource.bep");

    const bep = Bep.create({
      name: "Proyecto de prueba",
      code: "PE-RESOURCE-001"
    });

    const resourceContent = "Recurso auxiliar de compatibilidad";
    await bep.setSkillResource("bep-authoring", "compat-test.txt", resourceContent);
    await writeFile(file, await bep.save());

    const reopened = await Bep.open(await readFile(file));
    await expect(
      reopened.getSkillResource("bep-authoring", "compat-test.txt")
    ).resolves.toBe(resourceContent);
  });
});
