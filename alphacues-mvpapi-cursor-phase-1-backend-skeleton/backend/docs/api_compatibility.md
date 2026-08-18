# API Compatibility, Versioning & Migration Safety Policy

## 1. Versioning & Deprecation Policy

### 1.1 Canonical Base Path
- `/api/v1` is the canonical base path for all Alpha Cues MVP backend endpoints.
- Older `/api/*` paths from legacy proxy backends may remain as read-only aliases during active migration windows. No legacy path may be silently repurposed to new or incompatible semantics.

### 1.2 Versioning & Breaking Changes
- **Canonical Envelope**: All `/api/v1` responses must conform to the project standard:
  ```json
  {
    "success": true,
    "data": {},
    "error": null,
    "meta": {
      "requestId": "<uuid>",
      "apiVersion": "1",
      "nextCursor": null
    }
  }
  ```
- **Breaking Changes**: Any change that removes a field, changes a data type, alters enum contracts, or introduces non-backward-compatible validation constraints **requires an `/api/v2` endpoint prefix**.
- **Additive Changes**: New optional/nullable fields may be added to existing `/api/v1` response shapes provided existing JSON structure and nullability rules for existing fields are strictly preserved.
- **Deprecation Window**: Deprecated fields must remain populated and supported for **at least one full frontend release cycle** before removal.

---

## 2. Database & Schema Migration Rules

1. **Additive-First Schema Evolution**: All database migrations must be non-destructive first (add columns as nullable or with safe defaults, add new tables).
2. **Delayed Destructive Changes**: Destructive migrations (dropping columns or tables) must wait until at least one release after the corresponding API fields have been deprecated and unlinked from client usage.
3. **Forward-Fix Rollback Strategy**: In production incidents caused by schema/contract mismatches, engineers must prefer a **forward-fix patch** over a blind database schema rollback to prevent data loss.

---

## 3. High-Variance Area Guidelines (`alerts` & `market`)

The `alerts` and `market` modules (`stock_tick`, rollups, quote, bars, snapshot, search, movers, fundamentals) represent high-variance contracts:
> **Risk Note**: Undocumented additive fields can still break frontend mobile/web client models if field nullability or types change unexpectedly.

### Mandatory Rules for `alerts` and `market`:
- Any new field added to alert triggers or market payloads must be explicitly declared as optional/nullable in serialization schemas.
- Contract fixtures under `backend/tests/fixtures/contracts/alerts/` and `backend/tests/fixtures/contracts/market/` MUST be updated in the same commit whenever additive fields are added.
- Contract validation tests (`contract_check.py`) must be executed to verify no unexpected type changes or nullability violations are introduced.

---

## 4. Engineer Migration Safety Checklist

Before committing or deploying any API contract or schema change, engineers must complete the following checklist:

```markdown
- [ ] 1. Is this change strictly additive? (No removed fields, no type alterations)
- [ ] 2. If non-additive or breaking: Has a new `/api/v2` endpoint route been introduced instead of altering `/api/v1`?
- [ ] 3. Does nullability change for any existing field? (Non-nullable -> nullable or vice-versa requires explicit contract review)
- [ ] 4. Has a JSON fixture been updated under `backend/tests/fixtures/contracts/<module>/*`?
- [ ] 5. For `alerts` or `market` additive changes: Have marshmallow/pydantic serialization schemas been updated to preserve explicit default/nullability behavior?
- [ ] 6. Has `backend/scripts/contract_check.py` passed cleanly without exit code 1?
- [ ] 7. Has an entry been recorded in `CHANGELOG.md` under the appropriate module section?
```
