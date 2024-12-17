create database display;
\c display

create extension postgres_fdw;

create server storage
foreign data wrapper postgres_fdw
options (
    dbname 'storage'
);

create user mapping
for postgres
server storage
options (
    user 'postgres'
);

create schema storage;

import foreign schema public
from server storage
into storage;

create table branches (
    id bigint not null primary key,
    name text not null
);

create table weeks (
    id bigserial primary key,
    start timestamptz not null unique
);

create table sale_totals (
    id bigserial primary key,
    week_id bigint not null,
    branch_id bigint not null,
    total integer not null,
    unique(week_id, branch_id)
);

alter table sale_totals
    add constraint sale_totals_week_id_fk foreign key (week_id) references weeks (id),
    add constraint sale_totals_branch_id_fk foreign key (branch_id) references branches (id);
