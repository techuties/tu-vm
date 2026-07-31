---
title: Battery and Power Operator Signals
description: Constructional contract for laptop battery status and energy-aware recommendations that reuse helper status surfaces and operator profiles without cloud device management.
last_updated: 2026-07-31
owner: maintainers
status: proposed
theme: operations
impact: medium
---

# Battery and Power Operator Signals

## Problem

CHANGELOG lists **battery status integration** and power-related improvements as planned features. Historical branches repeat “battery widget” ideas without a contribution contract. Community implementers need a LAN-local, optional signal path that fits the helper + dashboard model—not MDM, not vendor battery clouds.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| Helper status endpoints + dashboard chips | Existing operator signal pattern |
| Stage 2 operator profiles / Stage 4 profile CLI | Energy Save and related profiles |
| Stage 7 idle auto-stop policy | Complementary power-saving control |
| Stage 2 hardware compatibility matrix | Host class context (laptop vs mini PC) |
| `./tu-vm.sh doctor` | Host environment sanity checks |
| Stage 6 observability contract | Host metrics via Prometheus when monitoring is on |

Out of scope:

- Shipping battery telemetry off-LAN by default
- Controlling BIOS/firmware power plans
- Guaranteeing accurate battery data inside every container runtime without host access
- Replacing profiles with opaque “AI power mode”

## Proposal

Add an optional **battery/power signals** slice to the operator control plane.

### Data shape (illustrative)

```json
{
  "battery": {
    "present": true,
    "percent": 64,
    "charging": false,
    "ac_powered": false,
    "updated_at": "2026-07-31T08:00:00Z",
    "source": "host",
    "recommendations": ["Consider Energy Save profile", "Idle auto-stop is available"]
  }
}
```

### Rules

1. **Optional.** Hosts without batteries return `present: false` (not an error).
2. **Local only.** Values stay on the LAN dashboard/helper; not included in public GitHub digests.
3. **Recommendation, not compulsion.** UI may suggest profiles or idle-policy enablement; it must not force-stop services without the idle-policy opt-in.
4. **Helper contract.** Additive endpoint or `/status/full` optional object under the Helper API contribution contract.
5. **Degraded modes.** If the helper container cannot read host power sysfs/UPower, document the limitation and keep `present`/`source` honest.

### Website / UX placement

- Operators → Power → short explainer + link to Energy Save profile
- Dashboard widget only after helper contract + fixture notes land
- Hardware matrix can note “laptop class benefits from battery widget”

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Host read | Standard Linux power interfaces via carefully documented host access | Electron battery apps |
| UI | Existing dashboard status patterns | New mobile-only companion app as prerequisite |
| Actions | Existing profiles + idle policy | Custom power daemon |
| Privacy | Local status JSON | Vendor device-management SaaS |

## Rollout

1. Publish this page; accept design notes via GitHub Issues.
2. Prototype host signal read path behind a feature flag / env toggle.
3. Expose helper JSON; update fixture only for optional keys.
4. Add dashboard widget after Stage 4 modularization makes asset work safer.
5. Wire recommendations to profile CLI `--plan` text.

## Acceptance criteria

- [ ] Non-battery hosts degrade cleanly.
- [ ] No cloud export path in the default design.
- [ ] Recommendations link to existing profiles/policies rather than inventing new stop semantics.
- [ ] Helper/fixture changes follow the helper API contract.

## Rollback

Disable the env flag / omit the widget; helper returns `present: false` or omits the object.

## Success metrics

- Laptop operators can see charge state on the LAN dashboard.
- Energy Save / idle-policy adoption increases among battery hosts without surprise stops.
- Duplicate battery-feature suggestions close as duplicates of this contract.
