-- Students whose enrollments are set to a window whose LEA is different from the student's LEA.
SELECT
	COUNT(DISTINCT se.student_id)
FROM
	order_mngmt.student_enrollments se, 
	order_mngmt.test_windows tw, 
	accounts.organizations sch,
	student.students s 
WHERE
	se.student_id = s.id 
	AND s.owner_org_id = sch.id 
	AND sch.parent_organization_id != tw.org_id
	AND se.test_window_id = tw.id 
	AND se.status = 't'
	AND s.enrolled = 't'
;

-- STUDENTS WHO HAVE ACTIVE ENROLLMENTS TO WINDOW 0
SELECT 
	COUNT(DISTINCT se.student_id)
FROM 
	order_mngmt.student_enrollments se
WHERE
	se.test_window_id=0
	AND se.status = 't'
;

-- WINDOW MISMATCHES FOR STUDENTS WITH SCHOOL TRACK
SELECT 
	COUNT(DISTINCT se.student_id)
FROM 
	order_mngmt.student_enrollments se, 
	order_mngmt.test_windows tw, 
	accounts.organizations sch,
	order_mngmt.org_track ot,
	student.students s 
WHERE
	se.student_id = s.id 
	AND s.owner_org_id = ot.school_org_id
	AND sch.id = ot.school_org_id
	AND sch.parent_organization_id = tw.org_id
	AND tw.track_id = ot.track_id
	AND tw.test_prgm_id = se.program_id
	AND se.test_window_id != tw.id 
	AND (s.stud_attribute->>'track') IS NULL
	AND se.status = 't'
	AND s.enrolled = 't'
;

-- WINDOW MISMATCHES FOR STUDENTS WITH INDIVIDUAL TRACK
SELECT 
	COUNT(DISTINCT se.student_id)
FROM 
	order_mngmt.student_enrollments se, 
	order_mngmt.test_windows tw, 
	accounts.organizations sch,
	student.students s 
WHERE
	se.student_id = s.id 
	AND sch.id = s.owner_org_id
	AND sch.parent_organization_id = tw.org_id
	AND 'ADMIN0' || tw.track_id = UPPER(s.stud_attribute->>'track')
	AND tw.test_prgm_id = se.program_id
	AND se.test_window_id != tw.id 
	AND (s.stud_attribute->>'track') IS NOT NULL
	AND se.status = 't'
	AND s.enrolled = 't'
;

-- STUDENT PBT ENROLLMENTS THAT ARE MISSING PAPER ENROLLMENTS
SELECT 
	COUNT(DISTINCT se.student_id)
FROM 
	order_mngmt.student_enrollments se
WHERE
	se.mode = 'PBT'
	AND se.status = 't'
	AND NOT EXISTS (
		SELECT
			spa.id
		FROM
			order_mngmt.student_paper_admin spa
		WHERE 
			se.code = spa.code
			AND se.student_id = se.student_id
			AND se.subject_id = spa.subject_id
			AND se.test_window_id = spa.test_window_id
	)
;

-- clear table for new enrollment run.
DELETE FROM students_to_enroll ;

