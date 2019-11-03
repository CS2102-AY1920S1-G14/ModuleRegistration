DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Admins CASCADE;
DROP TABLE IF EXISTS Students CASCADE;
DROP TABLE IF EXISTS Appeal CASCADE;
DROP TABLE IF EXISTS Rounds CASCADE;
DROP TABLE IF EXISTS Register CASCADE;
DROP TABLE IF EXISTS Takes CASCADE;
DROP TABLE IF EXISTS Programs CASCADE;
DROP TABLE IF EXISTS Require CASCADE;
DROP TABLE IF EXISTS LectureSlots CASCADE;
DROP TABLE IF EXISTS Modules CASCADE;
DROP TABLE IF EXISTS Prereq CASCADE;

CREATE TABLE Programs (
  prog_name    varchar(256) PRIMARY KEY
);

CREATE TABLE Users (
  username     varchar(8) PRIMARY KEY,
  password     varchar(256) NOT NULL,
  CHECK(username ~* '^[A-Za-z][0-9]+$'),
  CHECK(LENGTH(username) = 8)
);

CREATE TABLE Admins (
  a_username   varchar(8) PRIMARY KEY REFERENCES Users (username) ON DELETE CASCADE
);

CREATE TABLE Students (
  s_username     varchar(8) PRIMARY KEY REFERENCES Users (username) ON DELETE CASCADE,
  prog_name      varchar(256) DEFAULT 'Unspecified',
  seniority      integer NOT NULL,
  s_time_enroll  timestamp DEFAULT now(),
  CHECK(seniority >= 1 AND seniority<= 5),
  FOREIGN KEY (prog_name) REFERENCES Programs (prog_name)
);

CREATE OR REPLACE FUNCTION not_students() RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
BEGIN
SELECT COUNT(*) INTO count FROM Students WHERE NEW.a_username = Students.s_username;
  IF count > 0 THEN RETURN NULL; ELSE RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_admin
BEFORE INSERT OR UPDATE ON Admins
FOR EACH ROW EXECUTE PROCEDURE not_students();

CREATE OR REPLACE FUNCTION not_admins() RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
BEGIN
SELECT COUNT(*) INTO count FROM Admins WHERE NEW.s_username = Admins.a_username;
  IF count > 0 THEN RETURN NULL; ELSE RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_student
BEFORE INSERT OR UPDATE ON Students
FOR EACH ROW EXECUTE PROCEDURE not_admins();

CREATE TABLE Modules (
  mod_code     varchar(7) PRIMARY KEY,
  mod_name     varchar(256) NOT NULL UNIQUE,
  a_username   varchar(8) NOT NULL,
  FOREIGN KEY(a_username) REFERENCES Admins (a_username)
);

CREATE TABLE Require (
  prog_name   varchar(256) REFERENCES Programs (prog_name),
  mod_code    varchar(7) REFERENCES Modules (mod_code),
  PRIMARY KEY(prog_name, mod_code)
);

CREATE TABLE LectureSlots (
  day           varchar(9),
  s_time_lect   time,
  e_time_lect   time,
  sem          integer,
  mod_code      varchar(7),
  quota         integer NOT NULL,
  FOREIGN KEY(mod_code) REFERENCES Modules (mod_code) ON DELETE CASCADE,
  PRIMARY KEY(mod_code, sem, day, s_time_lect, e_time_lect),
  CHECK(sem = 1 OR sem = 2),
  CHECK(quota >= 0),
  CHECK(day IN('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'))
);

CREATE TABLE Rounds (
  s_time_round   timestamp NOT NULL,
  e_time_round   timestamp NOT NULL,
  CHECK(s_time_round < e_time_round),
  PRIMARY KEY(s_time_round, e_time_round)
);

CREATE TABLE Prereq (
  parent    varchar(256) REFERENCES Modules (mod_code),
  child     varchar(256) REFERENCES Modules (mod_code),
  PRIMARY KEY(parent, child)
);

CREATE TABLE Takes (
  grade         varchar(2) DEFAULT 'IP',
  has_completed boolean DEFAULT FALSE,
  s_username    varchar(8) REFERENCES Students (s_username),
  mod_code      varchar(7) REFERENCES Modules (mod_code),
  PRIMARY KEY(s_username, mod_code)
);

CREATE TABLE Appeal (
  status         varchar(14) NOT NULL,
  day            varchar(9) NOT NULL,
  mod_code       varchar(7),
  s_time_lect    time NOT NULL,
  e_time_lect    time NOT NULL,
  sem            integer NOT NULL,
  s_username     varchar(8) REFERENCES Students (s_username),
  FOREIGN KEY (mod_code, sem, day, s_time_lect, e_time_lect) REFERENCES LectureSlots (mod_code, sem, day, s_time_lect, e_time_lect) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY(s_username, mod_code, day, s_time_lect, e_time_lect, sem),
  CHECK (status IN ('Success', 'Fail', 'Appeal Pending'))
);

