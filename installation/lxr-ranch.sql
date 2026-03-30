-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 LXR-RANCH — The Land of Wolves — Database Schema
-- ═══════════════════════════════════════════════════════════════════════════════
-- Developer   : iBoss21 | Brand : The Lux Empire
-- https://www.wolves.land | https://discord.gg/CrKcWdfd3A
-- © 2026 iBoss21 / The Lux Empire — All Rights Reserved
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 1: lxr_ranches — Ranch ownership, tiers, condition, upgrades, tax
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `lxr_ranches` (
    `id`                INT(11)             NOT NULL AUTO_INCREMENT,
    `ranchid`           VARCHAR(50)         NOT NULL,
    `owner_citizenid`   VARCHAR(50)         DEFAULT NULL,
    `name`              VARCHAR(100)        NOT NULL,
    `tier`              TINYINT(3) UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Ranch tier 1-5',
    `condition_score`   TINYINT(3) UNSIGNED NOT NULL DEFAULT 100 COMMENT 'Overall condition 0-100',
    `upgrades`          JSON                DEFAULT NULL COMMENT 'JSON object of purchased upgrades',
    `tax_status`        ENUM('current','due','overdue','locked','exempt') NOT NULL DEFAULT 'current',
    `tax_balance`       DECIMAL(12,2)       NOT NULL DEFAULT 0.00,
    `tax_due_date`      INT(10) UNSIGNED    DEFAULT 0,
    `last_tax_paid`     INT(10) UNSIGNED    DEFAULT 0,
    `total_invested`    DECIMAL(12,2)       NOT NULL DEFAULT 0.00 COMMENT 'Total money invested in ranch',
    `max_animals`       SMALLINT(5) UNSIGNED NOT NULL DEFAULT 10,
    `max_staff`         SMALLINT(5) UNSIGNED NOT NULL DEFAULT 20,
    `created_at`        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_ranchid` (`ranchid`),
    KEY `idx_owner` (`owner_citizenid`),
    KEY `idx_tax_status` (`tax_status`),
    KEY `idx_tier` (`tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 2: lxr_ranch_animals — Expanded animal records with cleanliness,
--          stress, genetics, species tracking, and lineage
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `lxr_ranch_animals` (
    `id`                    INT(11)             NOT NULL AUTO_INCREMENT,
    `ranchid`               VARCHAR(50)         DEFAULT NULL,
    `animalid`              VARCHAR(50)         DEFAULT NULL,
    `model`                 VARCHAR(50)         NOT NULL,
    `species`               VARCHAR(50)         DEFAULT NULL COMMENT 'cattle, chicken, turkey, sheep, goat, pig',
    `pos_x`                 FLOAT               NOT NULL,
    `pos_y`                 FLOAT               NOT NULL,
    `pos_z`                 FLOAT               NOT NULL,
    `pos_w`                 FLOAT               NOT NULL,
    `age`                   SMALLINT(5) UNSIGNED DEFAULT 0,
    `health`                TINYINT(3) UNSIGNED DEFAULT 100,
    `thirst`                TINYINT(3) UNSIGNED DEFAULT 100,
    `hunger`                TINYINT(3) UNSIGNED DEFAULT 100,
    `cleanliness`           TINYINT(3) UNSIGNED DEFAULT 100 COMMENT 'Cleanliness stat 0-100',
    `stress`                TINYINT(3) UNSIGNED DEFAULT 0 COMMENT 'Stress level 0-100 (lower is better)',
    `born`                  INT(10) UNSIGNED    NOT NULL,
    `scale`                 DECIMAL(4,2)        DEFAULT 0.50,
    `last_production`       INT(10) UNSIGNED    DEFAULT 0,
    `product_ready`         TINYINT(1)          DEFAULT 0,
    `gender`                ENUM('male','female') DEFAULT 'female',
    `pregnant`              TINYINT(1)          DEFAULT 0,
    `gestation_end_time`    INT(10) UNSIGNED    DEFAULT NULL,
    `breeding_ready_time`   INT(10) UNSIGNED    DEFAULT 0,
    `breeding_attempts`     INT(10) UNSIGNED    DEFAULT 0,
    `mother_id`             VARCHAR(50)         DEFAULT NULL,
    `father_id`             VARCHAR(50)         DEFAULT NULL,
    `genetics_json`         JSON                DEFAULT NULL COMMENT 'productionGene, healthGene, growthGene (0.0-1.0)',
    `is_alive`              TINYINT(1)          NOT NULL DEFAULT 1,
    `death_time`            INT(10) UNSIGNED    DEFAULT NULL,
    `created_at`            TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`            TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_animalid` (`animalid`),
    KEY `idx_ranchid` (`ranchid`),
    KEY `idx_species` (`species`),
    KEY `idx_product_ready` (`product_ready`),
    KEY `idx_ranchid_product` (`ranchid`, `product_ready`),
    KEY `idx_pregnant` (`pregnant`),
    KEY `idx_gender` (`gender`),
    KEY `idx_breeding_ready` (`breeding_ready_time`),
    KEY `idx_mother_id` (`mother_id`),
    KEY `idx_father_id` (`father_id`),
    KEY `idx_is_alive` (`is_alive`),
    KEY `idx_ranchid_alive` (`ranchid`, `is_alive`),
    KEY `idx_cleanliness` (`cleanliness`),
    KEY `idx_stress` (`stress`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 3: lxr_ranch_permissions — Player access control per ranch
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `lxr_ranch_permissions` (
    `id`                INT(11)         NOT NULL AUTO_INCREMENT,
    `ranchid`           VARCHAR(50)     NOT NULL,
    `citizenid`         VARCHAR(50)     NOT NULL,
    `role`              ENUM('owner','manager','ranchhand','trainee') NOT NULL DEFAULT 'trainee',
    `hired_by`          VARCHAR(50)     DEFAULT NULL,
    `permissions_json`  JSON            DEFAULT NULL COMMENT 'Custom permission overrides',
    `hired_at`          TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_ranch_citizen` (`ranchid`, `citizenid`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_ranchid` (`ranchid`),
    KEY `idx_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 4: lxr_ranch_storage — Per-ranch inventory storage
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `lxr_ranch_storage` (
    `id`            INT(11)             NOT NULL AUTO_INCREMENT,
    `ranchid`       VARCHAR(50)         NOT NULL,
    `item_name`     VARCHAR(100)        NOT NULL,
    `item_label`    VARCHAR(100)        DEFAULT NULL,
    `amount`        INT(11)             NOT NULL DEFAULT 0,
    `metadata`      JSON                DEFAULT NULL,
    `slot`          SMALLINT(5) UNSIGNED DEFAULT NULL,
    `weight`        INT(11)             NOT NULL DEFAULT 0,
    `created_at`    TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ranchid` (`ranchid`),
    KEY `idx_item_name` (`item_name`),
    KEY `idx_ranchid_item` (`ranchid`, `item_name`),
    KEY `idx_ranchid_slot` (`ranchid`, `slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 5: lxr_ranch_transactions — Economy audit trail
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `lxr_ranch_transactions` (
    `id`                INT(11)         NOT NULL AUTO_INCREMENT,
    `ranchid`           VARCHAR(50)     NOT NULL,
    `citizenid`         VARCHAR(50)     NOT NULL,
    `transaction_type`  ENUM('purchase','sale','tax','salary','penalty','refund','transfer','production','upgrade') NOT NULL,
    `item_or_subject`   VARCHAR(200)    DEFAULT NULL,
    `amount`            DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    `balance_after`     DECIMAL(12,2)   DEFAULT NULL,
    `quantity`          INT(11)         DEFAULT 1,
    `notes`             VARCHAR(255)    DEFAULT NULL,
    `created_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ranchid` (`ranchid`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_transaction_type` (`transaction_type`),
    KEY `idx_ranchid_type` (`ranchid`, `transaction_type`),
    KEY `idx_created_at` (`created_at`),
    KEY `idx_ranchid_date` (`ranchid`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE 6: lxr_ranch_tax_records — Tax payment history
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS `lxr_ranch_tax_records` (
    `id`                INT(11)         NOT NULL AUTO_INCREMENT,
    `ranchid`           VARCHAR(50)     NOT NULL,
    `citizenid`         VARCHAR(50)     NOT NULL,
    `tax_period_start`  INT(10) UNSIGNED NOT NULL,
    `tax_period_end`    INT(10) UNSIGNED NOT NULL,
    `amount_due`        DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    `amount_paid`       DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    `penalty_amount`    DECIMAL(12,2)   NOT NULL DEFAULT 0.00,
    `status`            ENUM('pending','paid','partial','overdue','waived') NOT NULL DEFAULT 'pending',
    `due_date`          INT(10) UNSIGNED NOT NULL,
    `paid_date`         INT(10) UNSIGNED DEFAULT NULL,
    `notes`             VARCHAR(255)    DEFAULT NULL,
    `created_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_ranchid` (`ranchid`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_status` (`status`),
    KEY `idx_ranchid_status` (`ranchid`, `status`),
    KEY `idx_due_date` (`due_date`),
    KEY `idx_ranchid_period` (`ranchid`, `tax_period_start`, `tax_period_end`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ─────────────────────────────────────────────────────────────────────────────
-- Seed ranch data for default locations
-- ─────────────────────────────────────────────────────────────────────────────

INSERT IGNORE INTO `lxr_ranches` (`ranchid`, `name`, `tier`, `condition_score`, `tax_status`, `created_at`) VALUES
('macfarranch',     'Macfarlane Ranch',     1, 100, 'current', CURRENT_TIMESTAMP),
('emeraldranch',    'Emerald Ranch',        1, 100, 'current', CURRENT_TIMESTAMP),
('pronghornranch',  'Pronghorn Ranch',      1, 100, 'current', CURRENT_TIMESTAMP),
('downesranch',     'Downes Ranch',         1, 100, 'current', CURRENT_TIMESTAMP),
('hillhavenranch',  'Hill Haven Ranch',     1, 100, 'current', CURRENT_TIMESTAMP),
('hangingdogranch', 'Hanging Dog Ranch',    1, 100, 'current', CURRENT_TIMESTAMP);

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🐺 LXR-RANCH — wolves.land — End of Schema
-- ═══════════════════════════════════════════════════════════════════════════════
