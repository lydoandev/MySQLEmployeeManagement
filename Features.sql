

-- TẠO VIEW XEM TOÀN BỘ THÔNG TIN CỦA NHÂN VIÊN

DROP VIEW IF EXISTS information_employees;

CREATE VIEW information_employees AS
	SELECT 
		emp_id, name, date_of_birth, gender, nation,status, dep_name, position_name, edu_name, level_salary
	FROM 
		employees AS E LEFT JOIN departments AS D ON E.dep_id = D.dep_id 
        LEFT JOIN job_positions AS P  ON E.position_id = P.position_id
        LEFT JOIN level_educations AS ED ON E.edu_id = ED.edu_id;
        

SELECT * FROM information_employees;

-- TẠO VIEW XEM LƯƠNG CỦA NHÂN VIÊN

DROP VIEW IF EXISTS salary_of_employees;
CREATE VIEW salary_of_employees AS
	SELECT employees.emp_id, name, timekeepings.month, timekeepings.year, days_work, days_paid_leave, days_pay_without_leave, salary
    FROM employees LEFT JOIN timekeepings ON employees.emp_id = timekeepings.emp_id
    LEFT JOIN emp_has_salarys ON employees.emp_id = emp_has_salarys.emp_id;

SELECT * FROM salary_of_employees;



-- 2 FUNCTION

-- TẠO FUNCTION ĐỂ ĐẾM SỐ NGÀY LÀM VIỆC TIÊU CHUẨN TRONG THÁNG
-- Bởi vì các tháng khác nhau sẽ có số ngày chủ nhật khác nhau

DROP FUNCTION IF EXISTS count_standard_working_days;
DELIMITER $$
CREATE FUNCTION count_standard_working_days(month INT, year INT) 
RETURNS int(11) deterministic
BEGIN 
	DECLARE dayInMonth int(11) DEFAULT (DAY(LAST_DAY(CONCAT(year,"-",month,"-1")))); -- Đếm tổng số ngày có trong tháng
    DECLARE countDay int(11) DEFAULT 1;
    DECLARE weekend int(11) DEFAULT 0;
    DECLARE standard_day int(11) DEFAULT 0;
    -- Đếm số ngày đặc biệt trong tháng như thứ bảy, chủ nhật
    WHILE countDay <= dayInMonth DO 
		IF weekday(CONCAT(year,"-",month,"-",countDay)) != 6 THEN
			SET standard_day =standard_day+1;
        END IF;
		SET countDay=countDay+1;
    END WHILE;
    RETURN standard_day;
END$$
DELIMITER ;

SELECT count_standard_working_days(03,2019);

-- FUNCTION TÍNH SỐ NĂM KINH NGHIỆM CỦA NHÂN VIÊN
-- Vì có trường hợp một nhân viên có nhiều hơn một bản hợp đồng. Functon này phục vụ cho việc update bậc lương

DROP FUNCTION IF EXISTS count_years_of_exprience;
DELIMITER $$
CREATE FUNCTION count_years_of_exprience(emp_id_input varchar(255)) 
RETURNS int(11) deterministic
BEGIN 
	DECLARE v_finished int DEFAULT 0;
    DECLARE v_emp_id VARCHAR(255);
    DECLARE v_start_date date;
    DECLARE v_end_date date;
    DECLARE sum_year int DEFAULT 0;
	DECLARE cursor1 CURSOR FOR SELECT emp_id, start_date, end_date FROM labor_contracts;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    OPEN cursor1;
    
    FETCH cursor1 INTO v_emp_id, v_start_date, v_end_date;
    WHILE v_finished != 1 DO
        IF v_emp_id = emp_id_input THEN
			IF v_end_date < v_start_date THEN
				SET sum_year = 0;
			ELSEIF v_end_date > CURDATE() OR v_end_date IS NULL THEN
				SET sum_year = sum_year + TIMESTAMPDIFF(YEAR, v_start_date, CURDATE());
			ELSE
				SET sum_year = sum_year + TIMESTAMPDIFF(YEAR, v_start_date, v_end_date);
            END IF;
        END IF;
		
        FETCH cursor1 INTO v_emp_id, v_start_date, v_end_date;
	END WHILE;
    CLOSE cursor1;
    RETURN sum_year;
