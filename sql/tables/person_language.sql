
CREATE TABLE base.person_language (
  person_id INTEGER NOT NULL,
  language TEXT NOT NULL,
  rank INTEGER
);

CREATE TABLE person_language (
  FOREIGN KEY (person_id) REFERENCES person (person_id) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (language) REFERENCES language (language) ON UPDATE CASCADE ON DELETE RESTRICT,
  PRIMARY KEY (person_id, language)
) INHERITS( base.person_language );

CREATE TABLE log.person_language (
) INHERITS( base.logging, base.person_language );

CREATE INDEX log_person_language_person_id_idx ON log.person_language( person_id );
CREATE INDEX log_person_language_log_transaction_id_idx ON log.person_language( log_transaction_id );

