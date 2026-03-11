# AWS Load Balancing Cost Optimization

## Purpose

This document records a practical repository-level cost optimization direction explored during the iteration of AWS-based AI infrastructure blueprints.

The focus is not to claim that one load balancing pattern is always better than another, but to document why the repository now keeps both **ALB** and **NLB** as valid public entry variants.

In this repository, cost optimization should be understood as a balance of:

- cloud cost
- operational simplicity
- architectural clarity
- fit for the actual service exposure pattern

## Background

During earlier iterations, the repository mainly followed an ALB-oriented public entry pattern for Kubernetes-based workloads.

That path remains valid and continues to be useful for many application-facing deployments, especially where Layer 7 routing behavior, HTTP-aware ingress handling, and common Kubernetes ingress workflows are desirable.

However, during later testing and refinement, an NLB-based variant was also brought into a usable state. At that stage:

- the backend vLLM service was running normally
- public access to the service was verified
- the overall public entry path became simpler in some scenarios

This created a new repository question:

Should the original ALB-based approach be replaced, or should the repository keep both paths and document them more clearly?

The more accurate answer for this repository is to **keep both paths**.

## Why this is treated as cost optimization

In practice, "cost optimization" here is broader than just comparing line-item pricing.

For infrastructure blueprints, cost optimization often includes reducing unnecessary architectural layers, avoiding avoidable operational complexity, and keeping the public entry path aligned with the real protocol and exposure requirements of the workload.

That means the optimization discussion may include:

- whether a Layer 7 entry point is actually needed
- whether the service exposure model is simpler with a lower-layer entry path
- whether the operational model becomes easier to reason about
- whether the architecture remains easy to document and reproduce

In other words, repository-level cost optimization is partly about cloud spend, and partly about not carrying complexity that does not create enough value.

## ALB path: why it still matters

The ALB-based path should remain in the repository as an important reference architecture.

It is still a strong fit when the blueprint benefits from:

- HTTP or HTTPS-aware routing
- ingress-style application exposure
- future expansion toward path-based or host-based routing
- alignment with common Kubernetes ingress conventions
- application-centric traffic management patterns

For many teams, this remains the more familiar and extensible approach.

Because of that, the repository should not frame ALB as a "wrong" design just because an NLB variant was later validated.

## NLB path: why it was added

The NLB-based path is included because it became a practical alternative in real testing.

At the current stage, it is useful to document NLB as an option when the goal is closer to:

- a simpler public entry pattern
- a more direct service exposure model
- fewer unnecessary Layer 7 assumptions
- a cleaner variant for certain AI inference access patterns

This does not automatically make NLB universally better.

Instead, it means the repository now has enough evidence to treat NLB as a legitimate documented variant rather than an unstructured experiment.

## Repository decision: split, do not overwrite

The key repository decision is:

**use a split-and-document strategy, not a replace-and-overwrite strategy**

That means:

- the ALB path remains documented
- the NLB path is added as an alternative
- old content is not removed only because a new path also works
- wording should reflect validation status honestly
- the repository should preserve architecture history where it is still technically meaningful

This is especially important for a blueprint repository.

A blueprint repository is more useful when it shows multiple realistic patterns and explains when each one makes sense, instead of pretending there is always a single final answer.

## On controller-related wording

One important editing principle from this iteration is to avoid overly absolute wording.

For example, statements such as "the controller can be removed" or "this component is unnecessary in all NLB scenarios" should not be presented as universal conclusions unless the implementation scope is fully defined and verified.

A safer documentation style is:

- describe what was actually used in the tested path
- avoid overgeneralizing from one working variant
- keep the wording tied to the specific blueprint and validation scope

This keeps the repository technically honest and easier to maintain.

## Current recommendation for this repository

At the current stage, the repository should present the load balancing story like this:

1. **ALB remains a primary reference path**
2. **NLB is now a documented alternative**
3. **the choice should be based on exposure needs and complexity trade-offs**
4. **the repository should preserve both patterns until later evidence justifies stronger recommendations**

This is a better fit for an evolving infrastructure repository than forcing a premature winner.

## Suggested repository structure

A practical documentation structure is:

- keep ALB-related architecture notes in their original location
- add NLB-focused notes as a sibling variant
- cross-reference both from the root README
- place cost and trade-off commentary in a dedicated `docs/cost-optimization/` section

Example:

```text
docs/
  cost-optimization/
    aws-load-balancing-cost-optimization.md
    nlb-as-alternative-public-entry.md
```

## Conclusion

The main outcome of this iteration is not "ALB was replaced by NLB".

The more accurate conclusion is:

- the repository started with a valid ALB-based pattern

- an NLB-based pattern later reached an initially validated state

- this justified documenting NLB as an alternative public entry blueprint

- the repository should now preserve both paths and explain the trade-offs more clearly

This approach is more useful for long-term repository quality, future iteration, and honest technical communication.
