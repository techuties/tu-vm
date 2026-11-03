---
title: Open WebUI Audio Model Parameter Contract
description: Constructional contract so the speech-to-text repair passes the model as a bound value and the checker reads the Redis engine it writes.
last_updated: 2026-11-02
owner: maintainers
status: proposed
theme: operations
impact: high
---

# Open WebUI Audio Model Parameter Contract

## Problem

`fix_openwebui_audio_config` in `tu-vm.sh` repairs Open WebUI speech-to-text settings in Postgres and Redis. The model comes from the command line:

```bash
fix-openwebui-audio)
    fix_openwebui_audio_config "${2:-whisper-1}"
```

The default `whisper-1` is safe. The function then pastes whatever string it received into a double-quoted `psql -c` argument:

```bash
docker exec -e PGPASSWORD="$pg_pass" ai_postgres psql -U "$pg_user" -d "$pg_db" -c "UPDATE config
SET data = jsonb_set(
            jsonb_set(
                jsonb_set(data::jsonb, '{audio,stt,engine}', '\"openai\"', true),
                '{audio,stt,model}', '\"${desired_model}\"', true
            ),
            '{audio,stt,supported_content_types}', '${desired_types}'::jsonb, true
          )::json
WHERE id = 1;"
```

Replayed on Bash 5.2.21 with `desired_model` set to `o'brien`. No database was contacted. The SQL text contains:

```text
'{audio,stt,model}', '"o'brien"', true
```

The quote that belongs to the model closes the SQL string. The characters `brien"'` are a new token, not part of the model name. A model that is only letters, digits, and a hyphen does not show this. A model with an apostrophe does. `psql` is not installed on this host, so this page proves the shell text, not a live `UPDATE`.

The same function writes Redis with quote characters included in the value:

```bash
docker exec -e REDISCLI_AUTH="$redis_pass" ai_redis redis-cli --raw SET open-webui:config:STT_ENGINE "\"openai\""
docker exec -e REDISCLI_AUTH="$redis_pass" ai_redis redis-cli --raw SET open-webui:config:STT_MODEL "\"${desired_model}\""
```

That matches a JSON string, which is what the checker tries to undo for the model only:

```bash
redis_engine="${redis_values[0]:-}"
redis_model="$(normalize_json_string_value "${redis_values[1]:-}")"
if [[ "$redis_engine" == "openai" && -z "$redis_model" ]]; then
    issues+=("Redis STT model is empty while STT engine is openai")
fi
```

`normalize_json_string_value` strips one leading and one trailing double quote. It is applied to the model and not to the engine. Replayed on Bash 5.2.21: the raw engine value `"openai"` does not equal `openai`. The same function returns `openai`. After a repair, an empty Redis model is not reported, because the engine comparison never succeeds.

The reader has a second split. `check_openwebui_audio_config` prints four fields separated by `|` and then `IFS='|' read`. A model that itself contains `|` moves the later fields. The repair and the checker are one command pair. Both have to treat the model as data.

Checked on 2026-11-02 by reading `fix_openwebui_audio_config` and `check_openwebui_audio_config`, and by replaying the shell strings. `./tu-vm.sh fix-openwebui-audio` was not run. Postgres and Redis were not started.

## Existing scan (reuse first)

| Asset | Role |
|---|---|
| `fix_openwebui_audio_config` | The repair that must stop pasting the model into SQL |
| `check_openwebui_audio_config` | The reader that must see the engine it just wrote |
| `normalize_json_string_value` | Quote strip already used for the Redis model |
| `psql -v` / `:'name'` | Bound literal syntax in the `psql` client this script already execs |
| `python3 -c` with `json.dumps` | JSON encoding already used by `scripts/daily-checkup.sh` and `scripts/doctor.sh` |
| Stage 53 service-probe credentials (open PR #79) | Passwords on the `psql` and `redis-cli` lines. Unchanged here |

Out of scope:

- A new speech-to-text service or a settings UI
- The password environment variables Stage 53 already names
- Open WebUI's own loader source (Stage 49 and Stage 59)
- Running the repair against a live database from this page

## Proposal

Keep the repair as `psql` and `redis-cli` inside the existing containers. Pass the model as a variable, and encode the Redis value with the JSON library the repo already runs.

### Contribution lanes

| Lane | Where | Suggested change |
|---|---|---|
| SQL | `fix_openwebui_audio_config` | `psql -v model="$desired_model" -c "... to_jsonb(:'model') ..."` |
| Redis | The three `SET` lines | Build the JSON string with `json.dumps` and pass that one argument to `redis-cli` |
| Checker | `check_openwebui_audio_config` | Run `normalize_json_string_value` on the engine as well as the model |
| Reader split | The `psql -F '|'` row | Return one JSON object and read fields from that object |

### Rules

1. **The model is a bound SQL literal.** `:'model'` is the `psql` form that quotes the variable. The characters of the model must not be concatenated into the `-c` string.
2. **Redis values stay JSON strings.** Open WebUI's checker already strips one pair of quotes. Produce that encoding with `json.dumps`, including for the constant `openai` and for the content-type array.
3. **The engine check uses the same normalizer as the model check.** `normalize_json_string_value` already exists. Call it for `STT_ENGINE`.
4. **The reader must not split on a character a model can contain.** A `|` inside the model currently shifts `db_base_url` and `db_types`.
5. **Leave the password lines alone.** `PGPASSWORD` and `REDISCLI_AUTH` stay as Stage 53 described them.

### Suggested contributor checklist

```text
1. Build the SQL text with model o'brien and confirm the model characters appear only as a psql variable, not inside the -c string
2. Confirm to_jsonb(:'model') is the jsonb value written at {audio,stt,model}
3. Confirm the Redis SET arguments are the JSON encodings of openai, the model, and the content-type array
4. Confirm a Redis engine value of "openai" with an empty model is reported
5. Confirm a model containing | does not shift the other checker fields
6. Confirm PGPASSWORD and REDISCLI_AUTH were not edited
```

### Framework reuse

| Need | Prefer | Avoid |
|---|---|---|
| Quote a SQL value | `psql -v` and `:'model'` | String pasting inside `-c` |
| Quote a JSON value | `json.dumps` via the `python3` already on the host | A new JSON helper package |
| Strip stored JSON quotes | `normalize_json_string_value` | A second parser |
| Intake | GitHub Issue | A dashboard form for this repair |

### Acceptance check

- [ ] The `psql -c` string does not contain `${desired_model}`.
- [ ] `o'brien` is stored as the model text, and the statement is one `UPDATE`.
- [ ] Redis `STT_ENGINE` and `STT_MODEL` are JSON strings produced by `json.dumps`.
- [ ] The empty-model warning compares the normalized engine to `openai`.
- [ ] A model containing `|` does not change `db_base_url` or `db_types`.
- [ ] No Postgres container was required to prove the shell text.

### Rollback

Restore the previous `-c` string and the three `SET` lines. Models that are only letters, digits, and hyphens keep the same stored JSON either way. A database that already holds a broken statement from a quoted model needs a later repair with the bound form. It does not need a restore of Postgres.