END$$
DELIMITER ;

SELECT count_years_of_exprience('EMP_02');

-- FUNCTION ĐỂ TRẢ VỀ NĂM KẾT THÚC HỢP ĐỒNG 
-- Bởi vì có trường hợp kết thúc hợp đồng cũ có thời hạn và bắt đầu hợp đồng mới không thời hạn

DROP FUNCTION IF EXISTS get_year_end_contract;
DELIMITER $$
CREATE FUNCTION get_year_end_contract(input_emp_id varchar(255)) 
RETURNS DATE deterministic
BEGIN 
	DECLARE v_finished int DEFAULT 0;
    DECLARE v_empid varchar(255);
    DECLARE v_final_end_date date;
    DECLARE v_end_date date;
    
    DECLARE cursor1 CURSOR FOR SELECT emp_id, end_date FROM labor_contracts;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    
    SELECT MIN(end_date) INTO v_final_end_date FROM labor_contracts WHERE emp_id = input_emp_id AND end_date IS NOT NULL;
    
    OPEN cursor1;
    
    FETCH cursor1 INTO v_empid, v_end_date;
    
    WHILE v_finished != 1 DO
		IF v_empid = input_emp_id THEN
			IF v_end_date IS NULL THEN
				SET v_final_end_date = NULL;
			ELSEIF v_end_date > v_final_end_date THEN
				SET v_final_end_date = v_end_date;
            END IF;
		END IF;
        FETCH cursor1 INTO v_empid, v_end_date;
	END WHILE;
    CLOSE cursor1;
    RETURN v_final_end_date;
END$$
DELIMITER ;

SELECT get_year_end_contract('EMP_06');

-- 2 PROCEDURE

-- TẠO PROCEDURE ĐỂ CẬP NHẬT BẬC LƯƠNG CỦA NHÂN VIÊN VÌ CỨ BA NĂM THÌ TĂNG MỘT BẬC LƯƠNG

DROP PROCEDURE IF EXISTS update_level_salary;
DELIMITER $$
CREATE PROCEDURE update_level_salary()
BEGIN 
	DECLARE v_finished int DEFAULT 0;
    DECLARE v_empid varchar(255);
    DECLARE v_status int(11);
    DECLARE v_start_date date;
    DECLARE v_end_date date;
    DECLARE v_level_salary INT;
    
    DECLARE cursor1 CURSOR FOR SELECT emp_id, status FROM employees;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    OPEN cursor1;
    
    FETCH cursor1 INTO v_empid, v_status;
    WHILE v_finished != 1 DO
		SET v_level_salary = 1 + FLOOR(count_years_of_exprience(v_empid)/3); 
        SELECT v_level_salary;
        IF v_level_salary >= 6 THEN 
			UPDATE employees SET level_salary = 6 WHERE emp_id = v_empid;
		ELSE
			UPDATE employees SET level_salary = v_level_salary WHERE emp_id = v_empid;
        END IF;
        FETCH cursor1 INTO v_empid, v_status;
	END WHILE;
    CLOSE cursor1;
END$$
DELIMITER ;

CALL update_level_salary;

-- TẠO PROCEDURE TÍNH LƯƠNG THEO THÁNG CHO TOÀN BỘ NHÂN VIÊN
-- Công thức tính lương: lươngFull = (hsLuong + hsPhuCap) * luongCoBan => luong = luongFull/soNgayCongTieuChuan*(soNgaylam + ngayNghiCoLuong)