INSERT INTO students_to_enroll (
	-- Students whose enrollments are set to a window whose LEA is different from the student's LEA.
	SELECT
		DISTINCT se.student_id
	FROM
		order_mngmt.student_enrollments se, 
		order_mngmt.test_windows tw, 
		accounts.organizations sch,
		student.students s 
	WHERE
		se.student_id = s.id 
		AND s.owner_org_id = sch.id 
		AND sch.parent_organization_id != tw.org_id
		AND se.test_window_id = tw.id 
		AND se.status = 't'

	UNION 

	-- STUDENTS WHO HAVE ACTIVE ENROLLMENTS TO WINDOW 0
	SELECT 
		DISTINCT se.student_id
	FROM 
		order_mngmt.student_enrollments se
	WHERE
		se.test_window_id=0
		AND se.status = 't'

	UNION 

	-- WINDOW MISMATCHES FOR STUDENTS WITH SCHOOL TRACK
	SELECT 
		DISTINCT se.student_id
	FROM 
		order_mngmt.student_enrollments se, 
		order_mngmt.test_windows tw, 
		accounts.organizations sch,
		order_mngmt.org_track ot,
		student.students s 
	WHERE
		se.student_id = s.id 
		AND s.owner_org_id = ot.school_org_id
		AND sch.id = ot.school_org_id
		AND sch.parent_organization_id = tw.org_id
		AND tw.track_id = ot.track_id
		AND tw.test_prgm_id = se.program_id
		AND se.test_window_id != tw.id 
		AND (s.stud_attribute->>'track') IS NULL
		AND se.status = 't'

	UNION 

	-- WINDOW MISMATCHES FOR STUDENTS WITH INDIVIDUAL TRACK
	SELECT 
		DISTINCT se.student_id
	FROM 
		order_mngmt.student_enrollments se, 
		order_mngmt.test_windows tw, 
		accounts.organizations sch,
		student.students s 
	WHERE
		se.student_id = s.id 
		AND sch.id = s.owner_org_id
		AND sch.parent_organization_id = tw.org_id
		AND 'ADMIN0' || tw.track_id = UPPER(s.stud_attribute->>'track')
		AND tw.test_prgm_id = se.program_id
		AND se.test_window_id != tw.id 
		AND (s.stud_attribute->>'track') IS NOT NULL
		AND se.status = 't'

	UNION

	-- STUDENT PBT ENROLLMENTS THAT ARE MISSING PAPER ENROLLMENTS
	SELECT 
		DISTINCT se.student_id
	FROM 
		order_mngmt.student_enrollments se
	WHERE
		se.mode = 'PBT'
		AND se.status = 't'
		AND NOT EXISTS (
			SELECT
				spa.id
			FROM
				order_mngmt.student_paper_admin spa
			WHERE 
				se.code = spa.code
				AND se.student_id = se.student_id
				AND se.subject_id = spa.subject_id
				AND se.test_window_id = spa.test_window_id
		)
);

--students missing CST enrollments
INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, lao.org_code as ssid
	--count(distinct ss.id) as expected_enrollments_cst_Hayward, lao.org_code
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ss.id in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'scienceMode' = 'CST'
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and stud_attribute ->> 'track' = 'ADMIN01'
			and owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select 
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CST'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN02')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
			from
				student.students ss
			where
				ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CST'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN03')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 3))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CST'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN04')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 4))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CST'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN05')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 5))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where stud_attribute ->> 'scienceMode' = 'CST'
				and grade in ('05','08','10')
				and owner_org_id != 73202
				--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
				and stud_attribute ->> 'track' = 'ADMIN06')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 6))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			id
		from
			student.students
		where
			(stud_attribute ->> 'scienceMode') is null
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and stud_attribute ->> 'track' = 'ADMIN01'
			and owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select 
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					(stud_attribute ->> 'scienceMode') is null
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN02')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 2))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
			from
				student.students ss
			where
				ss.id in (
				select
					id
				from
					student.students
				where
					(stud_attribute ->> 'scienceMode') is null
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN03')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 3))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					(stud_attribute ->> 'scienceMode') is null
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN04')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 4))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					(stud_attribute ->> 'scienceMode') is null
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN05')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 5))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
				(stud_attribute ->> 'scienceMode') is null
				and grade in ('05','08','10')
				and owner_org_id != 73202
				--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
				and stud_attribute ->> 'track' = 'ADMIN06')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 6))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'scienceMode' = 'CST'
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and (stud_attribute ->> 'track') is null
			and owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			id
		from
			student.students
		where
			(stud_attribute ->> 'scienceMode') is null
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and (stud_attribute ->> 'track') is null
			and owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
		) and ss.id not in (select student_id from students_to_enroll));
		
--students missing cma enrollments
INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, lao.org_code as ssid
	--count(distinct ss.id) as expected_enrollments_cma_Hayward
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ss.id in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'scienceMode' = 'CMA'
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and stud_attribute ->> 'track' = 'ADMIN01'
			and owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select 
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CMA'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN02')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
			from
				student.students ss
			where
				ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CMA'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN03')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 3))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CMA'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN04')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CMA'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN05')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where stud_attribute ->> 'scienceMode' = 'CMA'
				and grade in ('05','08','10')
				and owner_org_id != 73202
				--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
				and stud_attribute ->> 'track' = 'ADMIN06')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'scienceMode' = 'CMA'
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and (stud_attribute ->> 'track') is null
			and owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
		)and ss.id not in (select student_id from students_to_enroll));
		

