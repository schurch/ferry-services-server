CREATE TABLE vessels (
   mmsi INT PRIMARY KEY NOT NULL,
   updated DATETIME NOT NULL,
   name VARCHAR(50) NOT NULL,
   location POINT NOT NULL,
   speed DOUBLE NULL,
   course DOUBLE NULL,
   status INT NULL
);
