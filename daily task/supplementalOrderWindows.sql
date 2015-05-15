
Begin; 

CREATE TABLE temp_sup_window_fix ( 
order_win_1 INTEGER, 
ow1_start_date timestamp with time zone,
order_win_2 INTEGER, 
ow2_start_date timestamp with time zone); 

select count(distinct ow2.id) as count_mismatch_start_dates from order_mngmt.order_windows ow1, order_mngmt.order_windows ow2, order_mngmt.test_windows tw1, order_mngmt.test_windows tw2 where ow1.parent_test_window_id = tw1.id and ow2.parent_test_window_id = tw2.id and tw1.org_id = tw2.org_id and tw1.track_id = tw2.track_id and tw1.test_prgm_id = 4 and tw2.test_prgm_id in (5,6,7) and ow1.start_date != ow2.start_date and ow1.order_type = 2 and ow2.order_type = 2;

INSERT into temp_sup_window_fix (select ow1.id, ow1.start_date, ow2.id, ow2.start_date from order_mngmt.order_windows ow1, order_mngmt.order_windows ow2, order_mngmt.test_windows tw1, order_mngmt.test_windows tw2 where ow1.parent_test_window_id = tw1.id and ow2.parent_test_window_id = tw2.id and tw1.org_id = tw2.org_id and tw1.track_id = tw2.track_id and tw1.test_prgm_id = 4 and tw2.test_prgm_id in (5,6,7) and ow1.start_date != ow2.start_date and ow1.order_type = 2 and ow2.order_type = 2); 

UPDATE order_mngmt.order_windows ow SET start_date = sub_fix.ow1_start_date from (select * from temp_sup_window_fix) as sub_fix where ow.id = sub_fix.order_win_2; 

select count(distinct ow2.id) from order_mngmt.order_windows ow1, order_mngmt.order_windows ow2, order_mngmt.test_windows tw1, order_mngmt.test_windows tw2 where ow1.parent_test_window_id = tw1.id and ow2.parent_test_window_id = tw2.id and tw1.org_id = tw2.org_id and tw1.track_id = tw2.track_id and tw1.test_prgm_id = 4 and tw2.test_prgm_id in (5,6,7) and ow1.start_date != ow2.start_date and ow1.order_type = 2 and ow2.order_type = 2; 

DROP TABLE temp_sup_window_fix;

CREATE TABLE temp_sup_window_fix ( 
order_win_1 INTEGER, 
ow1_end_date timestamp with time zone, 
order_win_2 INTEGER, 
ow2_end_date timestamp with time zone); 


select count(distinct ow2.id) as count_mismatch_end_dates from order_mngmt.order_windows ow1, order_mngmt.order_windows ow2, order_mngmt.test_windows tw1, order_mngmt.test_windows tw2 where ow1.parent_test_window_id = tw1.id and ow2.parent_test_window_id = tw2.id and tw1.org_id = tw2.org_id and tw1.track_id = tw2.track_id and tw1.test_prgm_id = 4 and tw2.test_prgm_id in (5,6,7) and ow1.end_date != ow2.end_date and ow1.order_type = 2 and ow2.order_type = 2;

INSERT into temp_sup_window_fix (select ow1.id, ow1.end_date, ow2.id, ow2.end_date from order_mngmt.order_windows ow1, order_mngmt.order_windows ow2, order_mngmt.test_windows tw1, order_mngmt.test_windows tw2 where ow1.parent_test_window_id = tw1.id and ow2.parent_test_window_id = tw2.id and tw1.org_id = tw2.org_id and tw1.track_id = tw2.track_id and tw1.test_prgm_id = 4 and tw2.test_prgm_id in (5,6,7) and ow1.end_date != ow2.end_date and ow1.order_type = 2 and ow2.order_type = 2); 

UPDATE order_mngmt.order_windows ow SET end_date = sub_fix.ow1_end_date from (select * from temp_sup_window_fix) as sub_fix where ow.id = sub_fix.order_win_2;

select count(distinct ow2.id) from order_mngmt.order_windows ow1, order_mngmt.order_windows ow2, order_mngmt.test_windows tw1, order_mngmt.test_windows tw2 where ow1.parent_test_window_id = tw1.id and ow2.parent_test_window_id = tw2.id and tw1.org_id = tw2.org_id and tw1.track_id = tw2.track_id and tw1.test_prgm_id = 4 and tw2.test_prgm_id in (5,6,7) and ow1.end_date != ow2.end_date and ow1.order_type = 2 and ow2.order_type = 2;

DROP TABLE temp_sup_window_fix; 

end;
