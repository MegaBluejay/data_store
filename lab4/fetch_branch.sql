\c storage

insert into branches (name)
values (:'branch')
on conflict do nothing;

create extension if not exists postgres_fdw;

create server if not exists :"branch"
foreign data wrapper postgres_fdw
options (
    dbname :'branch'
);

create user mapping if not exists
for postgres
server :branch
options (
    user 'postgres'
);

drop schema if exists :"branch" cascade;
create schema :"branch";

import foreign schema public
from server :"branch"
into :"branch";


create or replace function fetch_new(branch public.branches)
returns void as $func$
begin
    execute format(
        $sql$
        with updates as (
            select *
            from %1$I.items
            where
                case
                when $2 is null
                then true
                else modified_at > $2
                end
        ), new_items as (
            insert into public.items (
                branch_id,
                local_id,
                guid
            )
            select $1, id, guid
            from updates
            on conflict do nothing
            returning id, local_id
        ), link as (
            select id, local_id from new_items
            union all
            select i.id, i.local_id from updates u
            join public.items i on i.branch_id = $1 and i.local_id = u.id
        )
        insert into public.item_states (
            item_id,
            modified_at,
            name,
            price
        )
        select
            l.id,
            modified_at,
            name,
            price
        from updates u
        join link l on u.id = l.local_id;

        with updates as (
            select *
            from %1$I.categories
            where
                case
                when $2 is null
                then true
                else modified_at > $2
                end
        ), new_categories as (
            insert into public.categories (
                branch_id,
                local_id,
                guid
            )
            select $1, id, guid
            from updates
            on conflict do nothing
            returning id, local_id
        ), link as (
            select id, local_id from new_categories
            union all
            select c.id, c.local_id from updates u
            join public.categories c on c.branch_id = $1 and c.local_id = u.id
        )
        insert into public.category_states (
            category_id,
            modified_at,
            name
        )
        select
            l.id,
            modified_at,
            name
        from updates u
        join link l on u.id = l.local_id;

        with updates as (
            select *
            from %1$I.item_categories
            where
                case
                when $2 is null
                then true
                else modified_at > $2
                end
        ), new_item_categories as (
            insert into public.item_categories (
                branch_id,
                local_id,
                guid
            )
            select $1, id, guid
            from updates
            on conflict do nothing
            returning id, local_id
        ), link as (
            select id, local_id from new_item_categories
            union all
            select ic.id, ic.local_id from updates u
            join public.item_categories ic on ic.branch_id = $1 and ic.local_id = u.id
        )
        insert into public.item_category_states (
            item_category_id,
            modified_at,
            item_id,
            category_id
        )
        select
            l.id,
            modified_at,
            i.id,
            c.id
        from updates u
        join link l on u.id = l.local_id
        join public.items i on i.branch_id = $1 and i.local_id = u.item_id
        join public.categories c on c.branch_id = $1 and c.local_id = u.category_id;

        with updates as (
            select *
            from %1$I.buyers
            where
                case
                when $2 is null
                then true
                else modified_at > $2
                end
        ), new_buyers as (
            insert into public.buyers (
                branch_id,
                local_id,
                guid
            )
            select $1, id, guid
            from updates
            on conflict do nothing
            returning id, local_id
        ), link as (
            select id, local_id from new_buyers
            union all
            select b.id, b.local_id from updates u
            join public.buyers b on b.branch_id = $1 and b.local_id = u.id
        )
        insert into public.buyer_states (
            buyer_id,
            modified_at
        )
        select
            l.id,
            modified_at
        from updates u
        join link l on u.id = l.local_id;

        with updates as (
            select *
            from %1$I.sales
            where
                case
                when $2 is null
                then true
                else modified_at > $2
                end
        ), new_sales as (
            insert into public.sales (
                branch_id,
                local_id,
                guid
            )
            select $1, id, guid
            from updates
            on conflict do nothing
            returning id, local_id
        ), link as (
            select id, local_id from new_sales
            union all
            select s.id, s.local_id from updates u
            join public.sales s on s.branch_id = $1 and s.local_id = u.id
        )
        insert into public.sale_states (
            sale_state_id,
            modified_at,
            created_at,
            finalized_at,
            buyer_id,
            total
        )
        select
            l.id,
            modified_at,
            created_at,
            finalized_at,
            b.id,
            total
        from updates u
        join link l on u.id = l.local_id
        join public.buyers b on b.branch_id = $1 and b.local_id = u.buyer_id;

        with updates as (
            select *
            from %1$I.sale_items
            where
                case
                when $2 is null
                then true
                else modified_at > $2
                end
        ), new_sale_items as (
            insert into public.sale_items (
                branch_id,
                local_id,
                guid
            )
            select $1, id, guid
            from updates
            on conflict do nothing
            returning id, local_id
        ), link as (
            select id, local_id from new_sale_items
            union all
            select si.id, si.local_id from updates u
            join public.sale_items si on si.branch_id = $1 and si.local_id = u.id
        )
        insert into public.sale_item_states (
            sale_item_id,
            modified_at,
            sale_id,
            item_id,
            count,
            price
        )
        select
            l.id,
            modified_at,
            s.id,
            i.id,
            count,
            price
        from updates u
        join link l on l.local_id = u.id
        join public.sales s on s.branch_id = $1 and s.local_id = u.sale_id
        join public.items i on i.branch_id = $1 and i.local_id = u.item_id;
        $sql$,
        branch.name
    ) using branch.id, branch.last_fetched_at;

    update public.branches
    set last_fetched_at = now()
    where id = branch.id;
end;
$func$ language 'plpgsql';

select fetch_new(branches) from branches where name = :'branch';
