# The Shape of Sleep

An interactive data story exploring sleep health patterns across 374 adults — stress, occupation, BMI, and sleep disorders — built from the *Sleep Health and Lifestyle* dataset.

**[View the live story](https://danasalama48-droid.github.io/SLEEP-HEALTH-LIFESTYLE/)**

## What this is

A single-page, self-contained HTML visualization (Chart.js) that walks through five findings in the dataset:

1. **The stress line** — stress level is the strongest predictor of sleep quality in the data (r ≈ −0.81).
2. **The occupation gap** — average sleep duration and stress vary sharply by job (engineers sleep ~1.6 hrs more than salespeople).
3. **The weight connection** — sleep disorder rates climb steeply with BMI category.
4. **Two disorders, two causes** — nurses skew toward Sleep Apnea; salespeople and teachers skew toward Insomnia.
5. **The gender gap** — a modest difference in sleep duration, a larger one in reported stress.

## Dataset

`Sleep_health_and_lifestyle_dataset.csv` — 374 rows, 13 columns:

| Column | Description |
|---|---|
| Person ID | Unique identifier |
| Gender | Male / Female |
| Age | Age in years |
| Occupation | Job title |
| Sleep Duration | Average hours of sleep per night |
| Quality of Sleep | Self-rated, 1–10 |
| Physical Activity Level | Minutes of daily activity |
| Stress Level | Self-rated, 1–8 |
| BMI Category | Normal / Normal Weight / Overweight / Obese |
| Blood Pressure | Systolic/diastolic (e.g. 126/83) |
| Heart Rate | Resting heart rate (bpm) |
| Daily Steps | Average daily step count |
| Sleep Disorder | None / Insomnia / Sleep Apnea |

## Repo structure

```
.
├── README.md
├── sleep_story.html          # the visual story (open directly in a browser)
├── schema.sql                # SQL to create a normalized database for this data
└── Sleep_health_and_lifestyle_dataset.csv   # source data (add your own copy)
```

## Setting up the database

`schema.sql` creates a normalized schema (a `people` table plus a `blood_pressure` split into systolic/diastolic) and includes the `CREATE TABLE` statements, indexes, and a load command. See that file for details — it targets PostgreSQL syntax but only uses standard SQL types, so it also runs in MySQL/SQLite with minor tweaks (e.g. `SERIAL` → `AUTOINCREMENT` for SQLite).

```bash
psql -U your_user -d your_db -f schema.sql
```

## Tech

- Chart.js (via CDN) for the visualizations
- Plain HTML/CSS/JS — no build step, no dependencies to install
- SQL schema for anyone who wants to query the dataset relationally instead of from the CSV

## License

MIT (or your preferred license — update this section).
