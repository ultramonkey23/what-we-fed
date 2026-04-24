# WORKFLOW: HANDOFF COMPILER (v1.0 "The Execution Packet")

## Purpose
The Handoff Compiler is a **BRAIN (Director)** protocol that formalizes task delegation. It converts abstract intent into a rigid, deterministic **Execution Packet**, ensuring zero fidelity loss when moving between agents or tools (e.g., BRAIN -> ALFRED).

## 1. THE EXECUTION PACKET
Modern agent architecture requires strongly-typed handoffs. A "compiled" handoff is not prose; it is a structured packet defining constraints and invariants.

## 2. COMPILATION SCHEMA
Every compiled handoff must include:

```md
### Compiled Execution Packet [ID]
- **Lead Agent**: [ALFRED | SYMBIOTE | CYBORG | INSPECTOR]
- **Target Files**: [Specific Paths]
- **Mutation Budget**: [Low | Medium | High] (Strict limit on allowed changes)
- **Blast Radius**: [Tier 0 | 1 | 2 | 3]
- **Invariants**: [What MUST NOT change (e.g., Timing Truth)]
- **Acceptance Criteria**: [Deterministic pass/fail conditions]
- **Validation Requirement**: [smoke_project.bat | validate_data.bat | etc.]
```

## 3. MUTATION BUDGET LAW
- **Low**: Surgical fix only. No logic changes outside the target line/function.
- **Medium**: Local logic restructuring allowed within the target file.
- **High**: Cross-file systemic changes permitted under strict BRAIN supervision.

## 4. PROTOCOL
1. **BRAIN** decides the Best-Next-Move.
2. **BRAIN** runs the Handoff Compiler protocol to generate the packet.
3. **Target Agent** (e.g., ALFRED) reads the packet as their **Primary Command**.
4. If the target agent cannot fulfill the task within the **Mutation Budget**, they must return the packet to BRAIN for re-compilation.

## Output Contract
The Handoff Compiler is a formatting protocol. The resulting Execution Packet is the primary artifact.
