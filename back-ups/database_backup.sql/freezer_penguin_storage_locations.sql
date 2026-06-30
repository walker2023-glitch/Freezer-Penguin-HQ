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
-- Table structure for table `storage_locations`
--

DROP TABLE IF EXISTS `storage_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `storage_locations` (
  `location_id` int NOT NULL AUTO_INCREMENT,
  `location_name` varchar(50) NOT NULL,
  `user_id` int NOT NULL,
  PRIMARY KEY (`location_id`,`user_id`),
  KEY `fk_storage_locations_Users1_idx` (`user_id`),
  CONSTRAINT `fk_storage_locations_Users1` FOREIGN KEY (`user_id`) REFERENCES `Users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=55 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `storage_locations`
--

LOCK TABLES `storage_locations` WRITE;
/*!40000 ALTER TABLE `storage_locations` DISABLE KEYS */;
INSERT INTO `storage_locations` VALUES (1,'Kitchen Freezer',1),(1,'Aisle 1 - Shelf A',10),(2,'Garage Deep Freeze',1),(2,'Aisle 1 - Shelf B',10),(3,'Aisle 2 - Shelf A',10),(4,'Aisle 2 - Shelf B',10),(5,'Main Walk-in Freezer',10),(6,'Front Display Rack',10),(7,'Bakery Display',10),(8,'Endcap 1',10),(9,'Endcap 2',10),(10,'Manager Office Holding',10),(11,'Backroom Overstock Cage A',10),(12,'Backroom Overstock Cage B',10),(13,'Loading Dock Bay 1',10),(14,'Loading Dock Bay 2',10),(15,'Dairy Cooler Section 1',10),(16,'Dairy Cooler Section 2',10),(17,'Meat Locker Hook Area',10),(18,'Pharmacy Fridge Temp-A',10),(19,'Pharmacy Fridge Temp-B',10),(20,'Customer Service Desk Drawer',10),(21,'Aisle 3 - Hazmat Locker',10),(22,'Aisle 4 - Bulk Pallets',10),(23,'Outside Garden Center Tent',10),(24,'Front Register 1 Under-counter',10),(25,'Front Register 2 Under-counter',10),(30,'Aisle 1 - Shelf A',10),(31,'Aisle 1 - Shelf B',10),(32,'Aisle 2 - Shelf A',10),(33,'Aisle 2 - Shelf B',10),(34,'Main Walk-in Freezer',10),(35,'Front Display Rack',10),(36,'Bakery Display',10),(37,'Endcap 1',10),(38,'Endcap 2',10),(39,'Manager Office Holding',10),(40,'Backroom Overstock Cage A',10),(41,'Backroom Overstock Cage B',10),(42,'Loading Dock Bay 1',10),(43,'Loading Dock Bay 2',10),(44,'Dairy Cooler Section 1',10),(45,'Dairy Cooler Section 2',10),(46,'Meat Locker Hook Area',10),(47,'Pharmacy Fridge Temp-A',10),(48,'Pharmacy Fridge Temp-B',10),(49,'Customer Service Desk Drawer',10),(50,'Aisle 3 - Hazmat Locker',10),(51,'Aisle 4 - Bulk Pallets',10),(52,'Outside Garden Center Tent',10),(53,'Front Register 1 Under-counter',10),(54,'Front Register 2 Under-counter',10);
/*!40000 ALTER TABLE `storage_locations` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-06-24 18:12:03
