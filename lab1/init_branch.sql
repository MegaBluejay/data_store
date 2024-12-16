create database :"branch";
\c :"branch"

create function update_modified_at()
returns trigger as $$
begin
    NEW.modified_at = now();
    return NEW;
end;
$$ language 'plpgsql';

create table items (
    id bigserial primary key,
    guid uuid not null default gen_random_uuid(),
    modified_at timestamptz not null default now(),
    name text not null,
    price integer not null
);

create trigger items_update_modified_at
    before update on items
    for each row
    execute function update_modified_at();

create index items_modified_at_idx on items (modified_at);

create table categories (
    id bigserial primary key,
    guid uuid not null default gen_random_uuid(),
    modified_at timestamptz not null default now(),
    name text not null
);

create trigger categories_update_modified_at
    before update on categories
    for each row
    execute function update_modified_at();

create index categories_modified_at_idx on categories (modified_at);

create table item_categories (
    id bigserial primary key,
    guid uuid not null default gen_random_uuid(),
    modified_at timestamptz not null default now(),
    item_id bigint not null,
    category_id bigint not null,
    unique(item_id, category_id)
);

create index item_categories_modified_at_idx on item_categories (modified_at);
create index item_categories_item_id_idx on item_categories (item_id);
create index item_categories_category_id_idx on item_categories (category_id);

alter table item_categories
    add constraint item_categories_item_id_fk foreign key (item_id) references items (id),
    add constraint item_categories_category_id_fk foreign key (category_id) references categories (id);

create table buyers (
    id bigserial primary key,
    guid uuid not null default gen_random_uuid(),
    modified_at timestamptz not null default now()
);

create trigger buyers_update_modified_at
    before update on buyers
    for each row
    execute function update_modified_at();

create index buyers_modified_at_idx on buyers (modified_at);

create table sales (
    id bigserial primary key,
    guid uuid not null default gen_random_uuid(),
    modified_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    finalized_at timestamptz,
    buyer_id bigint not null,
    total integer not null default 0
);

create trigger sales_update_modified_at
    before update on sales
    for each row
    execute function update_modified_at();

create index sales_modified_at_idx on sales (modified_at);
create index sales_buyer_id_idx on sales (buyer_id);

alter table sales
    add constraint sales_buyer_id_fk foreign key (buyer_id) references buyers (id);

create table sale_items (
    id bigserial primary key,
    guid uuid not null default gen_random_uuid(),
    modified_at timestamptz not null default now(),
    sale_id bigint not null,
    item_id bigint not null,
    count  integer not null default 1,
    price integer not null
);

create trigger sale_items_update_modified_at
    before update on sale_items
    for each row
    execute function update_modified_at();

create index sale_items_modified_at_idx on sale_items (modified_at);
create index sale_items_sale_id_idx on sale_items (sale_id);
create index sale_items_item_id_idx on sale_items (item_id);

alter table sale_items
    add constraint sale_items_sale_id_fk foreign key (sale_id) references sales (id),
    add constraint sale_items_item_id_fk foreign key (item_id) references items (id);

create function update_sale_total()
returns trigger as $$
begin
    if (TG_OP = 'DELETE') then
        update sales set total = total - (select sum(price * count) from old_table where sale_id = sales.id)
        where id in (select sale_id from old_table);
    elsif (TG_OP = 'UPDATE') then
        update sales set total = total - (select sum(price * count) from old_table where sale_id = sales.id) + (select sum(price * count) from new_table where sale_id = sales.id)
        where id in (select sale_id from old_table);
    elsif (TG_OP = 'INSERT') then
        update sales set total = total + (select sum(price) from new_table where sale_id = sales.id)
        where id in (select sale_id from new_table);
    end if;
    return null;
end;
$$ language 'plpgsql';

create trigger update_sale_total_ins
    after insert on sale_items
    referencing new table as new_table
    for each statement execute function update_sale_total();
create trigger update_sale_total_upd
    after update on sale_items
    referencing old table as old_table new table as new_table
    for each statement execute function update_sale_total();
create trigger update_sale_total_del
    after delete on sale_items
    referencing old table as old_table
    for each statement execute function update_sale_total();
