# Implementation Concerns

## Master Agent Role
- Master agent should **reference** AGENT_PROMPTS.md (extract prompts), not generate new ones from scratch

## One-Shot Execution Risk
- Sub-agents may miss integration points or need iteration
- Ensure DONE.md includes integration details and handoff information

## Quality Gate Enforcement
- Manually validate each gate before proceeding to next agent
- Master agent should verify DONE.md against gates, not just pass through

## Final Integration Validation
- No automated end-to-end testing built in
- Test `make dev` after C&C Part 1 + A&D complete
- Test `make deploy` after C&C Part 2 completes

