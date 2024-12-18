\c storage

create or replace function fetch_new(branch branches)
returns void as $func$
begin
    perform set_config('search_path', branch.name, true);

    with dels as (
        delete from deleted_items
        returning *
    ), updates as (
        select *, null deleted_at
        from items
        where
            case
            when branch.last_fetched_at is null
            then true
            else modified_at > branch.last_fetched_at
            end
        union all
        select * from dels
    ), new_items as (
        insert into public.items (
            branch_id,
            local_id,
            guid
        )
        select branch.id, id, guid
        from updates
        on conflict do nothing
        returning id, local_id
    ), link as (
        select id, local_id from new_items
        union all
        select i.id, i.local_id from updates u
        join public.items i on i.branch_id = branch.id and i.local_id = u.id
    )
    insert into public.item_states (
        item_id,
        deleted_at,
        modified_at,
        name,
        price
    )
    select
        l.id,
        deleted_at,
        modified_at,
        name,
        price
    from updates u
    join link l on u.id = l.local_id;

    with dels as (
        delete from deleted_categories
        returning *
    ), updates as (
        select *, null deleted_at
        from categories
        where
            case
            when branch.last_fetched_at is null
            then true
            else modified_at > branch.last_fetched_at
            end
        union all
        select * from dels
    ), new_categories as (
        insert into public.categories (
            branch_id,
            local_id,
            guid
        )
        select branch.id, id, guid
        from updates
        on conflict do nothing
        returning id, local_id
    ), link as (
        select id, local_id from new_categories
        union all
        select c.id, c.local_id from updates u
        join public.categories c on c.branch_id = branch.id and c.local_id = u.id
    )
    insert into public.category_states (
        category_id,
        deleted_at,
        modified_at,
        name
    )
    select
        l.id,
        deleted_at,
        modified_at,
        name
    from updates u
    join link l on u.id = l.local_id;

    with dels as (
        delete from deleted_item_categories
        returning *
    ), updates as (
        select *, null deleted_at
        from item_categories
        where
            case
            when branch.last_fetched_at is null
            then true
            else modified_at > branch.last_fetched_at
            end
        union all
        select * from dels
    ), new_item_categories as (
        insert into public.item_categories (
            branch_id,
            local_id,
            guid
        )
        select branch.id, id, guid
        from updates
        on conflict do nothing
        returning id, local_id
    ), link as (
        select id, local_id from new_item_categories
        union all
        select ic.id, ic.local_id from updates u
        join public.item_categories ic on ic.branch_id = branch.id and ic.local_id = u.id
    )
    insert into public.item_category_states (
        item_category_id,
        deleted_at,
        modified_at,
        item_id,
        category_id
    )
    select
        l.id,
        deleted_at,
        modified_at,
        i.id,
        c.id
    from updates u
    join link l on u.id = l.local_id
    join public.items i on i.branch_id = branch.id and i.local_id = u.item_id
    join public.categories c on c.branch_id = branch.id and c.local_id = u.category_id;

    with dels as (
        delete from deleted_buyers
        returning *
    ), updates as (
        select *, null deleted_at
        from buyers
        where
            case
            when branch.last_fetched_at is null
            then true
            else modified_at > branch.last_fetched_at
            end
        union all
        select * from dels
    ), new_buyers as (
        insert into public.buyers (
            branch_id,
            local_id,
            guid
        )
        select branch.id, id, guid
        from updates
        on conflict do nothing
        returning id, local_id
    ), link as (
        select id, local_id from new_buyers
        union all
        select b.id, b.local_id from updates u
        join public.buyers b on b.branch_id = branch.id and b.local_id = u.id
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

    with dels as (
        delete from deleted_sales
        returning *
    ), updates as (
        select *, null deleted_at
        from sales
        where
            case
            when branch.last_fetched_at is null
            then true
            else modified_at > branch.last_fetched_at
            end
        union all
        select * from dels
    ), new_sales as (
        insert into public.sales (
            branch_id,
            local_id,
            guid
        )
        select branch.id, id, guid
        from updates
        on conflict do nothing
        returning id, local_id
    ), link as (
        select id, local_id from new_sales
        union all
        select s.id, s.local_id from updates u
        join public.sales s on s.branch_id = branch.id and s.local_id = u.id
    )
    insert into public.sale_states (
        sale_id,
        deleted_at,
        modified_at,
        created_at,
        finalized_at,
        buyer_id,
        total
    )
    select
        l.id,
        deleted_at,
        modified_at,
        created_at,
        finalized_at,
        b.id,
        total
    from updates u
    join link l on u.id = l.local_id
    join public.buyers b on b.branch_id = branch.id and b.local_id = u.buyer_id;

    with dels as (
        delete from deleted_sale_items
        returning *
    ), updates as (
        select *, null deleted_at
        from sale_items
        where
            case
            when branch.last_fetched_at is null
            then true
            else modified_at > branch.last_fetched_at
            end
        union all
        select * from dels
    ), new_sale_items as (
        insert into public.sale_items (
            branch_id,
            local_id,
            guid
        )
        select branch.id, id, guid
        from updates
        on conflict do nothing
        returning id, local_id
    ), link as (
        select id, local_id from new_sale_items
        union all
        select si.id, si.local_id from updates u
        join public.sale_items si on si.branch_id = branch.id and si.local_id = u.id
    )
    insert into public.sale_item_states (
        sale_item_id,
        deleted_at,
        modified_at,
        sale_id,
        item_id,
        count,
        price
    )
    select
        l.id,
        deleted_at,
        modified_at,
        s.id,
        i.id,
        count,
        price
    from updates u
    join link l on l.local_id = u.id
    join public.sales s on s.branch_id = branch.id and s.local_id = u.sale_id
    join public.items i on i.branch_id = branch.id and i.local_id = u.item_id;

    update public.branches
    set last_fetched_at = now()
    where id = branch.id;
end;
$func$ language 'plpgsql';
