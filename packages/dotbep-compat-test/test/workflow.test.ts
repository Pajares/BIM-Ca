import { describe, expect, it } from "vitest";
import {
  Bep,
  Runtime,
  type InstanceStore,
  type WorkflowInstance,
} from "@dotbep/core";

/**
 * Test adapter that models a durable repository by sharing its backing map
 * across adapter instances. It is intentionally not a production database.
 */
class SharedMapStore implements InstanceStore {
  constructor(
    private readonly records: Map<string, WorkflowInstance>,
  ) {}

  async listInstances(): Promise<WorkflowInstance[]> {
    return [...this.records.values()].map((instance) => structuredClone(instance));
  }

  async getInstance(id: string): Promise<WorkflowInstance | null> {
    const instance = this.records.get(id);
    return instance ? structuredClone(instance) : null;
  }

  async saveInstance(instance: WorkflowInstance): Promise<void> {
    this.records.set(instance.id, structuredClone(instance));
  }

  async deleteInstance(id: string): Promise<void> {
    this.records.delete(id);
  }
}

describe("@dotbep/core workflow engine and instance persistence", () => {
  it("creates, transitions, cancels and reloads workflow instances from an InstanceStore", async () => {
    const bep = Bep.create({
      name: "Edificación pública piloto",
      code: "PE-WORKFLOW-001",
    });

    const [{ id: actionId }] = bep.actions.add([
      { name: "Revisar entregable BIM" },
    ]).succeeded;

    bep.events.add([
      {
        id: "submit-review",
        name: "Enviar a revisión",
        payload: [{ key: "comment", type: "string", required: true }],
      },
    ]);

    const [{ id: workflowId }] = bep.workflows.add([
      {
        name: "Revisión de entregable",
        description: "Flujo de prueba para revisión técnica",
        diagram: {
          direction: "LR",
          nodes: {
            start: { type: "start" },
            review: {
              type: "process",
              actionId,
              responsibleRoleIds: [],
            },
            end: { type: "end" },
          },
          edges: {
            startToReview: { from: "start", to: "review" },
            reviewToEnd: {
              from: "review",
              to: "end",
              triggerEventId: "submit-review",
            },
          },
        },
      },
    ]).succeeded;

    const backingRecords = new Map<string, WorkflowInstance>();
    const firstStore = new SharedMapStore(backingRecords);

    // skipRaci is explicitly enabled only for this isolated engine test.
    bep.engine.init({
      runtime: new Runtime(),
      storage: firstStore,
      events: { skipRaci: true },
    });

    const trackedAsset = {
      source: "external" as const,
      url: "https://example.invalid/deliverables/ARQ-001.ifc",
      label: "Modelo IFC ARQ-001",
    };

    const completedInstance = await bep.engine.workflows.create(
      workflowId,
      trackedAsset,
      "coordinador@example.invalid",
    );

    expect(completedInstance).not.toBeNull();
    expect(completedInstance!.status).toBe("active");
    expect((await bep.engine.workflows.getStatus(completedInstance!.id))?.type)
      .toBe("awaitingAction");

    const emitted = await bep.engine.workflows.emit(completedInstance!.id, {
      eventId: "submit-review",
      actor: "revisor@example.invalid",
      payload: { comment: "Revisión técnica completada" },
    });

    expect(emitted.success).toBe(true);
    expect(emitted.instance?.status).toBe("completed");
    expect(emitted.instance?.history.some(
      (entry) => entry.type === "transition" && entry.actor === "revisor@example.invalid",
    )).toBe(true);
    expect(await bep.engine.workflows.resolveContext(completedInstance!.id)).toEqual({
      comment: "Revisión técnica completada",
    });

    const cancelledInstance = await bep.engine.workflows.create(
      workflowId,
      { ...trackedAsset, label: "Modelo IFC ARQ-002" },
      "coordinador@example.invalid",
    );
    expect(cancelledInstance).not.toBeNull();

    await bep.engine.workflows.cancel(
      cancelledInstance!.id,
      "responsable@example.invalid",
    );

    const cancelled = await bep.engine.workflows.get(cancelledInstance!.id);
    expect(cancelled?.status).toBe("cancelled");
    expect(cancelled?.history.some(
      (entry) => entry.type === "cancellation" && entry.actor === "responsable@example.invalid",
    )).toBe(true);

    // Simulate application/engine reinitialization with a new adapter object
    // backed by the same durable repository.
    const reloadedStore = new SharedMapStore(backingRecords);
    bep.engine.init({
      runtime: new Runtime(),
      storage: reloadedStore,
      events: { skipRaci: true },
    });

    const reloadedCompleted = await bep.engine.workflows.get(completedInstance!.id);
    const reloadedCancelled = await bep.engine.workflows.get(cancelledInstance!.id);

    expect(reloadedCompleted?.status).toBe("completed");
    expect(reloadedCompleted?.history).toEqual(emitted.instance?.history);
    expect(reloadedCancelled?.status).toBe("cancelled");
    expect(reloadedCancelled?.history.some(
      (entry) => entry.type === "cancellation" && entry.actor === "responsable@example.invalid",
    )).toBe(true);

    expect((await bep.engine.workflows.list({
      where: [{ field: "status", operator: "eq", value: "completed" }],
    })).map((instance) => instance.id)).toContain(completedInstance!.id);
  });
});