--students missing capa enrollments
INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, lao.org_code as ssid
	--count(distinct ss.id) as expected_enrollments_capa_Hayward
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ss.id in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'scienceMode' = 'CAP'
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and stud_attribute ->> 'track' = 'ADMIN01'
			and owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select 
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CAP'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN02')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
			from
				student.students ss
			where
				ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CAP'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN03')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 3))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CAP'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN04')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'scienceMode' = 'CAP'
					and grade in ('05','08','10')
					and owner_org_id != 73202
					and stud_attribute ->> 'track' = 'ADMIN05')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where stud_attribute ->> 'scienceMode' = 'CAP'
				and grade in ('05','08','10')
				and owner_org_id != 73202
				--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
				and stud_attribute ->> 'track' = 'ADMIN06')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 6))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'scienceMode' = 'CAP'
			and grade in ('05','08','10')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and (stud_attribute ->> 'track') is null
			and owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
		)and ss.id not in (select student_id from students_to_enroll));

		
--students missing enrollments in sts

INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, lao.org_code as ssid
	--count(distinct ss.id) as expected_enrollments_sts_Hayward
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ss.id in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'stsMode' = 'true'
			and grade in ('02','03','04','05','06','07','08','09','10','11')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and stud_attribute ->> 'track' = 'ADMIN01'
			and owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select 
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'stsMode' = 'true'
					and grade in ('02','03','04','05','06','07','08','09','10','11')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN02')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
			from
				student.students ss
			where
				ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'stsMode' = 'true'
					and grade in ('02','03','04','05','06','07','08','09','10','11')
					and owner_org_id != 73202
					and stud_attribute ->> 'track' = 'ADMIN03')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 3))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'stsMode' = 'true'
					and grade in ('02','03','04','05','06','07','08','09','10','11')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN04')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where
					stud_attribute ->> 'stsMode' = 'true'
					and grade in ('02','03','04','05','06','07','08','09','10','11')
					and owner_org_id != 73202
					--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
					and stud_attribute ->> 'track' = 'ADMIN05')
						and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			distinct ss.id
		from
			student.students ss
		where
			ss.id in (
				select
					id
				from
					student.students
				where stud_attribute ->> 'stsMode' = 'true'
				and grade in ('02','03','04','05','06','07','08','09','10','11')
				and owner_org_id != 73202
				--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
				and stud_attribute ->> 'track' = 'ADMIN06')
					and owner_org_id in (
						select id from accounts.organizations where parent_organization_id in (
							select org_id from order_mngmt.instructional_calendar where track_id = 6))
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			id
		from
			student.students
		where
			stud_attribute ->> 'stsMode' = 'true'
			and grade in ('02','03','04','05','06','07','08','09','10','11')
			and owner_org_id != 73202
			--and owner_org_id in (select id from accounts.organizations where parent_organization_id = 57340)
			and (stud_attribute ->> 'track') is null
			and owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				) and ss.id not in (select student_id from order_mngmt.student_paper_admin)
		)and ss.id not in (select student_id from students_to_enroll));
		
--students missing sbac math enrollments

INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, ss.grade, lao.org_code as ssid
	--distinct ss.id, ss.grade, sao.org_code, lao.org_code, (ss.stud_attribute->> 'specialForm') as special_form, (ss.stud_attribute->> 'track') as student_admin--, ot.track_id as school_admin
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
	,order_mngmt.org_track ot
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ot.school_org_id = sao.id
	and ss.id in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
	
	
	
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
		)and ss.id not in (select student_id from students_to_enroll));
		

--students missing enrollments in sbac ela
INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, ss.grade, lao.org_code as ssid
	--distinct ss.id, ss.grade, sao.org_code, lao.org_code, (ss.stud_attribute->> 'specialForm') as special_form, (ss.stud_attribute->> 'track') as student_admin--, ot.track_id as school_admin
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
	,order_mngmt.org_track ot
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ot.school_org_id = sao.id
	and ss.id in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
	
	
	
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
		)and ss.id not in (select student_id from students_to_enroll));
		
		
--missing online SBAC math

INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, ss.grade, lao.org_code as ssid
	--distinct ss.id, ss.grade, sao.org_code, lao.org_code, (ss.stud_attribute->> 'specialForm') as special_form, (ss.stud_attribute->> 'track') as student_admin--, ot.track_id as school_admin
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
	,order_mngmt.org_track ot
	/* ,order_mngmt.student_enrollments se */
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ot.school_org_id = sao.id
	and ss.owner_org_id != 73202
	/* and ss.id = se.student_id
	and se.status = 't'
	and se.mode = 'CBT' */
	and ss.grade in ('03','04','05','06','07','08','11')
	and ss.id not in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 2
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
	
	
	
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 2
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
		) and ss.id not in (select student_id from order_mngmt.student_enrollments where mode = 'CBT' and status = 't' and program_id in (2,3)) and ss.id not in (select student_id from students_to_enroll));
		
		
--missing online SBAC ELA

INSERT INTO students_to_enroll(
select 
	--distinct ss.id, ss.local_student_id, ss.grade, lao.org_code as ssid
	--distinct ss.id, ss.grade, sao.org_code, lao.org_code, (ss.stud_attribute->> 'specialForm') as special_form, (ss.stud_attribute->> 'track') as student_admin--, ot.track_id as school_admin
	distinct ss.id
from 
	student.students ss
	,accounts.organizations sao
	,accounts.organizations lao
	,order_mngmt.org_track ot
	/* ,order_mngmt.student_enrollments se */
where 
	ss.owner_org_id = sao.id
	and sao.parent_organization_id = lao.id
	and ot.school_org_id = sao.id
	and ss.owner_org_id != 73202
	/* and ss.id = se.student_id
	and se.status = 't'
	and se.mode = 'CBT' */
	and ss.grade in ('03','04','05','06','07','08','11')
	and ss.id not in(
	select 
		distinct ss.id
	from
		student.students ss 
	where ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			and sao.id = paa.org_id
			and ss.id = spa.student_id
			and paa.subj_id = 14
			and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' != 'braille'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
	
	
	
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN01'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 1))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN02'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 2))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN03'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 3))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN04'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 4))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN05'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 5))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and ss.stud_attribute ->> 'track' = 'ADMIN06'
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select id from accounts.organizations where parent_organization_id in (
					select org_id from order_mngmt.instructional_calendar where track_id = 6))
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	or ss.id in (
		select
			ss.id
		from
		
		accounts.organizations sao, 
		accounts.organizations lao, 
		student.students ss, 
		--order_mngmt.school_paper_assignment paa, 
		order_mngmt.student_paper_admin spa 
		where
			ss.owner_org_id = sao.id
			and sao.parent_organization_id = lao.id
			--and sao.id = paa.org_id
			and ss.id = spa.student_id
			--and paa.subj_id = 14
			--and CAST(paa.grade in('01','02','03','04','05','06','07','08','09','10','11','12') AS integer) = CAST(ss.grade in('1','2','3','4','5','6','7','8','9','10','11','12') AS integer)
			and ss.owner_org_id != 73202
			and (ss.stud_attribute ->> 'track') is null
			and ss.stud_attribute ->> 'specialForm' = 'braille'
			and sao.org_attributes ->> 'allowBraille' = 'on'
			and ss.owner_org_id in (
				select sao.id from accounts.organizations sao, order_mngmt.org_track ot, order_mngmt.instructional_calendar ic where sao.id = ot.school_org_id and ot.track_id = ic.track_id and sao.parent_organization_id = ic.org_id and ic.preid_type = 1)
				)--and ss.id not in (select student_id from order_mngmt.student_paper_admin)
	
	
	
	
	
	
		) and ss.id not in (select student_id from order_mngmt.student_enrollments where mode = 'CBT' and status = 't' and program_id in (2,3)) and ss.id not in (select student_id from students_to_enroll));

-- Mark AND delete students for re-enrollment.
UPDATE student.students SET enrolled = 'f' WHERE id IN (SELECT student_id FROM  students_to_enroll);
DELETE FROM order_mngmt.student_enrollments where student_id in (select student_id from students_to_enroll);
DELETE FROM order_mngmt.student_paper_admin where student_id in (select student_id from students_to_enroll);
DELETE FROM online_testing.student_online_admin where student_id in (select student_id from students_to_enroll);
