CREATE TABLE IF NOT EXISTS `rex_ranch_animals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ranchid` varchar(50) DEFAULT NULL,
  `animalid` varchar(50) DEFAULT NULL,
  `model` varchar(50) NOT NULL,
  `pos_x` float NOT NULL,
  `pos_y` float NOT NULL,
  `pos_z` float NOT NULL,
  `pos_w` float NOT NULL,
  `age` int(11) DEFAULT 0,
  `health` int(11) DEFAULT 100,
  `thirst` int(11) DEFAULT 100,
  `hunger` int(11) DEFAULT 100,
  `born` INT UNSIGNED NOT NULL,
  `scale` float DEFAULT 0.5,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
