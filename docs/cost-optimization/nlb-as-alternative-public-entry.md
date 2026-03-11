# NLB as an Alternative Public Entry

## Purpose

This document records why the repository now treats **NLB** as an alternative public entry pattern for some AWS-based AI infrastructure scenarios.

The goal is not to claim that NLB should replace every existing ALB-based design. Instead, the goal is to document a simpler, practically validated variant that became useful during repository iteration.

## Context

The repository originally leaned more toward an ALB-oriented public entry model.

That remained reasonable because ALB fits well with many Kubernetes ingress-oriented workflows, especially when the architecture benefits from HTTP-aware routing and richer Layer 7 behavior.

However, later testing showed that an NLB-based public entry path could also work well for the current scenario. In that tested path:

- the backend service was reachable from the public internet
- the vLLM service was running normally
- the overall entry pattern became simpler in some practical respects

This made NLB worth documenting as a repository-level variant.

## Why document NLB separately

It is helpful to document NLB as its own variant because it represents a different architectural preference.

In this repository, the NLB option is mainly relevant when the user wants:

- a simpler public entry model
- fewer application-layer assumptions at the entry point
- a more direct service exposure path
- a documented alternative for comparing architecture and operational trade-offs

This makes NLB valuable as a blueprint option, even if ALB remains the more feature-rich choice in many application-facing scenarios.

## What this document does not claim

This document does **not** claim that:

- NLB is always cheaper in every real deployment
- NLB is always simpler in every Kubernetes setup
- ALB should be removed from the repository
- one successful test automatically defines a universal best practice

Those conclusions would be too strong for the current validation level.

Instead, the correct repository position is more limited and more useful:

- NLB has been practically validated in this context
- NLB is worth documenting as an alternative path
- the repository should keep both ALB and NLB patterns available

## Why NLB can be a good fit here

For the kind of blueprint being explored in this repository, NLB can be attractive because it may help reduce unnecessary architectural layering in some service exposure scenarios.

That can be useful when the service entry requirement is relatively direct and does not clearly need richer Layer 7 ingress features.

At a repository level, this may improve:

- architectural clarity
- operational simplicity
- reproducibility of the tested path
- documentation quality when describing a more direct exposure model

Again, this should be understood as a scenario-based fit, not a universal rule.

## Relationship with the ALB path

The repository should present the ALB and NLB paths as **parallel variants**, not as "old versus new" or "wrong versus right".

A healthy documentation model is:

- ALB remains a primary and valid reference pattern
- NLB is added as an alternative public entry option
- the repository explains where each path may be more suitable
- future iterations can strengthen or weaken recommendations based on additional validation

This is more useful than forcing a single architecture answer too early.

## Documentation principle

When adding NLB to the repository, the key principle is:

**add a new documented variant instead of rewriting the entire previous story**

That means:

- preserve earlier ALB-based documentation where it is still valid
- document NLB as a sibling option
- describe trade-offs carefully
- avoid absolute statements that go beyond what has actually been tested

This keeps the blueprint repository realistic and easier to evolve.

## Practical repository value

Documenting NLB as an alternative public entry path adds value to the repository in several ways.

First, it shows that the repository is not locked into one ingress pattern.

Second, it makes the repository more useful for readers who want to compare service exposure approaches.

Third, it preserves practical engineering history: the repository now reflects that an additional path was tested and reached an initially usable state.

That is often more valuable than presenting a falsely simplified architecture story.

## Suggested cross-references

This document works best when linked together with:

- `README.md`
- `docs/cost-optimization/aws-load-balancing-cost-optimization.md`
- any future blueprint-specific notes describing the exact NLB implementation path

## Conclusion

The repository should currently present NLB like this:

- not as a total replacement for ALB
- not as a universal best practice
- but as a practically validated alternative public entry path

That positioning is accurate, technically honest, and useful for future repository iteration.
