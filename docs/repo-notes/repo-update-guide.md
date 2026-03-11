# Repository Update Guide

## Purpose

This note records how the current repository update should be handled.

The goal is to keep the repository technically honest, easy to iterate, and consistent with the actual validation status of the documented blueprints.

This guide is mainly for repository maintenance, not for end-user-facing architecture explanation.

## Current update context

The repository originally contained an ALB-oriented public entry story for AWS-based AI infrastructure experiments.

Later, an NLB-based public entry path also reached an initially usable state during testing. In that stage:

- the backend vLLM service was running
- public access was verified
- the overall entry pattern became simpler in some scenarios

Because of that, the repository now needs a clearer structure for documenting both variants.

## Main editing decision

The main editing decision for this iteration is:

**do not overwrite the old architecture story just because a new variant also works**

Instead:

- keep the ALB-related material where it is still valid
- add NLB as a documented alternative
- explain the trade-offs in separate documents
- update the root README so readers can understand the relationship between both paths

This repository should evolve by **expanding documented variants**, not by repeatedly rewriting history.

## Editing principles

### 1. Prefer split over replacement

When a new architecture path becomes usable, prefer adding it as a new documented variant.

Do not remove older material unless:

- it is clearly incorrect
- it is dangerously misleading
- it no longer matches the repository scope at all

A repository like this becomes more useful when it shows multiple realistic infrastructure patterns.

### 2. Keep wording tied to actual validation

Documentation should match what was actually verified.

Use wording such as:

- initially validated
- practical alternative
- tested in the current scenario
- documented variant

Avoid wording such as:

- definitive best practice
- universally recommended
- always simpler
- should fully replace the previous path

Those stronger conclusions require more evidence than the repository currently has.

### 3. Avoid absolute statements

Be careful with statements about infrastructure components, controllers, or service exposure patterns.

If a conclusion depends on a specific implementation path, the documentation should say so.

Do not generalize one successful setup into a universal rule unless the scope has been clearly validated.

### 4. Preserve architecture history where useful

Older repository content still has value when it represents a valid architecture path.

The goal of iteration is not to hide earlier decisions, but to improve repository clarity by showing how the architecture options evolved.

This is especially important for blueprint-style repositories.

## Recommended repository changes

### Root README

Update the root `README.md` to make the following points clear:

- ALB remains a valid primary reference path
- NLB is now documented as an alternative public entry variant
- the repository keeps both patterns intentionally
- detailed trade-off notes live under `docs/`

A small dedicated section is usually enough.

### Cost optimization notes

Keep cost and trade-off commentary under:

```text
docs/cost-optimization/
```

Recommended files:

```text
docs/cost-optimization/aws-load-balancing-cost-optimization.md
docs/cost-optimization/nlb-as-alternative-public-entry.md
```

### Repo maintenance notes

Keep internal maintenance logic and update rules under:

```text
docs/repo-notes/
```

This helps separate reader-facing architecture documents from maintainer-facing editing notes.

### Writing style guidance

For this repository, the writing style should stay:

- technical

- calm

- evidence-based

- natural

- not over-marketing

- not overstating production readiness

Good repository documentation should sound like engineering notes, not product promotion.

A useful tone is:

- clear about what works

- honest about what is still limited

- careful about recommendation strength

- structured enough for future iteration

### What this iteration should communicate

After this update, the repository should communicate the following:

1. the ALB path is still valid

2. the NLB path is now worth documenting

3. both paths are intentionally kept

4. the repository values trade-off clarity over forced simplification

5. future iterations may refine the recommendation as more validation is completed

If those five points are clear, this update is doing its job.

### Suggested commit style

This update is best committed as a documentation-focused change.

Example commit messages:
```text
docs: add ALB vs NLB load balancing notes for ai-infra blueprints
docs: document NLB as an alternative public entry variant
docs: reorganize load balancing guidance without replacing ALB path
```

### Practical maintenance rule

When similar architecture variations appear in the future, use the same decision model:

- if the new path is only an experiment, keep it out of the main story

- if the new path becomes usable and repeatable, document it as a variant

- if the new path clearly supersedes an old one with enough evidence, then strengthen the recommendation gradually

- do not jump from "tested once" to "final recommended standard"

This keeps the repository stable and credible over time.

### Conclusion

The purpose of this update is not to declare a final winner between ALB and NLB.

The purpose is to improve repository quality by:

- preserving valid existing material

- adding a newly validated alternative

- documenting trade-offs more clearly

- keeping the wording aligned with real evidence

That is the right approach for an evolving infrastructure blueprint repository.
