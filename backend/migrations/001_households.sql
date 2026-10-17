-- Freezer Penguin 0.1 household foundation migration
-- Apply once against the existing MySQL database after taking a database backup.
-- This migration is additive and leaves inventory household_id nullable until
-- row counts and the backfill are verified.

CREATE TABLE IF NOT EXISTS households (
    household_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    created_by INT NOT NULL,
    created_at DATETIME NOT NULL,
    CONSTRAINT fk_households_created_by
        FOREIGN KEY (created_by) REFERENCES Users(user_id)
);

CREATE TABLE IF NOT EXISTS household_members (
    membership_id INT AUTO_INCREMENT PRIMARY KEY,
    household_id INT NOT NULL,
    user_id INT NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at DATETIME NOT NULL,
    revoked_at DATETIME NULL,
    CONSTRAINT uq_household_members_household_user UNIQUE (household_id, user_id),
    CONSTRAINT fk_household_members_household
        FOREIGN KEY (household_id) REFERENCES households(household_id),
    CONSTRAINT fk_household_members_user
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE IF NOT EXISTS household_invites (
    invite_id INT AUTO_INCREMENT PRIMARY KEY,
    household_id INT NOT NULL,
    created_by INT NOT NULL,
    invite_code_hash CHAR(64) NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    accepted_at DATETIME NULL,
    accepted_by INT NULL,
    created_at DATETIME NOT NULL,
    CONSTRAINT fk_household_invites_household
        FOREIGN KEY (household_id) REFERENCES households(household_id),
    CONSTRAINT fk_household_invites_creator
        FOREIGN KEY (created_by) REFERENCES Users(user_id),
    CONSTRAINT fk_household_invites_acceptor
        FOREIGN KEY (accepted_by) REFERENCES Users(user_id)
);

ALTER TABLE inventory_items
    ADD COLUMN household_id INT NULL,
    ADD INDEX ix_inventory_items_household_id (household_id),
    ADD CONSTRAINT fk_inventory_items_household
        FOREIGN KEY (household_id) REFERENCES households(household_id);

INSERT INTO households (name, created_by, created_at)
SELECT CONCAT('User ', u.user_id, '''s Household'), u.user_id, UTC_TIMESTAMP()
FROM Users u
LEFT JOIN households h ON h.created_by = u.user_id
WHERE h.household_id IS NULL;

INSERT INTO household_members (household_id, user_id, role, joined_at)
SELECT h.household_id, h.created_by, 'owner', UTC_TIMESTAMP()
FROM households h
LEFT JOIN household_members m
    ON m.household_id = h.household_id AND m.user_id = h.created_by
WHERE m.membership_id IS NULL;

UPDATE inventory_items i
JOIN households h ON h.created_by = i.user_id
SET i.household_id = h.household_id
WHERE i.household_id IS NULL;

-- Verify before making the column required:
-- SELECT COUNT(*) AS unassigned_inventory
-- FROM inventory_items
-- WHERE household_id IS NULL;
