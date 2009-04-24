
CREATE TABLE base.mime_type_localized (
  mime_type TEXT NOT NULL,
  translated TEXT NOT NULL,
  name TEXT NOT NULL
);

CREATE TABLE mime_type_localized (
  FOREIGN KEY (mime_type) REFERENCES mime_type (mime_type) ON UPDATE CASCADE ON DELETE CASCADE,
  FOREIGN KEY (translated) REFERENCES language (language) ON UPDATE CASCADE ON DELETE CASCADE,
  PRIMARY KEY (mime_type, translated)
) INHERITS( base.mime_type_localized );

CREATE TABLE log.mime_type_localized (
) INHERITS( base.logging, base.mime_type_localized );

CREATE INDEX log_mime_type_localized_mime_type_idx ON log.mime_type_localized( mime_type );
CREATE INDEX log_mime_type_localized_log_transaction_id_idx ON log.mime_type_localized( log_transaction_id );

