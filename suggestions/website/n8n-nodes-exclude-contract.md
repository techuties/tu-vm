---
title: n8n Node Exclude Contract
description: Constructional contract to pin the n8n 2.25.7 NODES_EXCLUDE default so Execute Command and Local File Trigger stay unloaded.
last_updated: 2026-09-23
owner: maintainers
status: proposed
theme: operations
impact: high
---

# n8n Node Exclude Contract

## Problem

n8n `2.25.7` sets `NODES_EXCLUDE` in `packages/@n8n/config/src/configs/nodes.config.ts`:

```text
['n8n-nodes-base.executeCommand', 'n8n-nodes-base.localFileTrigger']
```

The comment in that file says the default excludes Execute Command and Local File Trigger, and that an empty array allows all node types. Official node docs show the same array and warn that `NODES_EXCLUDE: "[]"` enables the nodes that are blocked by default.

Compose does not pin the key. Unset still uses the code default, which is safe. The hazard is a later edit. The parser in that file (`JsonStringArray`) returns an empty array when the string is not valid JSON. An empty array loads Execute Command. A broken quote in Compose is therefore an allow-all, not a fallback to the secure default.

Stage 34 `n8n-restrict-file-access-contract.md` (expected sibling) owns `N8N_RESTRICT_FILE_ACCESS_TO`. This page does not add Read/Write Files to the exclude list. The pinned default does not include that node. Adding it needs its own Issue so existing workflows are not broken in the same change.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| n8n `2.25.7` `nodes.config.ts` | Default exclude array and empty-array-on-parse-failure |
| Official block-nodes guide | `[]` enables nodes that are blocked by default |
| `n8n` environment | `NODES_EXCLUDE` unset today, so the code default applies |
| Stage 34 file-jail contract (expected sibling) | Filesystem path restriction, separate key |
| GitHub Issues | Place to add or remove a node type |

Out of scope:

- A node-policy service, admission webhook, or custom n8n build
- Setting `NODES_INCLUDE` to a hand-maintained allowlist of every node
- Setting `NODES_EXCLUDE` to `[]`
- Changing `N8N_RESTRICT_FILE_ACCESS_TO` or `N8N_BLOCK_ENV_ACCESS_IN_NODE` (Stage 33 / 34)
- Disabling community packages (Stage 34 already has that contract)

## Proposal

Pin the official default on the `n8n` service as a JSON array string:

```text
NODES_EXCLUDE: '["n8n-nodes-base.executeCommand","n8n-nodes-base.localFileTrigger"]'
```

Single quotes in Compose keep the JSON intact. Do not invent `TU_VM_BLOCKED_NODES`. Do not append `n8n-nodes-base.readWriteFile` in this change.

After recreate, confirm the running exclude list is those two types. If the editor can still search for Execute Command, the JSON did not parse and the list collapsed to empty.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| Compose | `n8n` environment | Official two-type JSON array |
| Env schema | `env.example` | Comment: invalid JSON becomes allow-all |
| Docs | n8n playbook | How to check the loaded node list after a quote change |
| Extra blocks | GitHub Issue | One node type per Issue, with a workflow search first |

### Rules

1. **Pin the 2.25.7 default.** Execute Command and Local File Trigger only.
2. **Valid JSON or it allows everything.** A parse error returns `[]`.
3. **`[]` is the enable-all switch.** Do not use it to "clear" the setting. Remove the env key instead.
4. **Do not maintain `NODES_INCLUDE` as a second policy.** Empty include already means "load everything that is not excluded."
5. **GitHub remains intake.** Adding Read/Write Files or any other type is a separate review.

### Suggested contributor checklist

```text
1. Confirm the pinned n8n 2.25.7 image still defaults NODES_EXCLUDE to executeCommand and localFileTrigger
2. Set that JSON array on the n8n service
3. Recreate n8n
4. Confirm Execute Command is not offered in the node search
5. Confirm the value is valid JSON (a bad quote must not ship)
6. Leave N8N_RESTRICT_FILE_ACCESS_TO and community-package keys unchanged
7. Do not add a node-policy service
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Block Execute Command and Local File Trigger | Official `NODES_EXCLUDE` array | A custom node firewall |
| Filesystem jail | Stage 34 restrict-file-access key | Stuffing more nodes into this pin |
| Code node env | Stage 33 env-access block | A new sandbox runtime |
| Allow one blocked node | Remove it in an Issue, with `[]` only when every default block should lift | A silent empty array |

## Rollout

1. Publish this page under `suggestions/website/`.
2. Prefer **code**: one Compose line, a JSON check, and an n8n recreate.
3. Further exclusions need an Issue that searches saved workflows for that node type.

## Acceptance criteria

- [ ] `n8n` sets `NODES_EXCLUDE` to the JSON array of `n8n-nodes-base.executeCommand` and `n8n-nodes-base.localFileTrigger`.
- [ ] The value is valid JSON, not `[]`.
- [ ] `N8N_RESTRICT_FILE_ACCESS_TO` is not edited by this change.
- [ ] No node-policy service is added.

## Rollback

Remove the key to restore the same code default. Setting `[]` enables Execute Command and is not a rollback.

## Success metrics

- Execute Command and Local File Trigger stay out of the node picker.
- A malformed value is caught before recreate, because invalid JSON would load both nodes.
