-- This is an example schema.
-- You can change the id types, indices or add columns as long as you keep these columns the same:
--  domains.name
--  users.email
--  users.password_hash
--  users.send_only
--  users.active
--  aliases.source
--  aliases.destination
--
-- Or you know what you're doing ;)

CREATE TABLE domains (
    id serial PRIMARY KEY,
    name varchar(255) NOT NULL UNIQUE
);

CREATE TABLE users (
    id serial PRIMARY KEY,
    domain_id integer NOT NULL REFERENCES domains(id),
    email varchar(255) NOT NULL UNIQUE,
    password_hash varchar(255) NOT NULL,
    send_only boolean NOT NULL DEFAULT false,
    active boolean NOT NULL DEFAULT true
);

CREATE TABLE aliases (
    id serial PRIMARY KEY,
    domain_id integer NOT NULL REFERENCES domains(id),
    source varchar(255) NOT NULL,
    destination varchar(255) NOT NULL
);

CREATE INDEX ON aliases(source);
