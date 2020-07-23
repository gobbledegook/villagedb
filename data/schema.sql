-- phpMyAdmin SQL Dump
-- version 4.8.5
-- https://www.phpmyadmin.net/
--
-- Generation Time: Jul 17, 2020 at 11:53 PM
-- Server version: 5.7.28-log
-- PHP Version: 7.1.22

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `villagedb`
--

-- --------------------------------------------------------

--
-- Table structure for table `Area`
--

CREATE TABLE `Area` (
  `ID` smallint(4) UNSIGNED NOT NULL,
  `Up_ID` tinyint(2) UNSIGNED NOT NULL DEFAULT '0',
  `Num` tinyint(3) UNSIGNED NOT NULL DEFAULT '0',
  `Name` varchar(50) CHARACTER SET utf8mb4 DEFAULT NULL,
  `Name_ROM` varchar(150) DEFAULT NULL,
  `Name_PY` varchar(150) DEFAULT NULL,
  `Name_JP` varchar(150) DEFAULT NULL,
  `Name_STC` varchar(100) DEFAULT NULL,
  `latlon` varchar(21) DEFAULT NULL,
  `Date_Created` datetime DEFAULT NULL,
  `Date_Modified` datetime DEFAULT NULL,
  `Created_By` varchar(20) DEFAULT NULL,
  `Flag` tinyint(3) UNSIGNED NOT NULL DEFAULT '0',
  `FlagNote` varchar(1000) CHARACTER SET utf8mb4 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `County`
--

CREATE TABLE `County` (
  `ID` tinyint(2) UNSIGNED NOT NULL,
  `Name` varchar(50) CHARACTER SET utf8mb4 NOT NULL,
  `Name_ROM` varchar(150) NOT NULL DEFAULT '',
  `Name_PY` varchar(150) NOT NULL DEFAULT '',
  `Name_JP` varchar(150) NOT NULL DEFAULT '',
  `Name_STC` varchar(100) NOT NULL DEFAULT '',
  `Date_Created` datetime DEFAULT NULL,
  `Date_Modified` datetime DEFAULT NULL,
  `Created_By` varchar(20) DEFAULT NULL,
  `Flag` tinyint(3) UNSIGNED NOT NULL DEFAULT '0',
  `FlagNote` varchar(1000) CHARACTER SET utf8mb4 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `Heung`
--

CREATE TABLE `Heung` (
  `ID` smallint(5) UNSIGNED NOT NULL,
  `Up_ID` smallint(4) UNSIGNED NOT NULL DEFAULT '0',
  `Name` varchar(50) CHARACTER SET utf8mb4 NOT NULL,
  `Name_ROM` varchar(150) NOT NULL DEFAULT '',
  `Name_PY` varchar(150) NOT NULL DEFAULT '',
  `Name_JP` varchar(150) NOT NULL DEFAULT '',
  `Name_STC` varchar(100) NOT NULL DEFAULT '',
  `Markets` varchar(50) CHARACTER SET utf8mb4 NOT NULL,
  `Markets_ROM` varchar(150) NOT NULL DEFAULT '',
  `Markets_PY` varchar(150) NOT NULL DEFAULT '',
  `Markets_JP` varchar(150) NOT NULL DEFAULT '',
  `Markets_STC` varchar(100) NOT NULL DEFAULT '',
  `Map_Location` varchar(7) DEFAULT NULL,
  `latlon` varchar(21) CHARACTER SET ascii NOT NULL,
  `Date_Created` datetime DEFAULT NULL,
  `Date_Modified` datetime DEFAULT NULL,
  `Created_By` varchar(20) DEFAULT NULL,
  `Flag` tinyint(3) UNSIGNED NOT NULL DEFAULT '0',
  `FlagNote` varchar(1000) CHARACTER SET utf8mb4 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `Pingyam`
--

CREATE TABLE `Pingyam` (
  `Big5` varchar(1) CHARACTER SET utf8mb4 NOT NULL,
  `Pinyin` varchar(7) CHARACTER SET ascii NOT NULL DEFAULT '',
  `Readings_PY` tinyint(4) NOT NULL DEFAULT '0',
  `Jyutping` varchar(7) CHARACTER SET ascii NOT NULL,
  `Readings_JP` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `roms`
--

CREATE TABLE `roms` (
  `pkey` smallint(4) UNSIGNED NOT NULL,
  `b5` varchar(1) CHARACTER SET utf8mb4 NOT NULL,
  `rom` varchar(8) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `STC`
--

CREATE TABLE `STC` (
  `STC_Code` char(4) CHARACTER SET ascii NOT NULL DEFAULT '',
  `Big5` varchar(1) CHARACTER SET utf8mb4 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `Subheung`
--

CREATE TABLE `Subheung` (
  `ID` smallint(5) UNSIGNED NOT NULL,
  `Up_ID` smallint(5) UNSIGNED NOT NULL DEFAULT '0',
  `Name` varchar(50) CHARACTER SET utf8mb4 NOT NULL,
  `Name_ROM` varchar(150) NOT NULL DEFAULT '',
  `Name_PY` varchar(150) NOT NULL DEFAULT '',
  `Name_JP` varchar(150) NOT NULL DEFAULT '',
  `Name_STC` varchar(100) NOT NULL DEFAULT '',
  `Date_Created` datetime DEFAULT NULL,
  `Date_Modified` datetime DEFAULT NULL,
  `Created_By` varchar(20) DEFAULT NULL,
  `Flag` tinyint(3) UNSIGNED NOT NULL DEFAULT '0',
  `FlagNote` varchar(1000) CHARACTER SET utf8mb4 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `Subheung2`
--

CREATE TABLE `Subheung2` (
  `ID` smallint(5) UNSIGNED NOT NULL,
  `Up_ID` smallint(5) UNSIGNED NOT NULL DEFAULT '0',
  `Name` varchar(50) CHARACTER SET utf8mb4 NOT NULL,
  `Name_ROM` varchar(150) NOT NULL DEFAULT '',
  `Name_PY` varchar(150) NOT NULL DEFAULT '',
  `Name_JP` varchar(150) NOT NULL DEFAULT '',
  `Name_STC` varchar(100) NOT NULL DEFAULT '',
  `Date_Created` datetime DEFAULT NULL,
  `Date_Modified` datetime DEFAULT NULL,
  `Created_By` varchar(20) DEFAULT NULL,
  `Flag` tinyint(3) UNSIGNED NOT NULL DEFAULT '0',
  `FlagNote` varchar(1000) CHARACTER SET utf8mb4 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `surnames`
--

CREATE TABLE `surnames` (
  `b5` varchar(2) CHARACTER SET utf8mb4 NOT NULL,
  `roms` varchar(30) NOT NULL DEFAULT '0',
  `py` varchar(15) NOT NULL DEFAULT '',
  `jp` varchar(15) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `surnames_index`
--

CREATE TABLE `surnames_index` (
  `pkey` mediumint(6) UNSIGNED NOT NULL,
  `b5` varchar(2) CHARACTER SET utf8mb4 NOT NULL,
  `village_id` mediumint(6) UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `User`
--

CREATE TABLE `User` (
  `username` varchar(20) NOT NULL DEFAULT '',
  `pwd` varchar(60) DEFAULT NULL,
  `fullname` varchar(60) NOT NULL DEFAULT '',
  `email` varchar(60) NOT NULL DEFAULT '',
  `lastlogin` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

-- --------------------------------------------------------

--
-- Table structure for table `Village`
--

CREATE TABLE `Village` (
  `ID` mediumint(6) UNSIGNED NOT NULL,
  `Name` varchar(50) CHARACTER SET utf8mb4 NOT NULL,
  `Name_ROM` varchar(150) NOT NULL DEFAULT '',
  `Name_PY` varchar(150) NOT NULL DEFAULT '',
  `Name_JP` varchar(150) NOT NULL DEFAULT '',
  `Name_STC` varchar(100) NOT NULL DEFAULT '',
  `Surnames` varchar(80) CHARACTER SET utf8mb4 NOT NULL,
  `Surnames_ROM` varchar(250) NOT NULL DEFAULT '',
  `Surnames_PY` varchar(250) NOT NULL DEFAULT '',
  `Surnames_JP` varchar(250) NOT NULL DEFAULT '',
  `Surnames_STC` varchar(150) NOT NULL DEFAULT '',
  `Date_Created` datetime DEFAULT NULL,
  `Date_Modified` datetime DEFAULT NULL,
  `Created_By` varchar(20) DEFAULT NULL,
  `Flag` tinyint(3) UNSIGNED NOT NULL DEFAULT '0',
  `FlagNote` varchar(1000) CHARACTER SET utf8mb4 NOT NULL,
  `srcid` varchar(20) NOT NULL DEFAULT '',
  `Heung_ID` smallint(5) UNSIGNED NOT NULL DEFAULT '0',
  `Subheung_ID` smallint(5) UNSIGNED DEFAULT NULL,
  `Subheung2_ID` smallint(5) UNSIGNED DEFAULT NULL,
  `Village_ID` mediumint(6) UNSIGNED DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 PACK_KEYS=1;

--
-- Triggers `Village`
--
DELIMITER $$
CREATE TRIGGER `insert_heung_ids` BEFORE INSERT ON `Village` FOR EACH ROW BEGIN
IF new.Village_ID IS NOT NULL THEN
SET new.Heung_ID = (SELECT Heung_ID FROM Village WHERE ID=new.Village_ID);
SET new.Subheung_ID = (SELECT Subheung_ID FROM Village WHERE ID=new.Village_ID);
SET new.Subheung2_ID = (SELECT Subheung2_ID FROM Village WHERE ID=new.Village_ID);
ELSEIF new.Subheung_ID IS NOT NULL THEN
SET new.Heung_ID = (SELECT Up_ID FROM Subheung WHERE ID=new.Subheung_ID);
ELSEIF new.Subheung2_ID IS NOT NULL THEN
SET @hid = 0;
SET @sid = 0;
SELECT Subheung.Up_ID, Subheung.ID INTO @hid, @sid FROM Subheung JOIN Subheung2 ON Subheung.ID=Subheung2.Up_ID WHERE Subheung2.ID=new.Subheung2_ID;
SET new.Heung_ID=@hid;
SET new.Subheung_ID=@sid;
END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `village_insert` AFTER INSERT ON `Village` FOR EACH ROW BEGIN
SET @x = 0; # failsafe to prevent infinite loop in case something goes horribly wrong
SET @list = new.Surnames;
label1: LOOP
IF CHAR_LENGTH(@list) = 0 OR @x = 50 THEN LEAVE label1;
END IF;
SET @item = SUBSTRING_INDEX(@list, ',', 1);
SET @len = CHAR_LENGTH(@item);
SET @item = TRIM(@item);
INSERT INTO surnames_index (b5, village_id) VALUES (@item, new.ID);
SET @list = SUBSTRING(@list, @len+2);
SET @x = @x+1;
END LOOP;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `village_update` AFTER UPDATE ON `Village` FOR EACH ROW label0: BEGIN
IF old.Surnames = new.Surnames THEN LEAVE label0;
END IF;
DELETE FROM surnames_index WHERE village_id=old.ID;
SET @x = 0; # failsafe to prevent infinite loop in case something goes horribly wrong
SET @list = new.Surnames;
label1: LOOP
IF CHAR_LENGTH(@list) = 0 OR @x = 50 THEN LEAVE label1;
END IF;
SET @item = SUBSTRING_INDEX(@list, ',', 1);
SET @len = CHAR_LENGTH(@item);
SET @item = TRIM(@item);
INSERT INTO surnames_index (b5, village_id) VALUES (@item, new.ID);
SET @list = SUBSTRING(@list, @len+2);
SET @x = @x+1;
END LOOP;
END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Area`
--
ALTER TABLE `Area`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `Up_ID` (`Up_ID`);

--
-- Indexes for table `County`
--
ALTER TABLE `County`
  ADD PRIMARY KEY (`ID`);

--
-- Indexes for table `Heung`
--
ALTER TABLE `Heung`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `Up_ID` (`Up_ID`);

--
-- Indexes for table `Pingyam`
--
ALTER TABLE `Pingyam`
  ADD PRIMARY KEY (`Big5`);

--
-- Indexes for table `roms`
--
ALTER TABLE `roms`
  ADD PRIMARY KEY (`pkey`),
  ADD KEY `rom` (`rom`),
  ADD KEY `b5` (`b5`);

--
-- Indexes for table `STC`
--
ALTER TABLE `STC`
  ADD PRIMARY KEY (`STC_Code`),
  ADD KEY `Hant` (`Big5`);

--
-- Indexes for table `Subheung`
--
ALTER TABLE `Subheung`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `Up_ID` (`Up_ID`);

--
-- Indexes for table `Subheung2`
--
ALTER TABLE `Subheung2`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `Up_ID` (`Up_ID`) USING HASH;

--
-- Indexes for table `surnames`
--
ALTER TABLE `surnames`
  ADD PRIMARY KEY (`b5`) USING BTREE;

--
-- Indexes for table `surnames_index`
--
ALTER TABLE `surnames_index`
  ADD PRIMARY KEY (`pkey`),
  ADD KEY `village_id` (`village_id`),
  ADD KEY `surname` (`b5`) USING HASH;

--
-- Indexes for table `User`
--
ALTER TABLE `User`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `Village`
--
ALTER TABLE `Village`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `Name_ROM` (`Name_ROM`),
  ADD KEY `Name_PY` (`Name_PY`),
  ADD KEY `Heung_ID` (`Heung_ID`),
  ADD KEY `Subheung_ID` (`Subheung_ID`),
  ADD KEY `Subheung2_ID` (`Subheung2_ID`),
  ADD KEY `subvillage` (`Village_ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `Area`
--
ALTER TABLE `Area`
  MODIFY `ID` smallint(4) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `County`
--
ALTER TABLE `County`
  MODIFY `ID` tinyint(2) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Heung`
--
ALTER TABLE `Heung`
  MODIFY `ID` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `roms`
--
ALTER TABLE `roms`
  MODIFY `pkey` smallint(4) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Subheung`
--
ALTER TABLE `Subheung`
  MODIFY `ID` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Subheung2`
--
ALTER TABLE `Subheung2`
  MODIFY `ID` smallint(5) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `surnames_index`
--
ALTER TABLE `surnames_index`
  MODIFY `pkey` mediumint(6) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `Village`
--
ALTER TABLE `Village`
  MODIFY `ID` mediumint(6) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `Area`
--
ALTER TABLE `Area`
  ADD CONSTRAINT `Area_ibfk_1` FOREIGN KEY (`Up_ID`) REFERENCES `County` (`ID`) ON UPDATE CASCADE;

--
-- Constraints for table `Heung`
--
ALTER TABLE `Heung`
  ADD CONSTRAINT `Heung_ibfk_1` FOREIGN KEY (`Up_ID`) REFERENCES `Area` (`ID`) ON UPDATE CASCADE;

--
-- Constraints for table `Subheung`
--
ALTER TABLE `Subheung`
  ADD CONSTRAINT `Subheung_ibfk_1` FOREIGN KEY (`Up_ID`) REFERENCES `Heung` (`ID`) ON UPDATE CASCADE;

--
-- Constraints for table `Subheung2`
--
ALTER TABLE `Subheung2`
  ADD CONSTRAINT `Subheung2_ibfk_1` FOREIGN KEY (`Up_ID`) REFERENCES `Subheung` (`ID`) ON UPDATE CASCADE;

--
-- Constraints for table `surnames_index`
--
ALTER TABLE `surnames_index`
  ADD CONSTRAINT `surnames_index_ibfk_1` FOREIGN KEY (`village_id`) REFERENCES `Village` (`ID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Village`
--
ALTER TABLE `Village`
  ADD CONSTRAINT `Village_ibfk_1` FOREIGN KEY (`Heung_ID`) REFERENCES `Heung` (`ID`) ON UPDATE CASCADE,
  ADD CONSTRAINT `Village_ibfk_2` FOREIGN KEY (`Subheung_ID`) REFERENCES `Subheung` (`ID`) ON UPDATE CASCADE,
  ADD CONSTRAINT `Village_ibfk_3` FOREIGN KEY (`Subheung2_ID`) REFERENCES `Subheung2` (`ID`) ON UPDATE CASCADE,
  ADD CONSTRAINT `subvillage` FOREIGN KEY (`Village_ID`) REFERENCES `Village` (`ID`) ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
