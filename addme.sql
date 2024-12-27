CREATE TABLE `garagelocations` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(50) NOT NULL,
    `label` varchar(200) NOT NULL,
    `type` varchar(50) NOT NULL,
    `restriction` varchar(50) DEFAULT NULL,
    `blipcoords` varchar(150) DEFAULT NULL,
	`zonepoints` longtext DEFAULT NULL,
    `thickness` int(11) DEFAULT 15,
    `parkinglocations` longtext DEFAULT NULL,
    `vehicleCategories` longtext DEFAULT NULL,

	PRIMARY KEY (`id`) USING BTREE
)
COLLATE='utf8mb4_general_ci' ENGINE=InnoDB AUTO_INCREMENT=1;

ALTER TABLE `garagelocations`
ADD COLUMN `spawner` longtext DEFAULT NULL;