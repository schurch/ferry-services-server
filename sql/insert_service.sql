INSERT INTO services (service_id, updated, sort_order, area, route, status) VALUES (1, CURRENT_TIMESTAMP,1, 'Arran', 'Brodick - Ardrossan', 2);

INSERT INTO services (service_id, updated, sort_order, area, route, status, additional_info, disruption_reason, disruption_date, disruption_details) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE updated = ?, sort_order = ?, area = ?, route = ?, status = ?, additional_info = ?, disruption_reason = ?, disruption_date = ?, disruption_details = ?
