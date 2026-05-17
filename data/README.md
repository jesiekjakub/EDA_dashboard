# Dataset

The dashboard expects `student_habits_performance.csv` in this directory. The CSV is not committed.

The Docker workflow handles this automatically: the `fetcher` service in `docker-compose.yml` calls the Kaggle API on first start (credentials from `.env`) and unzips the CSV here. For local non-Docker runs, either drop the CSV in manually or run `bootstrap_data.py` once.

## Source

Kaggle: [Student Habits vs Academic Performance](https://www.kaggle.com/datasets/jayaantanaath/student-habits-vs-academic-performance)

## Schema

| Column | Type | Description |
|---|---|---|
| `student_id` | string | Per-record identifier. Dropped on load. |
| `age` | int | Student age in years. |
| `gender` | string | Reported gender. |
| `study_hours_per_day` | float | Mean daily study time. |
| `social_media_hours` | float | Mean daily social-media use. |
| `netflix_hours` | float | Mean daily streaming-service use. |
| `part_time_job` | string | `Yes` / `No`. |
| `attendance_percentage` | float | Class attendance, 0–100. |
| `sleep_hours` | float | Mean nightly sleep. |
| `diet_quality` | string | `Poor` / `Fair` / `Good`. |
| `exercise_frequency` | int | Workouts per week. |
| `parental_education_level` | string | Highest level reached. |
| `internet_quality` | string | `Poor` / `Average` / `Good`. |
| `mental_health_rating` | int | Self-reported, 1–10. |
| `extracurricular_participation` | string | `Yes` / `No`. |
| `exam_score` | float | Final exam score, 0–100. |

The dashboard adds a derived `grade` column on a 6-point Polish scale
(2.0, 3.0, 3.5, 4.0, 4.5, 5.0) computed from `exam_score`.