CREATE TABLE Register (
  rank_pref       integer NOT NULL,
  priority_score  integer DEFAULT 1,
  status          varchar(14) NOT NULL,
  s_username      varchar(8) NOT NULL,
  s_time_round    timestamp NOT NULL,
  e_time_round    timestamp NOT NULL,
  day           varchar(9),
  s_time_lect   time,
  e_time_lect   time,
  sem          integer,
  mod_code      varchar(7),
  FOREIGN KEY (s_username) REFERENCES Students (s_username),
  FOREIGN KEY (s_time_round, e_time_round) REFERENCES Rounds (s_time_round, e_time_round),
  FOREIGN KEY (mod_code, sem, day, s_time_lect, e_time_lect) REFERENCES LectureSlots (mod_code, sem, day, s_time_lect, e_time_lect) ON DELETE CASCADE ON UPDATE CASCADE,
  PRIMARY KEY (s_username, mod_code, s_time_round, e_time_round, day, s_time_lect, e_time_lect, sem),
  CHECK (status IN ('Success', 'Fail', 'Result Pending', 'Appeal Pending')),
  CHECK (rank_pref >= 0 AND rank_pref < 10)
);

INSERT INTO Programs VALUES ('Computer Science');
INSERT INTO Programs VALUES ('Information System');
INSERT INTO Programs VALUES ('Business Analytics');
INSERT INTO Programs VALUES ('Applied Math');
INSERT INTO Programs VALUES ('Statistics');

INSERT INTO Users VALUES ('e0191330', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191331', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191332', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191333', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191334', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191335', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191336', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191337', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191338', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0191339', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');
INSERT INTO Users VALUES ('e0134110', '$2a$10$nFsooiu47TjD8154OAEYwePNtGb4Rbh.GO0ti2mr6zWqLkenPjZUa');

INSERT INTO Admins VALUES ('e0191330');
INSERT INTO Admins VALUES ('e0134110');

INSERT INTO Students VALUES ('e0191331', 'Computer Science', 1, now());
INSERT INTO Students VALUES ('e0191332', 'Information System', 1, now());
INSERT INTO Students VALUES ('e0191333', 'Business Analytics', 1, now());
INSERT INTO Students VALUES ('e0191334', 'Applied Math', 1, now());
INSERT INTO Students VALUES ('e0191335', 'Computer Science', 2, now());
INSERT INTO Students VALUES ('e0191336', 'Information System', 2, now());
INSERT INTO Students VALUES ('e0191337', 'Computer Science', 3, now());
INSERT INTO Students VALUES ('e0191338', 'Applied Math', 3, now());
INSERT INTO Students VALUES ('e0191339', 'Statistics', 4, now());

INSERT INTO Modules VALUES ('CS1010', 'Programming Methodology', 'e0134110');
INSERT INTO Modules VALUES ('CS2102', 'Database Systems', 'e0134110');
INSERT INTO Modules VALUES ('CS2030', 'Programming Methodology II', 'e0134110');
INSERT INTO Modules VALUES ('CS2040', 'Data Structures and Algorithms', 'e0191330');
INSERT INTO Modules VALUES ('CS2103T', 'Software Engineering', 'e0191330');
INSERT INTO Modules VALUES ('CS1231', 'Discrete Structures', 'e0191330');
INSERT INTO Modules VALUES ('CS2106', 'Operating Systems', 'e0191330');
INSERT INTO Modules VALUES ('CS2105', 'Computer Networks', 'e0191330');
INSERT INTO Modules VALUES ('CS2100', 'Computer Organization', 'e0191330');
INSERT INTO Modules VALUES ('CS3219', 'Software Engineering Principles and Patterns', 'e0191330');
INSERT INTO Modules VALUES ('CS4218', 'Software Testing', 'e0191330');
INSERT INTO Modules VALUES ('IS2103', 'Enterprise Systems Server-side Design and Development', 'e0191330');
INSERT INTO Modules VALUES ('ACC1002', 'Financial Accounting', 'e0191330');
INSERT INTO Modules VALUES ('ACC3604', 'Corporate and Securities Law', 'e0191330');

