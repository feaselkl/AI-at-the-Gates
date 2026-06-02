# Block 3 demo — prompt makeover, OFFLINE (pre-captured)

Run this when you want a guaranteed four-step arc with **no internet** — a recorded
talk, a flaky room, or to stay on the clock. Same task and **same prompts** as the
online version ([`claude-code-online.md`](claude-code-online.md)); the outputs are
captured below so you just narrate.

> Fidelity note: the v2–v4 queries are **real, schema-correct T-SQL**, and their
> behavior is **verified against the `WakeCountyFood` database** (v2 → 0 rows;
> v3 → fan-out inflation; v4 → correct). v1 is a representative hallucination.
> Re-capture wording from your own model run if you want it verbatim — but keep
> the prompts and the *lessons* identical to the online version.
>
> Optional: with the SQL container running you can still run v2/v3/v4 live here to
> show the 0-rows / inflation / correct results in real time.

**The task (fixed throughout):** "Find the restaurants with the most **critical**
violations in the last 12 months, with the count and their most recent inspection
score, worst first."

---

## v1 — no context  →  hallucinated schema
**Prompt:** *Without reading any files, write a SQL query to find the restaurants
with the most health-code violations.*

**Captured output:**
```sql
SELECT r.name, COUNT(*) AS violation_count
FROM restaurants AS r
JOIN violations AS v ON v.restaurant_id = r.id
GROUP BY r.name
ORDER BY violation_count DESC
LIMIT 10;
```
**Why it's wrong:** `restaurants`, `violations`, `restaurant_id`, `id` don't exist;
`LIMIT` isn't T-SQL; no definition of "critical," no date window, no score. It
wouldn't even parse against the database. **Lesson:** zero context → confident
fiction. *(This is your "spot the hallucination" hook.)*

## v2 — role + structure  →  right tables, wrong vocabulary
**Prompt:** *You are a senior SQL Server 2025 (T-SQL) DBA. Use the schema in
`schema.sql`. The restaurants with the most **critical** violations, with the
count, worst first.*

**Captured output:**
```sql
SELECT TOP (10)
    r.Name,
    COUNT(*) AS ViolationCount
FROM dbo.FoodInspectionViolation AS v
JOIN dbo.Restaurant AS r ON r.HSISID = v.HSISID
WHERE v.Severity = 'Critical'          -- guessed; this value does not exist
GROUP BY r.Name
ORDER BY ViolationCount DESC;
```
**Result (verified): 0 rows.** The real values are `Core` / `Priority` /
`Priority Foundation`. **Lesson:** correct structure, but the model can't know your
data's *vocabulary* unless you tell it.

## v3 — domain knowledge + task precision  →  correct filters, fan-out bug
**Prompt:** *`Severity` is `'Core'` / `'Priority'` / `'Priority Foundation'` (or
NULL); treat the latter two as critical. Restrict to the 12 months ending
`@AsOf = '2026-03-31'`. Include each restaurant's most recent inspection score as
of that date. Top 20, worst first.*

**Captured output:**
```sql
DECLARE @AsOf date = '2026-03-31';
SELECT TOP (20)
    r.Name,
    r.City,
    COUNT(*)  AS CriticalViolations,
    fi.Score  AS RecentScore
FROM dbo.FoodInspectionViolation AS v
JOIN dbo.Restaurant AS r       ON r.HSISID = v.HSISID
JOIN dbo.FoodInspection AS fi  ON fi.HSISID = v.HSISID     -- naive: joins ALL inspections
WHERE v.Severity IN ('Priority', 'Priority Foundation')
  AND v.InspectDate >= DATEADD(MONTH, -12, @AsOf)
  AND v.InspectDate <  DATEADD(DAY, 1, @AsOf)
GROUP BY r.Name, r.City, fi.Score
ORDER BY CriticalViolations DESC;
```
**Result (verified): inflated and duplicated.** Joining every inspection fans the
rows out: BASS LAKE DRAFT HOUSE's **5** critical violations become **165**
(× 33 inspections), and restaurants repeat once per distinct score. **Lesson:**
right filters, classic join fan-out — "most recent score" is not a plain join.

## v4 — correctness constraints + house style  →  production-quality
**Prompt:** *Set-based and SARGable (don't wrap `InspectDate` in a function); avoid
the fan-out — count violations in a derived table and get the most recent score via
`OUTER APPLY ... TOP (1)`; `INNER JOIN` to `Restaurant`. Output one T-SQL block in
our house style (header comment, UPPERCASE keywords, schema-qualified, 4-space
indent).*

**Captured output:**
```sql
/* -----------------------------------------------------------------------------
   Top restaurants by critical violations in the trailing 12 months.
   Critical = Severity IN ('Priority','Priority Foundation').
   Most recent inspection score is taken as of the same reference date.
   ----------------------------------------------------------------------------- */
DECLARE @AsOf date = '2026-03-31';      -- reference "today" for this frozen dataset

SELECT TOP (20)
    r.Name              AS RestaurantName,
    r.City,
    cv.CriticalViolations,
    ls.Score            AS MostRecentScore,
    ls.InspectionDate   AS MostRecentInspection
FROM (
    SELECT v.HSISID, COUNT(*) AS CriticalViolations
    FROM dbo.FoodInspectionViolation AS v
    WHERE v.Severity IN ('Priority', 'Priority Foundation')
      AND v.InspectDate >= DATEADD(MONTH, -12, @AsOf)
      AND v.InspectDate <  DATEADD(DAY, 1, @AsOf)
    GROUP BY v.HSISID
) AS cv
INNER JOIN dbo.Restaurant AS r
    ON r.HSISID = cv.HSISID                  -- named restaurants only
OUTER APPLY (
    SELECT TOP (1) fi.Score, fi.InspectionDate
    FROM dbo.FoodInspection AS fi
    WHERE fi.HSISID = cv.HSISID
      AND fi.InspectionDate <= @AsOf
    ORDER BY fi.InspectionDate DESC
) AS ls
ORDER BY cv.CriticalViolations DESC, r.Name;
```
**Result (verified): correct.** Clean top 20 — counts no longer inflated, most
recent score via `OUTER APPLY` (NULL when there's no qualifying inspection):

```
RestaurantName                          City         CriticalViolations  MostRecentScore  MostRecentInspection
--------------------------------------  -----------  ------------------  ---------------  --------------------
HIBACHI CHINA BUFFET                    CARY                         10            97.50  2025-10-08
ANTOJITOS DONA MARY (WCID #004)         RALEIGH                       6            90.00  2025-07-01
BLR FOOD STREET                         MORRISVILLE                   6            92.50  2025-12-04
TACOS MI TIERRA CALIENTE (WCID #792)    RALEIGH                       6            94.00  2025-12-17
CRAB DU JOUR CAJUN SEAFOOD RESTAURANT   RALEIGH                       5            91.00  2025-08-28
HAN-DEE HUGO'S #41                      CARY                          5             NULL  NULL
...
```
**Lesson:** same model throughout — the **prompt** carried it from fiction to
production. You supplied the vocabulary, the intent, the correctness bar, and the
house style, and you verified every step.

---

## The takeaway slide (recipe card)
**Role · Context · Task · Constraints · Output format — and verify everything.**
Context (your schema + your data's vocabulary) is the highest-leverage ingredient.
