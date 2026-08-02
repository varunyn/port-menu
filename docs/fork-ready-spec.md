# Port Menu: Fork-Ready Container Metadata and Repository Hygiene

> Project Hub task: `55c75c41-88b1-41b5-ad85-4da94066afab`
>
> Published: 2026-08-02

## Problem Statement

As a maintainer of the forked Port Menu repository, I need the app and repository to be safe and useful to publish from my fork. Container-backed development servers are difficult to identify because the scanner treats the runtime process as the project, omits useful image metadata, and only attempts container discovery when a narrow runtime-process heuristic matches. The repository also retains upstream publishing references and does not ignore common local signing or credential artifacts.

## Solution

Make container port discovery a first-class part of the live scan. Resolve published host ports through the Docker-compatible CLI, retain the actual container name and image, and expose those values in the menu while preserving Git-project and ordinary development-server behavior. Make the repository fork-ready by using the fork for documented clone and release URLs, allowing the release repository to be overridden, and ignoring common local credential/signing files. Verify the behavior through the existing scanner and store test seams, then publish the reviewed changes to the fork's main branch.

## User Stories

1. As a developer running a Docker container, I want its published host port to appear in Port Menu, so that I can open and manage the service without remembering which container owns the port.
2. As a developer running an OrbStack container, I want the same container discovery behavior as Docker, so that my local runtime does not change the usefulness of Port Menu.
3. As a developer running a Compose application, I want to see the actual container name, so that I can distinguish individual replicas and services.
4. As a developer running a Compose application, I want to see the Compose service name as the secondary context, so that I can understand the role of the container.
5. As a developer running a standalone container, I want the container name to be used as its project label, so that the row remains identifiable even without Compose labels.
6. As a developer inspecting a container-backed service, I want to see its image name, so that I can distinguish services that expose similar ports.
7. As a developer using a Git-backed local service, I want the repository name and branch behavior to remain unchanged, so that container support does not regress project context.
8. As a developer running a recognized non-container development runtime, I want it to remain visible when no Git root can be found, so that useful local services are not filtered out.
9. As a developer with no Docker-compatible CLI or an unavailable daemon, I want scanning to degrade gracefully, so that ordinary local port scanning continues to work.
10. As a developer with malformed or incomplete container CLI output, I want valid port rows to retain safe fallback labels, so that one incomplete record does not break the scan.
11. As a maintainer of a fork, I want README clone instructions to point to my fork, so that new contributors start from the intended repository.
12. As a maintainer of a fork, I want generated release-feed and asset URLs to target my fork by default, so that Sparkle updates and release assets are published consistently.
13. As a maintainer with a different release repository, I want the release repository to be configurable, so that the release script remains reusable without source edits.
14. As a maintainer, I want local environment files and signing credentials excluded from version control, so that accidental publication of secrets is less likely.
15. As a maintainer, I want existing public build metadata to remain usable, so that signing configuration does not require embedding private credentials.
16. As a contributor, I want the project to compile and its tests to pass after the scanner changes, so that the fork is safe to publish.
17. As a contributor, I want test fixtures to represent container names and images, so that future changes preserve the user-visible container context.
18. As a repository owner, I want the fork's main branch to contain the reviewed changes, so that collaborators and release automation use the same source of truth.

## Implementation Decisions

- Treat container discovery as an independent best-effort enrichment phase of live port scanning rather than gating it on a single process-name heuristic.
- Query the Docker-compatible CLI for running containers, published host ports, container names, Compose project labels, Compose service labels, and image names.
- Map each published host port to container metadata. Prefer the actual container name for the displayed project identity; use the Compose service as branch-like secondary context when available.
- Preserve existing Git-root and fallback-process behavior for non-container processes.
- Extend the domain model for an active port with optional image metadata while keeping existing initializers and non-container rows compatible.
- Render image metadata only for container rows, with compact, truncated secondary text so the menu remains scannable.
- Keep CLI discovery best-effort with a short timeout and an empty-result fallback when the CLI or daemon is unavailable.
- Preserve the existing public release workflow and use a configurable repository identifier with the fork as the default.
- Update repository-facing documentation to reference the fork.
- Add ignore rules for environment files and common signing/credential artifacts while allowing an explicitly reviewed example environment file.
- Do not add credentials, private keys, provisioning profiles, or notarization passwords to the repository.
- Use the existing Swift Testing suites and domain seams; no new abstraction layer is required for this change.

## Testing Decisions

- Test external behavior rather than implementation details: given representative container CLI output, assert the host-port-to-container metadata mapping and the resulting display data.
- Extend the existing container-output parser tests to cover actual container names, Compose project/service labels, image names, standalone containers, remapped ports, unpublished ports, and malformed rows.
- Retain tests for non-container Git-root resolution, known runtime fallback filtering, and active-port identity/equality so container enrichment cannot change unrelated behavior.
- Use existing PortStore tests to verify that scanner results continue to populate, refresh, and fail gracefully.
- Validate release and build shell scripts with shell syntax checks and repository diff checks.
- Run the macOS Xcode test suite with code signing disabled for verification; the expected baseline is all existing tests passing with no failures.
- Avoid tests that assert private helper structure, exact CLI invocation internals, or view layout implementation details beyond externally visible container metadata.

## Out of Scope

- Adding a new container runtime integration or replacing the Docker-compatible CLI.
- Starting, stopping, restarting, or inspecting container logs from Port Menu.
- Changing how ordinary local processes are discovered or terminated.
- Storing container history, Docker credentials, registry tokens, or daemon configuration.
- Automating GitHub releases, notarization, Sparkle key management, or CI provisioning.
- Rewriting repository history to remove public author metadata or previously published non-secret commits.
- Hiding or rotating a public Apple Developer Team ID; it is signing metadata, not a private credential.
- Redesigning the broader menu UI or adding new navigation screens.

## Further Notes

The implementation should remain compatible with Docker and OrbStack command-line behavior and tolerate missing Compose labels. The fork is the publishing target, while upstream may remain configured as a separate read-only reference remote. The reviewed implementation was verified against the existing macOS test suite, including 54 tests across 12 suites.