INSERT INTO Prereq VALUES ('CS1010', 'CS2030');
INSERT INTO Prereq VALUES ('CS1010', 'CS2040');
INSERT INTO Prereq VALUES ('CS2030', 'CS2102');
INSERT INTO Prereq VALUES ('CS2040', 'CS2102');
INSERT INTO Prereq VALUES ('CS1231', 'CS2102');
INSERT INTO Prereq VALUES ('CS2030', 'CS2103T');
INSERT INTO Prereq VALUES ('CS2040', 'CS2103T');
INSERT INTO Prereq VALUES ('CS2100', 'CS2106');
INSERT INTO Prereq VALUES ('CS1010', 'CS2100');

INSERT INTO Require VALUES ('Computer Science', 'CS1010');
INSERT INTO Require VALUES ('Computer Science', 'CS2102');
INSERT INTO Require VALUES ('Computer Science', 'CS2030');
INSERT INTO Require VALUES ('Computer Science', 'CS2040');
INSERT INTO Require VALUES ('Information System', 'CS1010');
INSERT INTO Require VALUES ('Information System', 'CS2102');
INSERT INTO Require VALUES ('Business Analytics', 'CS1010');
INSERT INTO Require VALUES ('Business Analytics', 'CS2030');
INSERT INTO Require VALUES ('Business Analytics', 'CS2040');

INSERT INTO Rounds VALUES ('2016-06-22 19:10:25', '2016-06-23 19:10:25');
INSERT INTO Rounds VALUES ('2016-06-24 19:10:25', '2016-06-25 19:10:25');
INSERT INTO Rounds VALUES ('2016-06-27 19:10:25', '2016-06-28 19:10:25');
INSERT INTO Rounds VALUES ('2019-10-30 09:00:00', '2019-11-05 17:00:00');

INSERT INTO LectureSlots VALUES ('Monday', '10:00:00', '13:00:00', 1, 'CS1010', 5);--4 people bidding, n1, quota left 1
INSERT INTO LectureSlots VALUES ('Tuesday', '11:00:00', '14:00:00', 1, 'CS1010', 4);--4 people bidding, n2, quota left 0
INSERT INTO LectureSlots VALUES ('Wednesday', '11:00:00', '14:00:00', 2, 'CS1010', 5);--not current sem, n3, quota left 5
INSERT INTO LectureSlots VALUES ('Thursday', '13:00:00', '16:00:00', 1, 'CS2102', 4);--5 people bidding, n4, quota left 0
INSERT INTO LectureSlots VALUES ('Friday', '14:00:00', '17:00:00', 1, 'CS2102', 3);--0 people bidding, n5, quota left 3
INSERT INTO LectureSlots VALUES ('Monday', '15:00:00', '18:00:00', 2, 'CS2030', 4);--not current sem, n6, quota left 4
INSERT INTO LectureSlots VALUES ('Tuesday', '16:00:00', '19:00:00', 1, 'CS2030', 0); --2 people bidding, n7, quota left 0
INSERT INTO LectureSlots VALUES ('Wednesday', '16:00:00', '19:00:00', 1, 'CS2030', 2); --4 people bidding, n8, quota left 0
INSERT INTO LectureSlots VALUES ('Wednesday', '17:00:00', '20:00:00', 2, 'CS2040', 4);--not current sem n9, quota left 4
INSERT INTO LectureSlots VALUES ('Thursday', '18:00:00', '21:00:00', 1,'CS2040', 5);--not regulate by this admin n10, quota left 5

