---
description: Run 7 parallel failure mode analyses and produce a synthesis report
version: 2.0 — file-based context offloading (2025-02-13)
---

You are a senior reliability and security engineer orchestrating a comprehensive failure mode analysis. Your goal is to analyze a system using 7 independent engineering methods in parallel, then synthesize the results into individual reports and a unified cross-method synthesis.

**CRITICAL ARCHITECTURE NOTE:** This workflow is designed to avoid context window exhaustion. Each analysis agent writes its full report directly to disk and returns only a short summary. The synthesis is performed by a dedicated agent with a fresh context window that reads the report files from disk. The orchestrator (you) never holds the full analysis content — only short summaries.

## Input

The user may provide:

1. A specific component or subsystem to analyze (e.g., "llm-gateway", "scan pipeline")
2. A scope description (e.g., "focus on the LLM data path")
3. Nothing — in which case, analyze the full system described in CLAUDE.md

Use the user's input to scope the analysis: $ARGUMENTS

## Process Overview

### Phase 1: Understand the System and Prepare Shared Context

Before launching sub-agents, explore the codebase to understand the system under analysis:

1. Read CLAUDE.md to understand the overall architecture
2. Identify the key components, data flows, and trust boundaries relevant to the scope
3. Read key source files to understand implementation details (not just documentation)
4. Build a mental model of: components, data flows, trust boundaries, security controls, external dependencies

**Write the shared context file** to `docs/failure-analysis/_system-context.md` containing:

1. A system description (10-15 lines)
2. A list of key file paths to read (the source files you identified as important)
3. The analysis scope

This file will be read by every sub-agent instead of passing the context inline.

Also create the output directory: `docs/failure-analysis/`

### Phase 2: Launch 7 Parallel Analysis Agents (File-Writing)

Launch **all 7 agents in parallel** using the Task tool with `subagent_type: "general-purpose"` and `model: "opus"`. Each agent must:

1. Read the shared context from `docs/failure-analysis/_system-context.md`
2. Read the source files listed in that context file
3. Perform its method-specific analysis
4. **Write its full report to its designated output file** using the Write tool
5. **Return only a short summary** (max 15 lines): method name, 3-5 key findings, top 3 recommendations, and any caveats

**CRITICAL:** Launch all 7 in a single message with 7 parallel Task tool calls. Do not wait for one to finish before launching the next.

**CRITICAL:** Each agent prompt must include these exact instructions about output:

```
OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to {output_file} using the Write tool.
   The report must include: method name, date, scope, complete findings, all tables/data, and recommendations.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.
```

#### Agent 1: FMEA (Failure Mode and Effects Analysis)

Output file: `docs/failure-analysis/fmea.md`

```
Perform a Failure Mode and Effects Analysis (FMEA) on the system described in docs/failure-analysis/_system-context.md.

Read that file FIRST to get the system description and list of key source files, then read those source files.

INSTRUCTIONS:
You are performing a bottom-up, component-level failure analysis. For each component in the system:

1. Define severity, occurrence, and detection scales (1-10) tailored to this system's domain
2. For each component, identify failure modes, their effects, causes, and current controls
3. Calculate Risk Priority Numbers: RPN = Severity x Occurrence x Detection
4. Identify cross-stage failure propagation paths
5. Map each entry to observable metrics (Prometheus queries, log patterns, etc.)

REPORT FORMAT (write to docs/failure-analysis/fmea.md):
- Title: "# FMEA — Failure Mode and Effects Analysis"
- Date and scope
- Severity/Occurrence/Detection scale definitions (tables)
- FMEA worksheet with columns: Component, Failure Mode, Effect, Cause, Current Controls, S, O, D, RPN, Recommended Action
- Cross-stage propagation matrix
- Ranked list by RPN (highest first)
- Top 5 recommendations

OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to docs/failure-analysis/fmea.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.

Read the actual source code. Ground every failure mode in specific code paths, not abstract possibilities.
```

#### Agent 2: FTA (Fault Tree Analysis)

Output file: `docs/failure-analysis/fta.md`

```
Perform a Fault Tree Analysis (FTA) on the system described in docs/failure-analysis/_system-context.md.

Read that file FIRST to get the system description and list of key source files, then read those source files.

INSTRUCTIONS:
You are performing a top-down deductive analysis starting from catastrophic end states.

1. Define 3-5 top events (undesired system-level outcomes)
2. For each top event, build a fault tree using AND/OR gates decomposing into basic events
3. Identify minimal cut sets (smallest combinations of basic events causing the top event)
4. Assign probability estimates to basic events based on code analysis
5. Calculate top event probabilities using Boolean algebra
6. Identify common cause failures (single root causes appearing in multiple branches)
7. Compute Fussell-Vesely importance for each basic event

REPORT FORMAT (write to docs/failure-analysis/fta.md):
- Title: "# FTA — Fault Tree Analysis"
- Date and scope
- Top event definitions with rationale
- Fault tree structure (text-based, using indentation for AND/OR gates)
- Minimal cut sets per top event (list of sets)
- Probability assignments with justification
- Top event probability calculations
- Common cause failures
- Importance rankings
- Top 5 recommendations

OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to docs/failure-analysis/fta.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.

Read the actual source code. Every basic event must reference specific code, config, or infrastructure.
```

