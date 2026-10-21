CREATE SCHEMA spendwise AUTHORIZATION spendwise_admin;

GRANT USAGE ON SCHEMA spendwise TO spendwise_admin, spendwise_user;

GRANT CREATE ON SCHEMA spendwise TO spendwise_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA spendwise
GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO spendwise_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA spendwise
    GRANT SELECT,INSERT,UPDATE,TRIGGER ON TABLES TO spendwise_admin;
