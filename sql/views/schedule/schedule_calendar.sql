CREATE OR REPLACE VIEW view_schedule_calendar AS
SELECT
  event.event_id,
  event.conference_id,
  event.title,
  event.subtitle,
  event.slug,
  event.abstract,
  event.description,
  event.conference_day_id,
  conference_day.conference_day,
  conference_day.name AS conference_day_name,
  event.start_time,
  event.duration,
  event.language,
  event_state_localized.translated,
  language_localized.name AS language_name,
  conference_room.conference_room,
  event.start_time + conference.day_change AS "time",
  conference_day.conference_day + event.start_time + conference.day_change::interval AS start_date,
  conference_day.conference_day + event.start_time + conference.day_change::interval + event.duration AS end_date,
  array_to_string(ARRAY(
    SELECT view_person.name
      FROM event_person
      INNER JOIN view_person USING (person_id)
      WHERE
        event_person.event_role IN ('speaker','moderator') AND
        event_person.event_role_state = 'confirmed' AND
        event_person.event_id = event.event_id), ','::text) AS speakers
FROM event
  INNER JOIN event_state_localized USING (event_state)
  INNER JOIN conference USING (conference_id)
  INNER JOIN conference_room ON (
      event.conference_room_id = conference_room.conference_room_id AND
      conference_room.public = 't' )
  INNER JOIN conference_day ON (
      event.conference_day_id = conference_day.conference_day_id AND
      conference_day.public = 't' )
  LEFT OUTER JOIN language_localized USING (language,translated)
WHERE
  event.public IS TRUE AND
  event.start_time IS NOT NULL AND
  event.event_state = 'accepted' AND
  event.event_state_progress = 'confirmed'
;

