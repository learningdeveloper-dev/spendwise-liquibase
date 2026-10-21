CREATE ROLE spendwise_admin WITH LOGIN PASSWORD '<change_me>';
CREATE ROLE spendwise_user WITH LOGIN PASSWORD '<change_me>';

CREATE DATABASE spendwise_db OWNER spendwise_admin;

GRANT CONNECT ON DATABASE spendwise_db TO  spendwise_admin, spendwise_user;
GRANT CREATE ON DATABASE spendwise_db TO spendwise_admin;
GRANT CREATE