--n1
--score: 1*(10-2)*10=80, success
INSERT INTO Register VALUES (2, 1, 'Result Pending', 'e0191331', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Monday', '10:00:00', '13:00:00', 1, 'CS1010');
--not the current round, pending
INSERT INTO Register VALUES (2, 1, 'Result Pending', 'e0191331', '2016-06-24 19:10:25', '2016-06-25 19:10:25', 'Monday', '10:00:00', '13:00:00', 1, 'CS1010');
--score: 1* (10-1)*1 = 9, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191334', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Monday', '10:00:00', '13:00:00', 1, 'CS1010');
--score: 4* (10-1) *1 = 36, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191339', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Monday', '10:00:00', '13:00:00', 1, 'CS1010');
--score: 3* (10-8) *1 = 6, success
INSERT INTO Register VALUES (8, 1, 'Result Pending', 'e0191338', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Monday', '10:00:00', '13:00:00', 1, 'CS1010');

--n2
--not the current round,pending
INSERT INTO Register VALUES (8, 1, 'Result Pending', 'e0191338', '2016-06-24 19:10:25', '2016-06-25 19:10:25', 'Tuesday', '11:00:00', '14:00:00', 1, 'CS1010');
--score: 1*(10-1)*10 = 90, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191332', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Tuesday', '11:00:00', '14:00:00', 1, 'CS1010');
--score: 1*(10-3)*10 = 70, success
INSERT INTO Register VALUES (3, 1, 'Result Pending', 'e0191333', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Tuesday', '11:00:00', '14:00:00', 1, 'CS1010');
--score: 3*(10-2)*10 = 240, success
INSERT INTO Register VALUES (2, 1, 'Result Pending', 'e0191337', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Tuesday', '11:00:00', '14:00:00', 1, 'CS1010');
--score: 2*(10-4)*10 = 120, success
INSERT INTO Register VALUES (4, 1, 'Result Pending', 'e0191335', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Tuesday', '11:00:00', '14:00:00', 1, 'CS1010');

--n3
--not the current semester, pending
INSERT INTO Register VALUES (4, 1, 'Result Pending', 'e0191336', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Wednesday', '11:00:00', '14:00:00', 2, 'CS1010');

--n4
--score 1*(10-1)*10=90, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191331', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Thursday', '13:00:00', '16:00:00', 1, 'CS2102');
--score 1*(10-1)*1 = 9, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191334', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Thursday', '13:00:00', '16:00:00', 1, 'CS2102');
--score 4*(10-8)*1 = 8, fail
INSERT INTO Register VALUES (8, 1, 'Result Pending', 'e0191339', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Thursday', '13:00:00', '16:00:00', 1, 'CS2102');
--score 2*(10-1)*10=180, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191335', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Thursday', '13:00:00', '16:00:00', 1, 'CS2102');
--score 3*(10-1)*10=270, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191337', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Thursday', '13:00:00', '16:00:00', 1, 'CS2102');
--n5, no bidding
--n6, not current semester
INSERT INTO Register VALUES (4, 1, 'Result Pending', 'e0191333', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Monday', '15:00:00', '18:00:00', 2, 'CS2030');
--n7
--no quota, fail
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191335', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Tuesday', '16:00:00', '19:00:00', 1, 'CS2030');
--no quota, fail
INSERT INTO Register VALUES (2, 1, 'Result Pending', 'e0191332', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Tuesday', '16:00:00', '19:00:00', 1, 'CS2030');
--n8
--score 1*(10-1)*1 = 9, fail
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191334', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Wednesday', '16:00:00', '19:00:00', 1, 'CS2030');
--score 2*(10-1)*1 = 18, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191336', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Wednesday', '16:00:00', '19:00:00', 1, 'CS2030');
--score 3*(10-1)*10 = 270, success
INSERT INTO Register VALUES (1, 1, 'Result Pending', 'e0191337', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Wednesday', '16:00:00', '19:00:00', 1, 'CS2030');
--score 4*(10-9)*1 = 4, fail
INSERT INTO Register VALUES (9, 1, 'Result Pending', 'e0191339', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Wednesday', '16:00:00', '19:00:00', 1, 'CS2030');

--n9, not current sem, not regulated by this admin
INSERT INTO Register VALUES (4, 1, 'Result Pending', 'e0191331', '2016-06-22 19:10:25', '2016-06-23 19:10:25', 'Wednesday', '17:00:00', '20:00:00', 2, 'CS2040');
--n10, not regulate by this admin
INSERT INTO Register VALUES (4, 1, 'Result Pending', 'e0191332', '2016-06-22 19:10:25', '2016-06-23 19:10:25','Thursday', '18:00:00', '21:00:00', 1, 'CS2040');
INSERT INTO Register VALUES (4, 1, 'Result Pending', 'e0191333', '2019-10-30 09:00:00', '2019-11-05 17:00:00', 'Thursday', '18:00:00', '21:00:00', 1, 'CS2040');

-- check if student has alr bid the module and insert register
CREATE OR REPLACE FUNCTION not_register()
RETURNS TRIGGER AS $$
DECLARE count NUMERIC;
BEGIN
   SELECT COUNT(*) INTO count FROM Register R
   WHERE R.s_username = NEW.s_username AND R.sem = NEW.sem AND R.mod_code = NEW.mod_code;
   IF count > 0 THEN
       RETURN NULL;
   ELSE
       RETURN NEW;
   END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_register
BEFORE INSERT ON Register
FOR EACH ROW EXECUTE PROCEDURE not_register();

-- check if student is bidding a lecture slot that has no quota
CREATE OR REPLACE FUNCTION register_quota()
RETURNS TRIGGER AS $$
DECLARE number NUMERIC;
BEGIN
   SELECT quota INTO number FROM LectureSlots L
   WHERE L.mod_code = NEW.mod_code AND L.sem = NEW.sem AND L.s_time_lect = NEW.s_time_lect AND L.e_time_lect = NEW.e_time_lect AND L.day = NEW.day;
   IF number <= 0 THEN
       RETURN NULL;
   ELSE
       RETURN NEW;
   END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_quota
BEFORE INSERT ON Register
FOR EACH ROW EXECUTE PROCEDURE register_quota();