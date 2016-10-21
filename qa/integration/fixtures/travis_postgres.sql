CREATE TABLE EMPLOYEES(
   ID  SERIAL PRIMARY KEY,
   NAME           TEXT      NOT NULL,
   AGE            INT       NOT NULL,
   CITY           TEXT,
   TITLE          TEXT,
   JOIN_DATE      DATE
);

INSERT INTO EMPLOYEES (NAME, AGE, CITY, TITLE, JOIN_DATE) VALUES
    ('John', 100, 'San Francisco', 'Engineer', '2014-02-10'),
    ('Jane', 101, 'San Jose', 'CTO', '2015-02-10'),
    ('Jack', 102, 'Mobile', 'Engineer', '2016-02-10');
