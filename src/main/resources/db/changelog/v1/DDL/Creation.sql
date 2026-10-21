--liquibase formatted sql
--changeset LD:create-user-table failOnError:true

CREATE TABLE system_code
(
    code         VARCHAR   NOT NULL,
    category     VARCHAR   NOT NULL,
    description  VARCHAR   NOT NULL,
    version_from INT       NOT NULL,
    version_to   INT       NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL,
    created_by   VARCHAR   NOT NULL,
    modified_at  TIMESTAMPTZ  NOT NULL,
    modified_by  VARCHAR   NOT NULL,
    PRIMARY KEY (code, category)
);

CREATE TABLE users
(
    user_id       uuid DEFAULT gen_random_uuid(),
    email_id      VARCHAR   NOT NULL,
    display_name  VARCHAR   NOT NULL,
    password      VARCHAR   NOT NULL,
    mobile_number VARCHAR   NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL,
    created_by    VARCHAR   NOT NULL,
    modified_at   TIMESTAMPTZ  NOT NULL,
    modified_by   VARCHAR   NOT NULL,
    is_deleted    CHAR DEFAULT 'N',
    PRIMARY KEY (user_id)
);

CREATE TABLE accounts
(
    account_id   uuid DEFAULT gen_random_uuid(),
    user_id      uuid    NOT NULL,
    account_name VARCHAR   NOT NULL,
    account_type VARCHAR   NOT NULL,
    description  VARCHAR   NULL,
    created_at   TIMESTAMPTZ  NOT NULL,
    created_by   VARCHAR   NOT NULL,
    modified_at  TIMESTAMPTZ  NOT NULL,
    modified_by  VARCHAR   NOT NULL,
    is_deleted   CHAR DEFAULT 'N',
    PRIMARY KEY (account_id),
    FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE counter_parties
(
    counter_party_id uuid DEFAULT gen_random_uuid(),
    user_id          uuid  NOT NULL,
    name             VARCHAR NOT NULL,
    email_id         VARCHAR NULL,
    mobile_number    VARCHAR NULL,
    PRIMARY KEY (counter_party_id),
    FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE bank_accounts
(
    account_id      uuid DEFAULT gen_random_uuid(),
    account_balance NUMERIC(19, 4) NOT NULL,
    created_at      TIMESTAMPTZ       NOT NULL,
    created_by      VARCHAR        NOT NULL,
    modified_at     TIMESTAMPTZ       NOT NULL,
    modified_by     VARCHAR        NOT NULL,
    is_deleted      CHAR DEFAULT 'N',
    PRIMARY KEY (account_id),
    FOREIGN KEY (account_id) REFERENCES accounts (account_id)
);

CREATE TABLE credit_cards
(
    account_id           uuid DEFAULT gen_random_uuid(),
    card_limit           NUMERIC(19, 4) NOT NULL,
    card_utilized        NUMERIC(19, 4) NOT NULL,
    billing_day_of_month INT            NOT NULL,
    payment_due_day      INT            NOT NULL,
    created_at           TIMESTAMPTZ       NOT NULL,
    created_by           VARCHAR        NOT NULL,
    modified_at          TIMESTAMPTZ       NOT NULL,
    modified_by          VARCHAR        NOT NULL,
    is_deleted           CHAR DEFAULT 'N',
    PRIMARY KEY (account_id),
    FOREIGN KEY (account_id) REFERENCES accounts (account_id)
);

CREATE TABLE transaction
(
    transaction_id uuid DEFAULT gen_random_uuid(),
    user_id        uuid    NOT NULL,
    description    VARCHAR   NULL,
    category       VARCHAR   NOT NULL,
    note           VARCHAR   NULL,
    created_at     TIMESTAMPTZ  NOT NULL,
    created_by     VARCHAR   NOT NULL,
    modified_at    TIMESTAMPTZ  NOT NULL,
    modified_by    VARCHAR   NOT NULL,
    is_deleted     CHAR DEFAULT 'N',
    PRIMARY KEY (transaction_id),
    FOREIGN KEY (user_id) REFERENCES users (user_id)
);

CREATE TABLE transaction_ledger
(
    ledger_id           uuid DEFAULT gen_random_uuid(),
    transaction_id      uuid         NOT NULL,
    sender_account_id   uuid         NOT NULL,
    receiver_account_id uuid         NOT NULL,
    entry_type          VARCHAR        NOT NULL,
    amount              NUMERIC(19, 4) NOT NULL,
    currency            VARCHAR        NOT NULL,
    created_at          TIMESTAMPTZ       NOT NULL,
    created_by          VARCHAR        NOT NULL,
    modified_at         TIMESTAMPTZ       NOT NULL,
    modified_by         VARCHAR        NOT NULL,
    is_deleted          CHAR DEFAULT 'N',
    PRIMARY KEY (ledger_id),
    FOREIGN KEY (transaction_id) REFERENCES transaction (transaction_id),
    FOREIGN KEY (sender_account_id) REFERENCES accounts (account_id),
    FOREIGN KEY (receiver_account_id) REFERENCES accounts (account_id)
);

CREATE TABLE refresh_tokens
(
    user_id                uuid,
    refresh_token          VARCHAR NOT NULL,
    previous_refresh_token VARCHAR NOT NULL,
    PRIMARY KEY (user_id),
    FOREIGN KEY (user_id) REFERENCES users (user_id)
);

-- Primary keys are already indexed. PostgreSQL does NOT auto-index foreign keys,
-- so those are covered first, followed by lookup/query-pattern indexes.

-- ---------- users ----------
-- Login lookup + uniqueness among non-deleted users
CREATE UNIQUE INDEX uq_users_email_active
    ON users (LOWER(email_id)) WHERE is_deleted = 'N';

CREATE UNIQUE INDEX uq_users_mobile_active
    ON users (mobile_number) WHERE is_deleted = 'N';

-- ---------- accounts ----------
CREATE INDEX idx_accounts_user_id
    ON accounts (user_id, account_type) WHERE is_deleted = 'N';

-- ---------- counter_parties ----------
CREATE INDEX idx_counter_parties_user_id
    ON counter_parties (user_id, name);

-- ---------- transaction ----------
-- "My recent transactions" and per-category filtering
CREATE INDEX idx_transaction_user_created
    ON transaction (user_id, created_at DESC) WHERE is_deleted = 'N';

CREATE INDEX idx_transaction_user_category
    ON transaction (user_id, category) WHERE is_deleted = 'N';

-- ---------- transaction_ledger ----------
CREATE INDEX idx_ledger_transaction_id
    ON transaction_ledger (transaction_id);

CREATE INDEX idx_ledger_sender_created
    ON transaction_ledger (sender_account_id, created_at DESC) WHERE is_deleted = 'N';

CREATE INDEX idx_ledger_receiver_created
    ON transaction_ledger (receiver_account_id, created_at DESC) WHERE is_deleted = 'N';

-- ---------- refresh_tokens ----------
-- Token lookup on refresh, and reuse detection via previous token
CREATE INDEX idx_refresh_tokens_token
    ON refresh_tokens (refresh_token);

CREATE INDEX idx_refresh_tokens_previous_token
    ON refresh_tokens (previous_refresh_token);

-- ---------- system_code ----------
-- PK is (code, category); this supports lookups by category and version range
CREATE INDEX idx_system_code_category_version
    ON system_code (category, version_from, version_to);
