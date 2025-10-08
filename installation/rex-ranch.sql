CREATE TABLE IF NOT EXISTS `rex_ranch_animals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranchid` varchar(50) DEFAULT NULL,
  `animalid` varchar(50) DEFAULT NULL,
  `model` varchar(50) NOT NULL,
  `pos_x` float NOT NULL,
  `pos_y` float NOT NULL,
  `pos_z` float NOT NULL,
  `pos_w` float NOT NULL,
  `health` int(11) DEFAULT 100,
  `born` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
