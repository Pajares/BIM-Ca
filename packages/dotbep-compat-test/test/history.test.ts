import { mkdtemp, rm, writeFile, readFile } from "node:fs/promises";
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

describe("@dotbep/core history and versioning", () => {
  it("persists commits, baselines and historical states through .bep round-trip", async () => {
    const directory = await mkdtemp(join(tmpdir(), "dotbep-pe-history-"));
    temporaryDirectories.push(directory);
    const file = join(directory, "history-roundtrip.bep");

    const bep = Bep.create({
      name: "Edificación pública piloto",
      code: "PE-HISTORY-001",
      description: "Estado inicial de la línea base",
    });

    expect(await bep.history.current()).toBe("0.0");
    expect(await bep.history.list()).toEqual([]);

    const initialBaselineText = await bep.readFile("baseline/bep.json");
    expect(initialBaselineText).not.toBeNull();
    expect(JSON.parse(initialBaselineText!).project.description).toBe(
      "Estado inicial de la línea base"
    );

    // Primer cambio consolidado: 0.1
    bep.data.project.description = "Estado consolidado 0.1";
    expect((await bep.history.status()).hasPendingChanges).toBe(true);

    const v01 = await bep.history.commit({
      target: "plan",
      type: "patch",
      author: "qa-dotbep-pe@example.invalid",
      description: "Primera versión de prueba",
    });
    expect(v01?.version).toBe("0.1");

    // Segundo cambio consolidado: 0.2
    bep.data.project.description = "Estado consolidado 0.2";
    const v02 = await bep.history.commit({
      target: "plan",
      type: "patch",
      author: "qa-dotbep-pe@example.invalid",
      description: "Segunda versión de prueba",
    });
    expect(v02?.version).toBe("0.2");
    expect(await bep.history.current()).toBe("0.2");
    expect(await bep.history.hasPendingChanges()).toBe(false);

    const changelogBeforeSave = await bep.readFile("changelog.json");
    expect(changelogBeforeSave).not.toBeNull();
    expect(JSON.parse(changelogBeforeSave!).versions.map((v: { version: string }) => v.version))
      .toEqual(["0.1", "0.2"]);

    expect(await bep.readFile("changelog/v0.1.diff.json")).not.toBeNull();
    expect(await bep.readFile("changelog/v0.2.diff.json")).not.toBeNull();

    await writeFile(file, await bep.save());

    // Reabrir el ZIP debe conservar changelog, baseline y diffs.
    const reopened = await Bep.open(await readFile(file));
    expect(await reopened.history.current()).toBe("0.2");
    expect((await reopened.history.list()).map((version) => version.version))
      .toEqual(["0.1", "0.2"]);
    expect(reopened.data.project.description).toBe("Estado consolidado 0.2");
    expect(await reopened.history.hasPendingChanges()).toBe(false);

    const historicalV01 = await reopened.history.get("0.1");
    const historicalV02 = await reopened.history.get("0.2");
    expect(historicalV01.project.description).toBe("Estado consolidado 0.1");
    expect(historicalV02.project.description).toBe("Estado consolidado 0.2");

    const baselineAfterReopen = await reopened.readFile("baseline/bep.json");
    expect(baselineAfterReopen).not.toBeNull();
    expect(JSON.parse(baselineAfterReopen!).project.description).toBe(
      "Estado consolidado 0.2"
    );

    // Revertir a 0.1 debe crear 0.3, sin borrar 0.2.
    const reverted = await reopened.history.revert("0.1", {
      type: "patch",
      author: "qa-dotbep-pe@example.invalid",
      description: "Reversión de prueba hacia el estado 0.1",
    });

    expect(reverted.version).toBe("0.3");
    expect(await reopened.history.current()).toBe("0.3");
    expect(reopened.data.project.description).toBe("Estado consolidado 0.1");
    expect((await reopened.history.list()).map((version) => version.version))
      .toEqual(["0.1", "0.2", "0.3"]);

    // El estado anterior sigue siendo reconstruible tras el revert.
    expect((await reopened.history.get("0.2")).project.description).toBe(
      "Estado consolidado 0.2"
    );
    expect((await reopened.history.get("0.3")).project.description).toBe(
      "Estado consolidado 0.1"
    );

    await writeFile(file, await reopened.save());
    const finalBep = await Bep.open(await readFile(file));
    expect(await finalBep.history.current()).toBe("0.3");
    expect((await finalBep.history.list()).map((version) => version.version))
      .toEqual(["0.1", "0.2", "0.3"]);
    expect(finalBep.data.project.description).toBe("Estado consolidado 0.1");
    expect(await finalBep.history.hasPendingChanges()).toBe(false);
  });
});
