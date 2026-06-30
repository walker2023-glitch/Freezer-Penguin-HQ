-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 100.81.95.123    Database: freezer_penguin
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `inventory_items`
--

DROP TABLE IF EXISTS `inventory_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_items` (
  `item_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `quantity` int DEFAULT NULL,
  `expiration_date` date NOT NULL,
  `UPC` varchar(15) DEFAULT NULL,
  `location_id` int NOT NULL,
  `unit_id` int NOT NULL,
  PRIMARY KEY (`item_id`,`user_id`,`unit_id`),
  KEY `fk_Inverntory Items_Users_idx` (`user_id`),
  KEY `fk_Inverntory Items_barcode_master1_idx` (`UPC`),
  KEY `fk_Inverntory Items_storage_locations1_idx` (`location_id`),
  KEY `fk_Inverntory Items_Units1_idx` (`unit_id`),
  CONSTRAINT `fk_Inverntory Items_barcode_master1` FOREIGN KEY (`UPC`) REFERENCES `barcode_master` (`UPC`),
  CONSTRAINT `fk_Inverntory Items_storage_locations1` FOREIGN KEY (`location_id`) REFERENCES `storage_locations` (`location_id`),
  CONSTRAINT `fk_Inverntory Items_Units1` FOREIGN KEY (`unit_id`) REFERENCES `Units` (`unit_id`),
  CONSTRAINT `fk_Inverntory Items_Users` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=504 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_items`
--

LOCK TABLES `inventory_items` WRITE;
/*!40000 ALTER TABLE `inventory_items` DISABLE KEYS */;
INSERT INTO `inventory_items` VALUES (3,1,1,'2026-06-15','012345678910',1,1),(4,1,1,'2026-06-15','012345678910',1,1),(5,1,1,'2026-06-15','040000000327',1,1),(6,1,1,'2026-06-15','077567254207',1,1),(7,1,1,'2026-06-08','999900000001',1,1),(8,1,1,'2026-06-08','999900000001',1,1),(9,1,1,'2026-06-08','999900000001',1,1),(10,1,1,'2026-06-08','999900000001',1,1),(11,1,1,'2026-06-09','999900000001',1,1),(12,1,2,'2026-07-10','041196910719',1,1),(13,1,1,'2026-06-15','077567254207',1,1),(14,1,1,'2026-06-15','077567254207',1,1),(15,1,1,'2026-06-15','077567254207',1,1);
/*!40000 ALTER TABLE `inventory_items` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-24 18:12:02
