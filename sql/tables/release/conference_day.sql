
CREATE TABLE release.conference_day (
  FOREIGN KEY (conference_release_id) REFERENCES conference_release ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (conference_release_id,conference_day)
) INHERITS( base.release, base.conference_day );