DROP PROCEDURE IF EXISTS calculate_salary;
DELIMITER $$
CREATE PROCEDURE calculate_salary(v_month INT, v_year INT)
BEGIN 
	DECLARE v_finished int DEFAULT 0;
    DECLARE v_empid varchar(255);
    DECLARE v_level_salary INT;
    DECLARE v_status INT;
    DECLARE v_basic_salary float;
    DECLARE v_allowance float;
    DECLARE v_coefficient_salary float;
    DECLARE v_days_work INT;
    DECLARE v_days_paid_leave INT;
    DECLARE salary float;
    
    DECLARE cursor1 CURSOR FOR SELECT emp_id, level_salary,status FROM employees;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    OPEN cursor1;
    
    FETCH cursor1 INTO v_empid, v_level_salary, v_status;
    
    WHILE v_finished != 1 DO
    
		SELECT basic_salary, coefficient_salary, allowance INTO v_basic_salary,
        v_coefficient_salary, v_allowance FROM salarys WHERE level_salary = v_level_salary;
        SELECT days_work, days_paid_leave INTO v_days_work, v_days_paid_leave 
        FROM timekeepings WHERE emp_id = v_empid AND month = v_month AND year = v_year;
        IF  v_status =1 THEN 
			SET salary = (v_coefficient_salary + v_allowance) * v_basic_salary;
            SET salary = salary/count_standard_working_days(v_month, v_year) * (v_days_work + v_days_paid_leave);
            -- Lương nhân viên nhận được sẽ bằng lương full tháng/ngày công chuẩn nhân*(ngày làm + ngày nghỉ có lương)
            INSERT INTO emp_has_salarys VALUES
            (v_empid, v_month, v_year, salary);
        END IF;
		
        FETCH cursor1 INTO v_empid, v_level_salary, v_status;
        
	END WHILE;
    CLOSE cursor1;
END$$
DELIMITER ;


 CALL calculate_salary(08,2018);

-- TẠO PROCEDURE ĐỂ UPDATE STATUS CỦA NHÂN VIÊN THÀNH 0 KHI ĐÃ HẾT HỢP ĐỒNG LAO ĐỘNG

DROP PROCEDURE IF EXISTS update_status_employees;
DELIMITER $$
CREATE PROCEDURE update_status_employees()
BEGIN 
	DECLARE v_finished int DEFAULT 0;
    DECLARE v_empid varchar(255);
    DECLARE v_status int(11);
    DECLARE v_end_date date;
    
    DECLARE cursor1 CURSOR FOR SELECT emp_id FROM employees;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_finished = 1;
    OPEN cursor1;
    
    FETCH cursor1 INTO v_empid;
    WHILE v_finished != 1 DO
        IF get_year_end_contract(v_empid) < CURDATE() &&  get_year_end_contract(v_empid) IS NOT NULL THEN
			UPDATE employees SET status = 0 WHERE emp_id = v_empid;
        END IF;
        FETCH cursor1 INTO v_empid;
	END WHILE;
    CLOSE cursor1;
END$$
DELIMITER ;

CALL update_status_employees;

-- 2 TRIGGER THEO DÕI SỰ THAY ĐỔI

-- TRIGGER THEO DÕI SỰ UPDATE NHÂN VIÊN Ở BẢNG EMPLOYEES
/* Bởi vì một số nhân viên có thể chuyển phòng ban và đổi chức vụ,
 nếu có sự update những trường này sẽ lưu lại ở bảng employees_audit để dễ theo dõi */

DROP TRIGGER IF EXISTS `FOLLOW_UPDATE_EMPLOYEES`;

DELIMITER $$
CREATE TRIGGER `FOLLOW_UPDATE_EMPLOYEES` BEFORE UPDATE ON `employees` 
FOR EACH ROW
BEGIN
	IF NEW.dep_id != OLD.dep_id THEN
	INSERT INTO `employees_audit`
	(`emp_id`, `action`, `changed_on`, `message`) 
	VALUES 
	(`OLD`.`emp_id`,'UPDATE', NOW(), CONCAT('The department was change from', OLD.dep_id, 'to', NEW.dep_id));
	END IF;
    IF NEW.position_id != OLD.position_id THEN
	INSERT INTO `employees_audit`
	(`emp_id`, `action`, `changed_on`, `message`) 
	VALUES 
	(`OLD`.`emp_id`,'UPDATE', NOW(), CONCAT('The department was change from ', OLD.position_id, ' to ', NEW.position_id));
	END IF;
