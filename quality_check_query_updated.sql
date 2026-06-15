SELECT
    s.program_state,
    l.shift_date,
    s.shift_number,
    s.enumerator_id,
    s.submission_time_pretty as submission_time_app,
    l.shift_change_time_pretty as logged_shirt_change_time,
    s.shift_treatment_type,
    -- remove this duplicate: s.enumerator_id,
    s.survey_key,
    s.submission_timestamp_utc,
    s.submission_datetime_localized,
    l.shift_change_timestamp_utc,
    s.duration_in_secs
FROM view_survey_data s
INNER JOIN view_half_shift_log l
ON s.enumerator_id = l.enumerator_id 
AND s.program_state = l.program_state 
AND s.submission_date = l.shift_date
WHERE ((s.submission_timestamp_utc >= l.shift_change_timestamp_utc AND s.shift_number = 1)
OR (s.submission_timestamp_utc < l.shift_change_timestamp_utc AND s.shift_number = 2))
AND s.submission_type = 'survey' 
ORDER BY s.submission_date, s.program_state, s.enumerator_id, s.submission_timestamp_utc