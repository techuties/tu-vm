# Feature Roadmap From Historical Suggestions

This proposal translates the existing historical ideas into a structured roadmap.

It intentionally reuses:
- `CHANGELOG.md` planned ideas
- Existing helper API (`helper/uploader.py`)
- Existing landing dashboard (`nginx/html/index.html`)
- Existing operations script (`tu-vm.sh`)
- Existing monitoring stack (`monitoring/`, daily-checkup flow)

---

## Historical suggestions already present

From changelog "future enhancements":
1. Quick Action Profiles
2. Battery status integration
3. Auto-stop for inactive services
4. Resource usage history
5. Smart startup optimization

The roadmap below turns these into practical implementation milestones.

---

## Milestone A - Quick Action Profiles

### Goal
Allow users and contributors to switch system behavior by profile instead of manual per-service toggles.

### Proposed profiles
- **Energy Save**: Tier 1 only, reduced polling, pause heavy services.
- **Work Mode**: Tier 1 + n8n, optional MinIO, no Ollama by default.
- **AI Mode**: Tier 1 + Ollama + Qdrant + Tika.
- **Full Stack**: All services enabled.

### Implementation approach
1. Add profile definitions to script-managed config (`scripts/profiles/*.env` or structured shell arrays in `tu-vm.sh`).
2. Add `./tu-vm.sh profile <name>` command.
3. Expose profile operations through helper API:
   - `POST /control/profile/<name>/apply`
   - `GET /status/profile`
4. Add dashboard profile buttons with active profile badge.

### Community value
- Easier onboarding for new users.
- Shared troubleshooting language ("switch to Work Mode and retry").
- Clear profile definitions invite contribution and discussion.

---

## Milestone B - Battery Status Integration

### Goal
Surface battery and power context in dashboard and automation decisions.

### Implementation approach
1. Expand helper status payload with stable battery object:
   - `battery.present`
   - `battery.status`
   - `battery.capacity_percent`
   - `battery.power_source`
2. Add dashboard card and alerts for battery-aware recommendations.
3. Add rule hooks:
   - when battery < configurable threshold, suggest or trigger profile change.
4. Add command:
   - `./tu-vm.sh battery-status`

### Community value
- Makes laptop and mobile VM operation first-class.
- Enables shared presets contributed by users with different hardware.

---

## Milestone C - Auto-Stop for Inactive Services

### Goal
Reduce idle cost safely without surprising users.

### Service candidates
- Ollama
- n8n (optional and conservative defaults)
- Tika and processor
- Qdrant (if not queried recently)

### Implementation approach
1. Collect lightweight activity signals in helper API:
   - request timestamps from status/control endpoints
   - optional container metrics polling (bounded interval)
2. Add idle policy config in `.env`:
   - `AUTO_STOP_ENABLED`
   - `AUTO_STOP_SERVICES`
   - `AUTO_STOP_IDLE_MINUTES`
3. Run periodic policy evaluator via cron or helper worker.
4. Add safety rails:
   - grace windows
   - never stop core Tier 1 defaults
   - dashboard warning and audit message before stop action

### Community value
- Significant quality-of-life for users who forget to stop heavy services.
- Lower hardware barrier for contributors with limited resources.

---

## Milestone D - Resource Usage History

### Goal
Add simple trends that inform optimization and community discussions.

### Implementation approach
1. Persist periodic snapshots to lightweight store:
   - JSONL in host volume or SQLite.
2. Capture:
   - cpu load
   - memory used
   - disk usage
   - service up/down state
3. Add endpoints:
   - `GET /metrics/history?range=24h`
4. Add charts to dashboard (keep focused and readable):
   - CPU over time
   - memory over time
   - service state timeline

### Community value
- Gives evidence for tuning decisions.
- Enables contributors to compare impact of config changes with data.

---

## Milestone E - Smart Startup Optimization

### Goal
Minimize startup friction and boot-time resource spikes.

### Implementation approach
1. Add startup planner in `tu-vm.sh`:
   - detect last successful profile
   - infer likely use mode from recent history
2. Add staged startup:
   - bring Tier 1 first
   - defer heavy services unless explicitly requested
3. Add post-start checks and user-facing summary:
   - what started
   - what stayed deferred
   - why

### Community value
- Better out-of-box experience.
- Fewer "everything started and machine is slow" support cases.

---

## Cross-cutting architecture recommendations

1. **Single source of state**
   - Keep profile and policy decisions in one module (helper or script layer), not split across many files.
2. **Predictable API contracts**
   - Version response shapes for `/status` and `/metrics` as features grow.
3. **Auditability**
   - Write action logs for automatic start/stop/profile events.
4. **Config transparency**
   - Expose effective settings in `/status/full` so users can self-diagnose behavior.

---

## Suggested implementation order

1. Quick Action Profiles
2. Battery Status Integration
3. Smart Startup Optimization
4. Auto-Stop for Inactive Services
5. Resource Usage History

Rationale:
- Profiles provide the control abstraction used by later steps.
- Battery and startup logic provide immediate UX improvements.
- Auto-stop and history are easier to tune once profile behavior is established.

---

## Community contribution opportunities per milestone

- Milestone A: profile presets and naming conventions
- Milestone B: hardware compatibility reports
- Milestone C: inactivity heuristics and safe defaults
- Milestone D: dashboard visualization pull requests
- Milestone E: startup sequence tuning across device classes

This keeps the roadmap open to community input while preserving a coherent architectural direction.