#### Agent 3: ETA (Event Tree Analysis)

Output file: `docs/failure-analysis/eta.md`

```
Perform an Event Tree Analysis (ETA) on the system described in docs/failure-analysis/_system-context.md.

Read that file FIRST to get the system description and list of key source files, then read those source files.

INSTRUCTIONS:
You are performing a forward-looking barrier analysis from initiating events through security controls to end states.

1. Define 4-6 initiating events (triggers that start a scenario)
2. Inventory all barriers/controls in the system (preventive, detective, mitigative)
3. For each initiating event, trace the path through sequential barriers
4. Assign barrier effectiveness probabilities based on code analysis
5. Calculate end-state probabilities for each path
6. Categorize end states by consequence severity
7. Analyze parallel/redundant barrier configurations
8. Model dynamic barrier effectiveness (how barriers degrade over time)

REPORT FORMAT (write to docs/failure-analysis/eta.md):
- Title: "# ETA — Event Tree Analysis"
- Date and scope
- Initiating events with frequency estimates
- Barrier inventory (table: barrier, type, stage, effectiveness)
- Event trees (text-based branching diagrams)
- End-state probability calculations
- Critical end states ranked by risk (probability x consequence)
- Barrier redundancy analysis
- Top 5 recommendations

OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to docs/failure-analysis/eta.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.

Read the actual source code. Barrier effectiveness must be justified by implementation details.
```

#### Agent 4: STPA (Systems-Theoretic Process Analysis)

Output file: `docs/failure-analysis/stpa.md`

```
Perform a Systems-Theoretic Process Analysis (STPA) with STPA-Sec extensions on the system described in docs/failure-analysis/_system-context.md.

Read that file FIRST to get the system description and list of key source files, then read those source files.

INSTRUCTIONS:
You are performing a control-theoretic analysis focused on unsafe control actions and inadequate feedback.

1. Define system-level losses (L-1 through L-N)
2. Define system-level hazards that lead to losses (H-1 through H-N)
3. Map the control structure: controllers, controlled processes, control actions, feedback
4. For each control action, identify Unsafe Control Actions (UCAs) in 4 categories:
   a. Not provided (when needed)
   b. Provided (when not needed)
   c. Wrong timing/order
   d. Stopped too soon/applied too long
5. For each critical UCA, develop loss scenarios (causal factors)
6. Apply STPA-Sec: identify adversarial scenarios where an attacker deliberately causes UCAs
7. Analyze feedback loops: where is feedback missing, delayed, or inadequate?
8. Derive safety/security constraints from UCAs

REPORT FORMAT (write to docs/failure-analysis/stpa.md):
- Title: "# STPA — Systems-Theoretic Process Analysis"
- Date and scope
- System-level losses table
- System-level hazards table (linked to losses)
- Control structure diagram (text-based)
- UCA table (controller, control action, UCA type, UCA description, hazard)
- 3-5 detailed loss scenarios
- STPA-Sec adversarial scenarios
- Feedback gap analysis
- Safety/security constraints
- Top 5 recommendations

OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to docs/failure-analysis/stpa.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.

Read the actual source code. UCAs must reference specific controller code and control action implementations.
```

#### Agent 5: Markov / Semi-Markov Analysis

Output file: `docs/failure-analysis/markov.md`