END$$
DELIMITER ;

UPDATE employees SET dep_id = 'PB_01' WHERE emp_id = 'EMP_02';

-- TRIGGER THEO DÕI SỰ UPDATE BẬC LƯƠNG BẤT THƯỜNG
-- Bởi vì thường thì 3 năm mới update một bậc lương, nếu nhận thấy có sự thay đổi bậc lương lớn hơn 2 so với bậc cũ thì vào bảng employees_audit để theo dõi

DROP TRIGGER IF EXISTS `BEFORE_EMPLOYEE_UPDATE_LEVEL_SALARY`;

DELIMITER $$
CREATE TRIGGER `BEFORE_EMPLOYEE_UPDATE_LEVEL_SALARY` BEFORE UPDATE ON `employees`
FOR EACH ROW
BEGIN
IF NEW.level_salary - OLD.level_salary > 2 THEN
INSERT INTO `employees_audit`
(`emp_id`, `action`, `changed_on`, `message`) 
VALUES 
(OLD.emp_id,'UPDATE', NOW(), CONCAT('The level salary was change from', OLD.level_salary, ' to ', NEW.level_salary));
END IF;
END$$
DELIMITER ;

UPDATE employees SET level_salary = 4 WHERE emp_id = 'EMP_02';


-- 2 TRIGGER KIỂM SOÁT TÍNH HỢP LỆ

-- TRIGGER KIỂM TRA TÍNH HỢP LỆ CỦA TỔNG SỐ NGÀY CÔNG TRƯỚC KHI INSERT VÀO BẢNG timekeepings
-- Bởi vì tổng số ngày làm, số ngày nghỉ có lương, số ngày nghỉ không lương phải bằng ngày công chuẩn của tháng đó

DROP TRIGGER IF EXISTS `CHECK_BEFORE_INSERT_TIMEKEEPINGS`;

DELIMITER $$
CREATE TRIGGER `CHECK_BEFORE_INSERT_TIMEKEEPINGS` BEFORE INSERT ON `timekeepings`
FOR EACH ROW
BEGIN
	IF (NEW.days_work + NEW.days_paid_leave + NEW.days_pay_without_leave) !=  count_standard_working_days(NEW.month, NEW.year) THEN
		-- Tổng số ngày làm việc, ngày nghỉ có lương và ngày nghỉ không lương phải bằng số ngày làm việc chuẩn trong tháng
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT='Total days working and leave is not valid'; 
	END IF;
END$$
DELIMITER ;

INSERT INTO timekeepings
VALUES  ('EMP_01',12,2018,19,1,2);

-- TRIGGER KIỂM TRA DỮ LIỆU NGÀY SINH, STATUS TRƯỚC KHI INSERT VÀO BẢNG EMPLOYEES

DROP TRIGGER IF EXISTS `CHECK_BEFORE_INSERT_EMPLOYEES`;

DELIMITER $$
CREATE TRIGGER `CHECK_BEFORE_INSERT_EMPLOYEES` BEFORE INSERT ON `employees`
FOR EACH ROW
BEGIN
	IF TIMESTAMPDIFF(YEAR, NEW.date_of_birth, CURDATE()) <= 18 || (NEW.status != 0 && NEW.status != 1) THEN
		-- Tổng số ngày làm việc, ngày nghỉ có lương và ngày nghỉ không lương phải bằng số ngày làm việc chuẩn trong tháng
		SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT='Age of employee must more than 18 and Stutus only 0 or 1'; 
	END IF;
END$$
DELIMITER ;

INSERT INTO employees
value('EMP_12','Nguyễn Thị Thu','2010-06-20','04-Nguyễn Công Trứ-Hà Nội','Nữ','Việt Nam',1,'','CV_01','HV_01',1);


-- 2 EVENTS

-- TẠO EVEN TỰ ĐỘNG UPDATE BẬC LƯƠNG MỖI NGÀY

