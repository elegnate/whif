create DATABASE mid_db;
create user mid_u IDENTIFIED by "password";
grant all PRIVILEGES on mid_db.* to mid_u@localhost IDENTIFIED by "password";

CREATE TABLE u5er_t6
(
  devid     CHAR(32)    PRIMARY KEY,
  phone     CHAR(11)    NULL,
  humid     CHAR(64)    NULL,
  pw        CHAR(64)    NULL,
  name      VARCHAR(15) NULL,
  birth     CHAR(10)    NULL,
  reg_date  DATETIME    NULL,
  pieceHash CHAR(64)    NULL,
  piece     CHAR(64)    NULL,
  piecePw   TEXT        NULL,
  pubkey    TEXT        NULL,
  CONSTRAINT phone      UNIQUE (devid),
  CONSTRAINT humid      UNIQUE (humid)
);