```
Perform a Markov and Semi-Markov availability analysis on the system described in docs/failure-analysis/_system-context.md.

Read that file FIRST to get the system description and list of key source files, then read those source files.

INSTRUCTIONS:
You are performing a stochastic state-based reliability and availability analysis.

1. Model 3-4 key component archetypes as Continuous-Time Markov Chains (CTMCs):
   - Long-running services (states: Healthy, Degraded, Rate-Limited, Failover, Down, Recovering)
   - Short-lived jobs (absorbing chain: Pending -> Running -> Succeeded/Failed/Timed-Out)
   - Infrastructure services (states: Healthy, Degraded, Cache-Only, Down)
2. Define transition rate matrices with rates estimated from code (timeouts, retry intervals, TTLs)
3. Compose component models into a system model (address state space explosion)
4. Calculate steady-state availability: P(system operational)
5. Perform sensitivity analysis: Birnbaum importance of each component's failure rate
6. Identify where the memoryless assumption breaks (Semi-Markov needed)
7. Model Semi-Markov extensions for deterministic timeouts, TTL expiry, backoff schedules
8. Provide capacity planning analysis: cost-availability tradeoffs for scaling actions

REPORT FORMAT (write to docs/failure-analysis/markov.md):
- Title: "# Markov / Semi-Markov Availability Analysis"
- Date and scope
- Component state-transition diagrams (text-based)
- Transition rate matrices with rate justifications
- Composed system model approach
- Availability metrics (point estimates)
- Sensitivity analysis (ranked Birnbaum importance)
- Structural single points of failure
- Semi-Markov extensions (which transitions, what distributions)
- Capacity planning table (scaling action, cost, availability gain)
- What-if scenarios
- Prometheus queries for rate estimation
- Top 5 recommendations

OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to docs/failure-analysis/markov.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.

Read the actual source code. Transition rates must be derived from actual timeouts, retry configs, and TTLs in the code.
```

#### Agent 6: Petri Net / Colored Petri Net Analysis

Output file: `docs/failure-analysis/petri-net.md`

```
Perform a Petri Net analysis with Colored Petri Net extensions on the system described in docs/failure-analysis/_system-context.md.

Read that file FIRST to get the system description and list of key source files, then read those source files.

INSTRUCTIONS:
You are performing a formal concurrency and resource contention analysis.

1. Model the full pipeline as a Petri Net: places (states), transitions (events), arcs (flow)
2. Model all shared resources as resource places with capacity bounds
3. Extend to Colored Petri Net (CPN) for heterogeneous workloads (different job types, providers, modes)
4. Analyze for deadlocks: can the system reach a state where no transition can fire?
5. Prove liveness: does every scan eventually terminate?
6. Prove boundedness: are all places bounded (no unbounded accumulation)?
7. Identify bottlenecks: which resource places have the highest utilization?
8. Add timed extensions: model transition firing times (deterministic, exponential, etc.)
9. Identify key invariants the net preserves

REPORT FORMAT (write to docs/failure-analysis/petri-net.md):
- Title: "# Petri Net / Colored Petri Net Analysis"
- Date and scope
- Resource model table (resource, capacity, acquired at, released at)
- Full pipeline token flow (places, transitions, arcs)
- CPN color set definitions
- Deadlock analysis (scenarios examined, resolution mechanisms)
- Liveness proof sketch
- Boundedness analysis per place
- Bottleneck ranking
- Timed extensions table (transition, distribution, parameters)
- Key invariants
- Tool recommendations for formal verification
- Top 5 recommendations

OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to docs/failure-analysis/petri-net.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.

Read the actual source code. Resource capacities must come from actual K8s limits, rate configs, and code constants.
```

#### Agent 7: HAZOP (Hazard and Operability Study)

Output file: `docs/failure-analysis/hazop.md`

```
Perform a HAZOP analysis with security-adapted guide words on the system described in docs/failure-analysis/_system-context.md.

Read that file FIRST to get the system description and list of key source files, then read those source files.

INSTRUCTIONS:
You are performing a systematic deviation analysis using guide words applied to study nodes.

1. Define 5-7 study nodes (pipeline stages or functional units) with design intent
2. Define security-adapted guide words beyond traditional HAZOP (SPOOFED, INJECTED, REPLAYED, ESCALATED, EXFILTRATED, TAMPERED, BYPASSED, EXHAUSTED, PERSISTED, ENUMERATED)
3. For each study node, apply guide words systematically to generate deviations
4. For the 3 highest-risk study nodes, produce detailed worksheets with:
   - Guide word, deviation, possible causes, consequences, safeguards, risk score (P x C), recommended actions
5. Build an interaction matrix showing how deviations in one node affect others
6. Identify critical interaction scenarios (cascading failures across nodes)
7. Define HAZOP team composition and estimated effort for a real study
8. Define trigger criteria for re-studying (when to re-run HAZOP)

REPORT FORMAT (write to docs/failure-analysis/hazop.md):
- Title: "# HAZOP — Hazard and Operability Study"
- Date and scope
- Study node definitions (table: ID, node, design intent)
- Security guide word definitions (table: guide word, definition, example)
- Detailed worksheets for top 3 nodes (table format)
- Interaction matrix (NxN)
- Critical interaction scenarios (3-5 narratives)
- Prioritized risk scores across all worksheets
- Team composition and effort estimate
- Living HAZOP maintenance triggers
- Top 5 recommendations

OUTPUT INSTRUCTIONS:
1. Write your FULL analysis report to docs/failure-analysis/hazop.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 15 lines) containing:
   - Method name
   - 3-5 key findings (one line each)
   - Top 3 recommendations (one line each)
   - Any caveats or limitations
   DO NOT return the full report content — it is already saved to disk.

Read the actual source code. Deviations must reference specific implementation details, not generic patterns.
```

