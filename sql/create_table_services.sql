CREATE TABLE services (
   service_id INT PRIMARY KEY NOT NULL,
   updated INTEGER UNSIGNED NOT NULL,
   sort_order INT NOT NULL,
   area VARCHAR(100) NOT NULL,
   route VARCHAR(200) NOT NULL,
   status INT NOT NULL,
   disruption_reason VARCHAR(50),
   disruption_date INTEGER UNSIGNED,
   disruption_details TEXT,
   additional_info TEXT
);