DROP EVENT IF EXISTS event_update_level_salary;
DELIMITER $$
CREATE EVENT event_update_level_salary
ON SCHEDULE EVERY 1 DAY
STARTS current_timestamp + INTERVAL 1 MINUTE
ON COMPLETION PRESERVE
enable
DO CALL update_level_salary;
$$
DELIMITER ;

show events;

-- TẠO EVENT TỰ ĐỘNG TÍNH LƯƠNG VÀO CUỐI THÁNG
-- Vì phải tính lương vào mỗi cuối tháng để đầu tháng có số liệu để phát lương

DROP EVENT IF EXISTS event_calculate_salary;
DELIMITER $$
CREATE EVENT event_calculate_salary
ON SCHEDULE EVERY 1 MONTH
STARTS timestamp('2018-07-31 23:59:00')
ON COMPLETION PRESERVE
enable
DO CALL calculate_salary(CONCAT(YEAR(CURDATE()), MONTH(CURDATE())));
$$
DELIMITER ;

-- TẠO EVENT TỰ ĐỘNG CẬP NHẬT STATUS 

DROP EVENT IF EXISTS event_update_status;
DELIMITER $$
CREATE EVENT event_update_status
ON SCHEDULE EVERY 1 DAY
STARTS current_timestamp + INTERVAL 1 MINUTE
ON COMPLETION PRESERVE
enable
DO CALL update_status_employees;
$$
DELIMITER ;

-- 1 PROCEDURE CÓ SỬ DỤNG TRANSACTION

-- TẠO PROCEDURE ĐỂ ĐỒNG THỜI VỪA INSERT VÀO BẢNG NHÂN VIÊN VỪA INSERT VÀO BẢNG HỢP ĐỒNG

DROP PROCEDURE IF EXISTS insert_employees_fail;
DELIMITER $$
CREATE PROCEDURE insert_employees_fail(
emp_id varchar(255), name varchar(255), date_of_birth date, address varchar(255),
gender varchar(255), nation varchar(255), status int, dep_id varchar(255),
position_id varchar(255), edu_id varchar(255),  level_salary varchar(255),
start_date date, end_date date, type_contract varchar(255)
)
BEGIN 
	DECLARE _rollback BOOL DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET _rollback=1;
    START TRANSACTION;
    INSERT INTO employees VALUES (emp_id, name, date_of_birth, address, gender, nation, status, dep_id, position_id, edu_id, level_salary);
    INSERT INTO labor_contract (emp_id, type_contract, start_date, end_date)
    VALUES (emp_id, type_contract, start_date, end_date);
    IF _rollback THEN
		ROLLBACK;
	ELSE 
		COMMIT;
	END IF;
END$$
DELIMITER ;

CALL insert_employees_fail('EMP_11','Nguyễn Thị Thu','1984-06-20',
'04-Nguyễn Công Trứ-Hà Nội','Nữ','Việt Nam',1,'','CV_01','HV_01',1,'2018-02-01', '2018-02-09', 'H');



-- 2 CHỈ MỤC CHO SỐ

ALTER table emp_has_salarys add INDEX (salary);

ALTER table timekeepings add INDEX (days_work);

-- 2 CHỈ MỤC CHO CHUỖI

ALTER TABLE employees ADD FULLTEXT(name);

SELECT emp_id, name, address  FROM employees 
WHERE MATCH(name) against('+nguyen -thi' IN boolean mode);

ALTER TABLE departments ADD FULLTEXT(dep_name);

SELECT dep_id, dep_name, address  FROM departments 
WHERE MATCH(dep_name) against('+Phong -Toan' IN boolean mode);

-- 2 USERS ROLE

DROP USER IF EXISTS 'Administrator'@'localhost';
CREATE USER 'Administrator'@'localhost' IDENTIFIED BY '@12345@';
GRANT ALL ON manager_employees.* TO 'Administrator'@'localhost';

DROP USER IF EXISTS 'employees'@'localhost';
CREATE USER 'employees'@'localhost' IDENTIFIED BY 'iamemployee';
GRANT SELECT ON manager_employees.information_employees TO 'employees'@'localhost';



















