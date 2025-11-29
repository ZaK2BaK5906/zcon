-- ESX Concess Job Database
-- Run this SQL file in your database

-- Table for vehicle stock
CREATE TABLE IF NOT EXISTS `concess_stock` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle_model` varchar(50) NOT NULL,
  `vehicle_name` varchar(100) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `buy_price` int(11) NOT NULL,
  `sell_price` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicle_model` (`vehicle_model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table for orders
CREATE TABLE IF NOT EXISTS `concess_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle_model` varchar(50) NOT NULL,
  `vehicle_name` varchar(100) NOT NULL,
  `quantity` int(11) NOT NULL,
  `total_price` int(11) NOT NULL,
  `status` enum('pending','in_progress','completed','cancelled') NOT NULL DEFAULT 'pending',
  `ordered_by` varchar(60) NOT NULL,
  `ordered_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Add job to jobs table (if not exists)
INSERT INTO `jobs` (`name`, `label`) VALUES ('concess', 'Concessionnaire')
ON DUPLICATE KEY UPDATE `label` = 'Concessionnaire';

-- Add job grades
INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('concess', 0, 'employee', 'Employé', 250, '{}', '{}'),
('concess', 1, 'manager', 'Gérant', 450, '{}', '{}'),
('concess', 2, 'boss', 'Patron', 750, '{}', '{}')
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `label` = VALUES(`label`),
    `salary` = VALUES(`salary`);

-- Add society account
INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
('society_concess', 'Concessionnaire', 1)
ON DUPLICATE KEY UPDATE `label` = 'Concessionnaire', `shared` = 1;

-- Initialize society account data (starting balance: 0)
INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES
('society_concess', 0, NULL)
ON DUPLICATE KEY UPDATE `account_name` = 'society_concess';
