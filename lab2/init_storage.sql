create database storage;
\c storage

create table branches (
    id bigserial primary key,
    name text not null unique,
    last_fetched_at timestamptz
);


create table items (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

create table item_states (
    id bigserial primary key,
    item_id bigint not null,
    fetched_at timestamptz not null default now(),
    modified_at timestamptz not null,
    name text not null,
    price integer not null
);

create table categories (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

create table category_states (
    id bigserial primary key,
    category_id bigint not null,
    fetched_at timestamptz not null default now(),
    modified_at timestamptz not null,
    name text not null
);

create table item_categories (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

create table item_category_states (
    id bigserial primary key,
    item_category_id bigint not null,
    fetched_at timestamptz not null default now(),
    modified_at timestamptz not null,
    item_id bigint not null,
    category_id bigint not null
);

create table buyers (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

create table buyer_states (
    id bigserial primary key,
    buyer_id bigint not null,
    fetched_at timestamptz not null default now(),
    modified_at timestamptz not null not null
);

create table sales (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

create table sale_states (
    id bigserial primary key,
    sale_state_id bigint not null,
    fetched_at timestamptz not null default now(),
    modified_at timestamptz not null,
    created_at timestamptz not null,
    finalized_at timestamptz,
    buyer_id bigint not null,
    total integer not null
);

create table sale_items (
    id bigserial primary key,
    branch_id bigint not null,
    local_id bigint not null,
    guid uuid not null,
    unique(branch_id, local_id)
);

create table sale_item_states (
    id bigserial primary key,
    sale_item_id bigint not null,
    fetched_at timestamptz not null default now(),
    modified_at timestamptz not null,
    sale_id bigint not null,
    item_id bigint not null,
    count integer not null,
    price integer not null
);