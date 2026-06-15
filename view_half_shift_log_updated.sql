CREATE VIEW view_half_shift_log AS
WITH base AS (
SELECT
  UPPER(program_state) as program_state,
  log_key,
  shift_number,
  shift_treatment_type,
  shirt_color,
  participants_surveyed,
  enumerator_id,
  date(half_shift_date) AS shift_date,
  date(
    half_shift_date,
    --- add day offset since half_shift_date is local but time_change_shirts is utc
    CASE 
      WHEN LOWER(program_state) = 'nv' 
        AND CAST(SUBSTR(time_change_shirts, 1, 2) AS INT) BETWEEN 0 AND 6 THEN '+1 day' -- changed from "BETWEEN 1 AND 7"
      WHEN LOWER(program_state) IN ('ga', 'mi') 
        AND CAST(SUBSTR(time_change_shirts, 1, 2) AS INT) BETWEEN 0 AND 3 THEN '+1 day' -- changed from "BETWEEN 1 AND 4"
      ELSE '+0 days'
    END
  ) || ' ' || time_change_shirts AS shift_change_timestamp_utc
FROM half_shift_log
)
SELECT
  *,
  strftime(
    '%l:%M %p', 
    datetime(
      shift_change_timestamp_utc,
      CASE 
        WHEN program_state = 'NV'          THEN '-7 hours'
        WHEN program_state IN ('GA', 'MI') THEN '-4 hours'
      END
    )
  ) || ' ' || 
    CASE 
      WHEN program_state = 'NV'          THEN 'PT'
      WHEN program_state IN ('GA', 'MI') THEN 'ET'
    END AS shift_change_time_pretty
FROM base