local Server = DDHunting.Server
local Bridge = Server.Bridge

local PersistenceService = {}
Server.Services.Persistence = PersistenceService

local function now()
    return os.time()
end

local function q(query, params)
    return Bridge.Database.Query(query, params or {})
end

local function single(query, params)
    return Bridge.Database.Single(query, params or {})
end

function PersistenceService.InitSchema()
    q([[CREATE TABLE IF NOT EXISTS dd_hunting_profiles (
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
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_skill_branches (
        identifier VARCHAR(80) NOT NULL,
        branch_key VARCHAR(40) NOT NULL,
        branch_rank INT NOT NULL DEFAULT 0,
        spent_points INT NOT NULL DEFAULT 0,
        updated_at BIGINT NOT NULL,
        PRIMARY KEY(identifier, branch_key),
        INDEX idx_branch_identifier(identifier)
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_species_mastery (
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
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_unlocks (
        identifier VARCHAR(80) NOT NULL,
        unlock_key VARCHAR(60) NOT NULL,
        unlocked_at BIGINT NOT NULL,
        meta_json LONGTEXT NULL,
        PRIMARY KEY(identifier, unlock_key),
        INDEX idx_unlock_identifier(identifier)
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_reputation (
        identifier VARCHAR(80) NOT NULL,
        rep_type VARCHAR(40) NOT NULL,
        rep_value INT NOT NULL DEFAULT 0,
        lifetime_gain INT NOT NULL DEFAULT 0,
        lifetime_loss INT NOT NULL DEFAULT 0,
        updated_at BIGINT NOT NULL,
        PRIMARY KEY(identifier, rep_type),
        INDEX idx_rep_identifier(identifier)
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_ranger_crimes (
        id BIGINT NOT NULL AUTO_INCREMENT,
        identifier VARCHAR(80) NOT NULL,
        crime_type VARCHAR(60) NOT NULL,
        heat_delta INT NOT NULL DEFAULT 0,
        metadata_json LONGTEXT NULL,
        created_at BIGINT NOT NULL,
        PRIMARY KEY(id),
        INDEX idx_crime_identifier(identifier),
        INDEX idx_crime_created(created_at)
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_active_contracts (
        identifier VARCHAR(80) NOT NULL,
        contract_id VARCHAR(64) NOT NULL,
        status VARCHAR(16) NOT NULL,
        expires_at BIGINT NOT NULL,
        contract_json LONGTEXT NOT NULL,
        updated_at BIGINT NOT NULL,
        PRIMARY KEY(identifier, contract_id),
        INDEX idx_active_contract_identifier(identifier)
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_contract_history (
        id BIGINT NOT NULL AUTO_INCREMENT,
        identifier VARCHAR(80) NOT NULL,
        contract_id VARCHAR(64) NOT NULL,
        status VARCHAR(16) NOT NULL,
        contract_json LONGTEXT NOT NULL,
        recorded_at BIGINT NOT NULL,
        PRIMARY KEY(id),
        INDEX idx_contract_history_identifier(identifier),
        INDEX idx_contract_history_status(status)
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_evidence (
        id BIGINT NOT NULL AUTO_INCREMENT,
        identifier VARCHAR(80) NOT NULL,
        evidence_type VARCHAR(64) NOT NULL,
        metadata_json LONGTEXT NULL,
        created_at BIGINT NOT NULL,
        PRIMARY KEY(id),
        INDEX idx_evidence_identifier(identifier)
    )]])

    q([[CREATE TABLE IF NOT EXISTS dd_hunting_enforcement_logs (
        id BIGINT NOT NULL AUTO_INCREMENT,
        identifier VARCHAR(80) NOT NULL,
        event_type VARCHAR(64) NOT NULL,
        alert_delta INT NOT NULL DEFAULT 0,
        total_alert INT NOT NULL DEFAULT 0,
        metadata_json LONGTEXT NULL,
        created_at BIGINT NOT NULL,
        PRIMARY KEY(id),
        INDEX idx_enforcement_identifier(identifier)
    )]])
end

function PersistenceService.LoadProfile(identifier)
    local row = single('SELECT * FROM dd_hunting_profiles WHERE identifier = ? LIMIT 1', { identifier })
    if row then
        return row
    end

    local ts = now()
    Bridge.Database.Insert([[INSERT INTO dd_hunting_profiles (identifier, created_at, updated_at) VALUES (?, ?, ?)]], {
        identifier, ts, ts,
    })

    return single('SELECT * FROM dd_hunting_profiles WHERE identifier = ? LIMIT 1', { identifier })
end

function PersistenceService.SaveProfile(identifier, profile)
    return Bridge.Database.Update([[
        UPDATE dd_hunting_profiles
        SET hunter_level = ?, hunter_xp = ?, unspent_skill_points = ?, current_title = ?,
            total_hunts = ?, total_clean_kills = ?, total_sales = ?, updated_at = ?
        WHERE identifier = ?
    ]], {
        profile.level,
        profile.xp,
        profile.skillPoints,
        profile.currentTitle,
        profile.totalHunts,
        profile.totalCleanKills,
        profile.totalSales,
        now(),
        identifier,
    })
end

function PersistenceService.LoadSkillBranches(identifier)
    return q('SELECT * FROM dd_hunting_skill_branches WHERE identifier = ?', { identifier }) or {}
end

function PersistenceService.SaveSkillBranch(identifier, branchKey, rank, spentPoints)
    return Bridge.Database.Update([[
        INSERT INTO dd_hunting_skill_branches (identifier, branch_key, branch_rank, spent_points, updated_at)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            branch_rank = VALUES(branch_rank),
            spent_points = VALUES(spent_points),
            updated_at = VALUES(updated_at)
    ]], { identifier, branchKey, rank, spentPoints or rank, now() })
end

function PersistenceService.LoadReputation(identifier)
    return q('SELECT * FROM dd_hunting_reputation WHERE identifier = ?', { identifier }) or {}
end

function PersistenceService.SaveReputation(identifier, repType, value, gain, loss)
    return Bridge.Database.Update([[
        INSERT INTO dd_hunting_reputation (identifier, rep_type, rep_value, lifetime_gain, lifetime_loss, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            rep_value = VALUES(rep_value),
            lifetime_gain = VALUES(lifetime_gain),
            lifetime_loss = VALUES(lifetime_loss),
            updated_at = VALUES(updated_at)
    ]], { identifier, repType, value, gain or 0, loss or 0, now() })
end

function PersistenceService.LoadSpeciesMastery(identifier)
    return q('SELECT * FROM dd_hunting_species_mastery WHERE identifier = ?', { identifier }) or {}
end

function PersistenceService.SaveSpeciesMastery(identifier, speciesKey, mastery)
    return Bridge.Database.Update([[
        INSERT INTO dd_hunting_species_mastery
            (identifier, species_key, kills, clean_kills, best_trophy, best_weight, variants_found_json, mastery_xp, mastery_rank, last_hunted_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            kills = VALUES(kills),
            clean_kills = VALUES(clean_kills),
            best_trophy = VALUES(best_trophy),
            best_weight = VALUES(best_weight),
            variants_found_json = VALUES(variants_found_json),
            mastery_xp = VALUES(mastery_xp),
            mastery_rank = VALUES(mastery_rank),
            last_hunted_at = VALUES(last_hunted_at),
            updated_at = VALUES(updated_at)
    ]], {
        identifier,
        speciesKey,
        mastery.kills,
        mastery.cleanKills,
        mastery.bestTrophy,
        mastery.bestWeight,
        json.encode(mastery.variantsFound or {}),
        mastery.masteryXP,
        mastery.masteryRank,
        mastery.lastHuntedAt,
        now(),
    })
end

function PersistenceService.LoadUnlocks(identifier)
    return q('SELECT * FROM dd_hunting_unlocks WHERE identifier = ?', { identifier }) or {}
end

function PersistenceService.SaveUnlock(identifier, unlockKey, metadata)
    return Bridge.Database.Update([[
        INSERT INTO dd_hunting_unlocks (identifier, unlock_key, unlocked_at, meta_json)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            unlocked_at = VALUES(unlocked_at),
            meta_json = VALUES(meta_json)
    ]], { identifier, unlockKey, now(), json.encode(metadata or {}) })
end

function PersistenceService.InsertCrime(identifier, crimeType, heatDelta, metadata)
    return Bridge.Database.Insert([[
        INSERT INTO dd_hunting_ranger_crimes (identifier, crime_type, heat_delta, metadata_json, created_at)
        VALUES (?, ?, ?, ?, ?)
    ]], { identifier, crimeType, heatDelta, json.encode(metadata or {}), now() })
end

function PersistenceService.UpsertActiveContract(identifier, contractId, status, expiresAt, contract)
    return Bridge.Database.Update([[
        INSERT INTO dd_hunting_active_contracts (identifier, contract_id, status, expires_at, contract_json, updated_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            status = VALUES(status),
            expires_at = VALUES(expires_at),
            contract_json = VALUES(contract_json),
            updated_at = VALUES(updated_at)
    ]], { identifier, contractId, status, expiresAt, json.encode(contract or {}), now() })
end

function PersistenceService.LoadActiveContracts(identifier)
    return q('SELECT * FROM dd_hunting_active_contracts WHERE identifier = ?', { identifier }) or {}
end

function PersistenceService.DeleteActiveContract(identifier, contractId)
    return Bridge.Database.Update('DELETE FROM dd_hunting_active_contracts WHERE identifier = ? AND contract_id = ?', {
        identifier, contractId,
    })
end

function PersistenceService.ArchiveContract(identifier, contractId, status, contract)
    return Bridge.Database.Insert([[
        INSERT INTO dd_hunting_contract_history (identifier, contract_id, status, contract_json, recorded_at)
        VALUES (?, ?, ?, ?, ?)
    ]], { identifier, contractId, status, json.encode(contract or {}), now() })
end

function PersistenceService.InsertEvidence(identifier, evidenceType, metadata)
    return Bridge.Database.Insert([[
        INSERT INTO dd_hunting_evidence (identifier, evidence_type, metadata_json, created_at)
        VALUES (?, ?, ?, ?)
    ]], { identifier, evidenceType, json.encode(metadata or {}), now() })
end

function PersistenceService.InsertEnforcementLog(identifier, eventType, alertDelta, totalAlert, metadata)
    return Bridge.Database.Insert([[
        INSERT INTO dd_hunting_enforcement_logs (identifier, event_type, alert_delta, total_alert, metadata_json, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { identifier, eventType, alertDelta, totalAlert, json.encode(metadata or {}), now() })
end
