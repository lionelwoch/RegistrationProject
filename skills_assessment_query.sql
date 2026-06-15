-- Step 1a: Cross-tab of treatment/control sessions by enumerator, shift date
SELECT enumerator_id, half_shift_date,
  SUM(CASE WHEN shift_treatment_type = 'treatment' THEN 1 ELSE 0 END) AS treatment,
  SUM(CASE WHEN shift_treatment_type = 'control' THEN 1 ELSE 0 END) AS control,
  COUNT(*) AS total
  FROM half_shift_log
GROUP BY enumerator_id, half_shift_date

-- Step 1b: Filter out enumerators whose total shifts per day is not equal to 2
SELECT enumerator_id, half_shift_date,
  SUM(CASE WHEN shift_treatment_type = 'treatment' THEN 1 ELSE 0 END) AS treatment,
  SUM(CASE WHEN shift_treatment_type = 'control' THEN 1 ELSE 0 END) AS control,
  COUNT(*) AS total
  FROM half_shift_log
GROUP BY enumerator_id, half_shift_date
HAVING COUNT(*) != 2 -- check why these enumerators have 1 or 3 half shifts on some days
  
-- Step 2: Cross-tab showing number of clock-ins/clock-outs per shift
SELECT
  enumerator_id,
  DATE(endtime) AS submission_date,
  SUM(CASE WHEN shift_number = 1 AND current_time_in IS NOT NULL THEN 1 ELSE 0 END) AS clock_in,
  SUM(CASE WHEN shift_number = 2 AND current_time_out IS NOT NULL THEN 1 ELSE 0 END) AS clock_out
FROM survey_data
GROUP BY enumerator_id, submission_date
  HAVING clock_in != 1 OR clock_out != 1
ORDER BY enumerator_id, submission_date 
-- check why these enumerators never clock in, clock in more than once, never clock out, or clock out more than once

-- Step 3: Cross-tab comparing number of surveys per day per shift from survey_data vs half_shift_log datasets
SELECT
  s.enumerator_id,
  DATE(s.endtime) AS submission_date,
  SUM(CASE WHEN s.shift_number = 1 AND s.question_1 IS NOT NULL THEN 1 ELSE 0 END) AS shift1_surveys,
  SUM(CASE WHEN s.shift_number = 2 AND s.question_1 IS NOT NULL THEN 1 ELSE 0 END) AS shift2_surveys,
  l1.participants_surveyed AS shift1_logged,
  l2.participants_surveyed AS shift2_logged,
  CASE WHEN SUM(CASE WHEN s.shift_number = 1 AND s.question_1 IS NOT NULL THEN 1 ELSE 0 END) = l1.participants_surveyed THEN 1 ELSE 0 END AS shift1_matched,
  CASE WHEN SUM(CASE WHEN s.shift_number = 2 AND s.question_1 IS NOT NULL THEN 1 ELSE 0 END) = l2.participants_surveyed THEN 1 ELSE 0 END AS shift2_matched
FROM survey_data s
LEFT JOIN half_shift_log l1
  ON s.enumerator_id = l1.enumerator_id
  AND DATE(s.endtime) = l1.half_shift_date
  AND l1.shift_number = 1
LEFT JOIN half_shift_log l2
  ON s.enumerator_id = l2.enumerator_id
  AND DATE(s.endtime) = l2.half_shift_date
  AND l2.shift_number = 2
GROUP BY s.enumerator_id, submission_date
ORDER BY s.enumerator_id, submission_date
-- check why these enumerators surveyed a different number of participants in either shift than what was recorded in the shift log dataset

-- Step 4: filter bottom 25% of rows by survey duration
SELECT * 
  FROM view_survey_data 
  WHERE submission_type = 'survey'
  ORDER BY CAST(duration_in_secs AS INTEGER) ASC 
  LIMIT (SELECT ROUND(COUNT(*) * 0.25) FROM view_survey_data WHERE submission_type = 'survey') 
-- check whether it's feasible to complete the survey within 92 seconds (25th percentile)

