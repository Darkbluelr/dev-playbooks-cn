# Proposal Debate Workflow

Objective: In the proposal phase, avoid consensus dilution and mechanical metric misdirection through "proposal-challenge-adjudication" triangular confrontation.

Directory Convention (protocol-agnostic):
- Change package: `<change-root>/<change-id>/`
- Proposal: `<change-root>/<change-id>/proposal.md`

Strict Rules:
- Proposal Author / Challenger / Judge must be independent dialogues/independent instances.
- Challenger can only raise objections based on committed `proposal.md` and design materials, no "private co-creation" allowed.
- Judge must provide clear adjudication, no ambiguous compromises allowed.

Workflow:
1) **Proposal Author**: Use `devbooks-proposal-author` Skill to produce `proposal.md` (including Debate Packet).
2) **Proposal Challenger**: Use `devbooks-proposal-challenger` Skill to output Challenge Report.
3) **Proposal Judge**: Use `devbooks-proposal-judge` Skill to output Adjudication Report.
4) **Write Back to Proposal**: Write adjudication conclusion back to `proposal.md`'s Decision Log.
5) **Proceed to Subsequent Artifacts**: Design/Spec/Plan only starts after adjudication is Approved or Revise.

Acceptance Criteria:
- `proposal.md` must contain `Decision Log`, with decision status being `Approved | Revise | Rejected`.
- If `Revise`, must list "Required Modifications" and complete them before re-adjudication.
- Optional automated check: `proposal-debate-check.sh <change-id>` (script located at this Skill's `scripts/proposal-debate-check.sh`)
