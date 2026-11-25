import { describe, expect, it } from "vitest";
import { Bep, Runtime } from "@dotbep/core";

describe("@dotbep/core RACI authorization", () => {
  it("enforces role-and-team intersection, responsible priority, explicit email authorization and denial history", async () => {
    const bep = Bep.create({
      name: "Edificación pública piloto",
      code: "PE-RACI-001",
    });

    const rolesResult = bep.roles.add([
      { name: "Coordinador BIM" },
      { name: "Integrante de equipo" },
      { name: "Responsable accountable" },
      { name: "Revisor por correo" },
    ]);
    expect(rolesResult.failed).toEqual([]);
    const roleManagerId = rolesResult.succeeded[0]!.id;
    const roleTeamMemberId = rolesResult.succeeded[1]!.id;
    const roleAccountableId = rolesResult.succeeded[2]!.id;
    const roleEmailId = rolesResult.succeeded[3]!.id;

    const memberEmails = [
      { email: "coordinador@example.invalid", name: "Coordinador autorizado", roleId: roleManagerId },
      { email: "solo-rol@example.invalid", name: "Solo rol", roleId: roleManagerId },
      { email: "solo-equipo@example.invalid", name: "Solo equipo", roleId: roleTeamMemberId },
      { email: "solo-accountable@example.invalid", name: "Solo accountable", roleId: roleAccountableId },
      { email: "revisor-correo@example.invalid", name: "Revisor por correo", roleId: roleEmailId },
    ];
    expect(bep.members.add(memberEmails).failed).toEqual([]);

    const teamResult = bep.teams.add([
      {
        id: "DSN",
        name: "Equipo de diseño",
        isoRole: "appointed-party",
        memberEmails: [
          "coordinador@example.invalid",
          "solo-equipo@example.invalid",
        ],
      },
    ]);
    expect(teamResult.failed).toEqual([]);
    const teamId = teamResult.succeeded[0]!.id;

    const actionResult = bep.actions.add([
      { name: "Revisar entregable BIM" },
    ]);
    expect(actionResult.failed).toEqual([]);
    const actionId = actionResult.succeeded[0]!.id;

    expect(bep.events.add([
      { id: "complete-role-team", name: "Completar revisión del equipo" },
      { id: "complete-email", name: "Completar revisión individual" },
    ]).failed).toEqual([]);

    const workflowResult = bep.workflows.add([
      {
        name: "Autorización RACI",
        description: "Prueba de autorización por rol, equipo y correo.",
        diagram: {
          direction: "LR",
          nodes: {
            start: { type: "start" },
            roleTeamReview: {
              type: "process",
              actionId,
              responsibleRoleIds: [roleManagerId],
              responsibleTeamIds: [teamId],
              accountableRoleIds: [roleAccountableId],
            },
            emailReview: {
              type: "process",
              actionId,
              responsibleEmails: ["revisor-correo@example.invalid"],
            },
            end: { type: "end" },
          },
          edges: {
            startToRoleTeam: { from: "start", to: "roleTeamReview" },
            roleTeamToEmail: {
              from: "roleTeamReview",
              to: "emailReview",
              triggerEventId: "complete-role-team",
            },
            emailToEnd: {
              from: "emailReview",
              to: "end",
              triggerEventId: "complete-email",
            },
          },
        },
      },
    ]);
    expect(workflowResult.failed).toEqual([]);
    const workflowId = workflowResult.succeeded[0]!.id;

    // RACI is deliberately enabled: skipRaci is not passed to init().
    bep.engine.init({ runtime: new Runtime() });

    const instance = await bep.engine.workflows.create(
      workflowId,
      {
        source: "external",
        url: "https://example.invalid/entregables/ARQ-001.ifc",
        label: "Modelo IFC ARQ-001",
      },
      "coordinador@example.invalid",
    );
    expect(instance).not.toBeNull();
    expect(instance!.currentNodeId).toBe("roleTeamReview");

    // A matching role alone is insufficient when a responsible team is also declared.
    const roleOnly = await bep.engine.workflows.emit(instance!.id, {
      eventId: "complete-role-team",
      actor: "solo-rol@example.invalid",
    });
    expect(roleOnly).toMatchObject({ success: false, error: "UNAUTHORIZED" });

    // A matching team alone is insufficient when a responsible role is also declared.
    const teamOnly = await bep.engine.workflows.emit(instance!.id, {
      eventId: "complete-role-team",
      actor: "solo-equipo@example.invalid",
    });
    expect(teamOnly).toMatchObject({ success: false, error: "UNAUTHORIZED" });

    // Accountable is not an alternative authorization path when Responsible exists.
    const accountableOnly = await bep.engine.workflows.emit(instance!.id, {
      eventId: "complete-role-team",
      actor: "solo-accountable@example.invalid",
    });
    expect(accountableOnly).toMatchObject({ success: false, error: "UNAUTHORIZED" });

    const afterDenials = await bep.engine.workflows.get(instance!.id);
    expect(afterDenials?.currentNodeId).toBe("roleTeamReview");
    const deniedActors = afterDenials?.history
      .filter((entry) => entry.type === "transitionDenied")
      .map((entry) => entry.actor);
    expect(deniedActors).toEqual([
      "solo-rol@example.invalid",
      "solo-equipo@example.invalid",
      "solo-accountable@example.invalid",
    ]);

    // This actor satisfies both the responsible role and responsible team.
    const authorized = await bep.engine.workflows.emit(instance!.id, {
      eventId: "complete-role-team",
      actor: "coordinador@example.invalid",
    });
    expect(authorized.success).toBe(true);
    expect(authorized.instance?.currentNodeId).toBe("emailReview");

    // Explicit responsibleEmails authorizes the named member at the next process.
    const emailActor = await bep.engine.workflows.emit(instance!.id, {
      eventId: "complete-email",
      actor: "revisor-correo@example.invalid",
    });
    expect(emailActor.success).toBe(true);
    expect(emailActor.instance?.status).toBe("completed");
    expect(emailActor.instance?.history.some(
      (entry) =>
        entry.type === "transition" &&
        entry.actor === "revisor-correo@example.invalid",
    )).toBe(true);
  });
});
