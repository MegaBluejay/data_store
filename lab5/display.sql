\c display

insert into branches (id, name)
select id, name
from storage.branches
on conflict do nothing;

insert into weeks (start)
select start
from generate_series(date_trunc('week', :'start'::timestamptz), date_trunc('week', :'end'::timestamptz), '1 week'::interval) starts(start)
on conflict do nothing;

insert into sale_totals (
    week_id,
    branch_id,
    total
)
select
    w.id,
    b.id,
    coalesce(gs.total, 0)
from generate_series(date_trunc('week', :'start'::timestamptz), date_trunc('week', :'end'::timestamptz), '1 week'::interval) starts(start)
join weeks w on w.start = starts.start
cross join branches b
left join (
    select
        s.branch_id,
        date_bin('1 week'::interval, ss.finalized_at, date_trunc('week', :'start'::timestamptz)) start,
        sum(ss.total) total
    from storage.sale_states ss
    join storage.sales s on s.id = ss.sale_id
    where
        date_trunc('week', :'start'::timestamptz) <= ss.finalized_at
        and
        ss.finalized_at < date_trunc('week', :'end'::timestamptz)
        and
        deleted_at is null
    group by 1, 2
) gs on gs.branch_id = b.id and gs.start = w.start
on conflict (week_id, branch_id) do update
set total = excluded.total;
