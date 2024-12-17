\c storage

select restore(branches) from branches where name = :'branch';
select dblink_connect(:'branch', :'branch');
select * from dblink(:'branch', 'select public.reset_seqs()') x(reset_seqs text);
