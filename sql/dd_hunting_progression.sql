CREATE TABLE IF NOT EXISTS dd_hunting_profiles (
    identifier VARCHAR(80) NOT NULL,
    hunter_level INT NOT NULL DEFAULT 1,
    hunter_xp INT NOT NULL DEFAULT 0,
    unspent_skill_points INT NOT NULL DEFAULT 0,
    current_title VARCHAR(64) NOT NULL DEFAULT 'Rookie Hunter',
    total_hunts INT NOT NULL DEFAULT 0,
    total_clean_kills INT NOT NULL DEFAULT 0,
    total_sales INT NOT NULL DEFAULT 0,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY(identifier)
);

CREATE TABLE IF NOT EXISTS dd_hunting_skill_branches (
    identifier VARCHAR(80) NOT NULL,
    branch_key VARCHAR(40) NOT NULL,
    branch_rank INT NOT NULL DEFAULT 0,
    spent_points INT NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY(identifier, branch_key),
    INDEX idx_branch_identifier(identifier)
);

CREATE TABLE IF NOT EXISTS dd_hunting_species_mastery (
    identifier VARCHAR(80) NOT NULL,
    species_key VARCHAR(40) NOT NULL,
    kills INT NOT NULL DEFAULT 0,
    clean_kills INT NOT NULL DEFAULT 0,
    best_trophy DECIMAL(10,2) NOT NULL DEFAULT 0,
    best_weight DECIMAL(10,2) NOT NULL DEFAULT 0,
    variants_found_json LONGTEXT NULL,
    mastery_xp INT NOT NULL DEFAULT 0,
    mastery_rank INT NOT NULL DEFAULT 0,
    last_hunted_at BIGINT NULL,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY(identifier, species_key),
    INDEX idx_mastery_identifier(identifier)
);

CREATE TABLE IF NOT EXISTS dd_hunting_unlocks (
    identifier VARCHAR(80) NOT NULL,
    unlock_key VARCHAR(60) NOT NULL,
    unlocked_at BIGINT NOT NULL,
    meta_json LONGTEXT NULL,
    PRIMARY KEY(identifier, unlock_key),
    INDEX idx_unlock_identifier(identifier)
);

CREATE TABLE IF NOT EXISTS dd_hunting_reputation (
    identifier VARCHAR(80) NOT NULL,
    rep_type VARCHAR(40) NOT NULL,
    rep_value INT NOT NULL DEFAULT 0,
    lifetime_gain INT NOT NULL DEFAULT 0,
    lifetime_loss INT NOT NULL DEFAULT 0,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY(identifier, rep_type),
    INDEX idx_rep_identifier(identifier)
);

CREATE TABLE IF NOT EXISTS dd_hunting_ranger_crimes (
    id BIGINT NOT NULL AUTO_INCREMENT,
    identifier VARCHAR(80) NOT NULL,
    crime_type VARCHAR(60) NOT NULL,
    heat_delta INT NOT NULL DEFAULT 0,
    metadata_json LONGTEXT NULL,
    created_at BIGINT NOT NULL,
    PRIMARY KEY(id),
    INDEX idx_crime_identifier(identifier),
    INDEX idx_crime_created(created_at)
);

CREATE TABLE IF NOT EXISTS dd_hunting_active_contracts (
    identifier VARCHAR(80) NOT NULL,
    contract_id VARCHAR(64) NOT NULL,
    status VARCHAR(16) NOT NULL,
    expires_at BIGINT NOT NULL,
    contract_json LONGTEXT NOT NULL,
    updated_at BIGINT NOT NULL,
    PRIMARY KEY(identifier, contract_id),
    INDEX idx_active_contract_identifier(identifier)
);

CREATE TABLE IF NOT EXISTS dd_hunting_contract_history (
    id BIGINT NOT NULL AUTO_INCREMENT,
    identifier VARCHAR(80) NOT NULL,
    contract_id VARCHAR(64) NOT NULL,
    status VARCHAR(16) NOT NULL,
    contract_json LONGTEXT NOT NULL,
    recorded_at BIGINT NOT NULL,
    PRIMARY KEY(id),
    INDEX idx_contract_history_identifier(identifier),
    INDEX idx_contract_history_status(status)
);

CREATE TABLE IF NOT EXISTS dd_hunting_evidence (
    id BIGINT NOT NULL AUTO_INCREMENT,
    identifier VARCHAR(80) NOT NULL,
    evidence_type VARCHAR(64) NOT NULL,
    metadata_json LONGTEXT NULL,
    created_at BIGINT NOT NULL,
    PRIMARY KEY(id),
    INDEX idx_evidence_identifier(identifier)
);

CREATE TABLE IF NOT EXISTS dd_hunting_enforcement_logs (
    id BIGINT NOT NULL AUTO_INCREMENT,
    identifier VARCHAR(80) NOT NULL,
    event_type VARCHAR(64) NOT NULL,
    alert_delta INT NOT NULL DEFAULT 0,
    total_alert INT NOT NULL DEFAULT 0,
    metadata_json LONGTEXT NULL,
    created_at BIGINT NOT NULL,
    PRIMARY KEY(id),
    INDEX idx_enforcement_identifier(identifier)
);