### Phase 3: Collect Summaries and Launch Synthesis Agent

After all 7 agents complete, you will have:
- 7 short summaries in your context (max ~105 lines total)
- 7 full report files on disk

**Do NOT read the full report files.** Instead, launch a **synthesis agent** with a fresh context window.

Launch a single Task tool call with `subagent_type: "general-purpose"` and `model: "opus"`:

```
You are a senior reliability engineer performing a cross-method synthesis of 7 independent failure mode analyses.

Read ALL of the following report files:
- docs/failure-analysis/fmea.md
- docs/failure-analysis/fta.md
- docs/failure-analysis/eta.md
- docs/failure-analysis/stpa.md
- docs/failure-analysis/markov.md
- docs/failure-analysis/petri-net.md
- docs/failure-analysis/hazop.md

Also read the system context: docs/failure-analysis/_system-context.md

Then write a synthesis report to docs/failure-analysis/synthesis-report.md with this structure:

1. **Executive Summary** — Key statistics, top 5 critical findings
2. **Methodology** — Brief description of each method and why it was chosen
3. **System Under Analysis** — Architecture diagram (text), scope, components
4. **Critical Findings** — Issues found by 3+ methods (highest confidence)
5. **Cross-Method Convergence Analysis** — Matrix showing which methods found which issues
6. **Detailed Findings by Theme** — Group findings by topic (DLP, identity, monitoring, etc.)
7. **Quantitative Risk Assessment** — FMEA RPNs, FTA probabilities, ETA end-states, Markov availability, HAZOP risk scores
8. **Prioritized Recommendations** — Unified, deduplicated, ranked by cross-method agreement and risk
9. **Method Comparison** — Which methods were most useful for which aspects
10. **Implementation Roadmap** — Phased plan for addressing findings

CROSS-METHOD CONVERGENCE RULES:
- 3+ methods agree -> Mark as "High Confidence" finding
- 2 methods agree -> Mark as "Medium Confidence"
- 1 method only -> Mark as "Method-Specific" (still valuable, but less validated)
- Methods disagree -> Note the disagreement and explain why perspectives differ

QUALITY CHECKS (verify before writing):
1. Every recommendation must trace back to at least one method's finding
2. Every "High Confidence" finding must cite which methods identified it
3. Quantitative values (probabilities, RPNs, availability) must cite which method produced them
4. No recommendation should be purely generic — each must reference specific code, config, or architecture

OUTPUT INSTRUCTIONS:
1. Write the FULL synthesis report to docs/failure-analysis/synthesis-report.md using the Write tool.
2. After writing the file, return ONLY a short summary (max 20 lines) containing:
   - Number of High/Medium/Method-Specific findings
   - Top 5 critical findings (one line each)
   - Top 5 recommendations (one line each)
   - Any methods that produced weak or missing results
   DO NOT return the full synthesis — it is already saved to disk.
```

### Phase 4: Report Completion

After the synthesis agent completes, present to the user:

1. The 7 short summaries from Phase 2 (already in your context)
2. The synthesis summary from Phase 3
3. The file paths for all generated reports:
   - `docs/failure-analysis/_system-context.md`
   - `docs/failure-analysis/fmea.md`
   - `docs/failure-analysis/fta.md`
   - `docs/failure-analysis/eta.md`
   - `docs/failure-analysis/stpa.md`
   - `docs/failure-analysis/markov.md`
   - `docs/failure-analysis/petri-net.md`
   - `docs/failure-analysis/hazop.md`
   - `docs/failure-analysis/synthesis-report.md`

If any agent failed, note which ones and suggest re-running them individually.

## Context Window Budget

This design keeps the orchestrator's context usage minimal:

| Phase | Context consumed |
|-------|-----------------|
| Phase 1: System exploration | ~moderate (codebase reads) |
| Phase 2: 7 agent summaries | ~105 lines (15 lines x 7) |
| Phase 3: Synthesis summary | ~20 lines |
| Phase 4: Final report | ~10 lines |
| **Total agent results in context** | **~135 lines** |

Compare to the old design where all 7 full reports (~thousands of lines) were held in the orchestrator context.

## Notes

- This command is compute-intensive: 7 opus agents + 1 synthesis agent running sequentially
- Total analysis time: typically 5-15 minutes depending on codebase size
- The individual method reports preserve full detail; the synthesis provides the cross-method view
- If a specific agent fails or produces low-quality output, note this in the Phase 4 report rather than blocking
- All intermediate data lives on disk in `docs/failure-analysis/` — the orchestrator context stays lean
