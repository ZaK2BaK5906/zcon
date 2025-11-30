-- Taxi Job Database Setup

-- Create taxi job
INSERT INTO `jobs` (`name`, `label`) VALUES
('taxi', 'Taxi')
ON DUPLICATE KEY UPDATE `label` = 'Taxi';

-- Create taxi job grades
INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES
('taxi', 0, 'chauffeur', 'Chauffeur', 500, '{}', '{}'),
('taxi', 1, 'gerant', 'Gérant', 750, '{}', '{}'),
('taxi', 2, 'boss', 'Boss', 1000, '{}', '{}')
ON DUPLICATE KEY UPDATE 
    `name` = VALUES(`name`),
    `label` = VALUES(`label`),
    `salary` = VALUES(`salary`);

-- Add society account
INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES
('society_taxi', 'Taxi', 1)
ON DUPLICATE KEY UPDATE `label` = 'Taxi', `shared` = 1;

-- Initialize society account data (starting balance: 0)
INSERT INTO `addon_account_data` (`account_name`, `money`, `owner`) VALUES
('society_taxi', 0, NULL)
ON DUPLICATE KEY UPDATE `account_name` = 'society_taxi';
