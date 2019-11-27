
DROP DATABASE IF EXISTS  MANAGER_EMPLOYEES;

CREATE DATABASE MANAGER_EMPLOYEES;

USE MANAGER_EMPLOYEES;

-- Tạo bảng phòng ban
DROP TABLE IF EXISTS  departments;
CREATE TABLE departments(
	dep_id varchar(255) PRIMARY KEY,
    dep_name varchar(255),
    address varchar(255),
    phone varchar(11)
);


DROP TABLE IF EXISTS  job_positions;
CREATE TABLE job_positions(
	position_id varchar(255) PRIMARY KEY,
	position_name varchar(255)
);

DROP TABLE IF EXISTS  level_educations;
CREATE TABLE level_educations(
	edu_id varchar(255) PRIMARY KEY,
	edu_name varchar(255),
	specialized varchar(255)
);

DROP TABLE IF EXISTS  salarys;
CREATE TABLE salarys(
	level_salary int PRIMARY KEY,
	basic_salary float,
	coefficient_salary float,
	allowance float
);

DROP TABLE IF EXISTS  employees;
CREATE TABLE employees(
	emp_id varchar(255) PRIMARY KEY,
	name varchar(255),
	date_of_birth date,
	address varchar(255),
	gender varchar(255),
	nation varchar(255),
    status int(11),
	dep_id varchar(255),
	position_id varchar(255),
	edu_id varchar(255),
	level_salary int,
    FOREIGN KEY (level_salary) REFERENCES salarys (level_salary),
	FOREIGN KEY (position_id) REFERENCES job_positions (position_id),
	FOREIGN KEY (edu_id) REFERENCES level_educations (edu_id)
);

DROP TABLE IF EXISTS  labor_contracts;
CREATE TABLE labor_contracts(
	contract_id varchar(255),
	emp_id varchar(255),
	type_contract varchar(255),
	start_date date,
	end_date date,
    PRIMARY KEY (contract_id),
	FOREIGN KEY (emp_id) REFERENCES employees (emp_id)
);

DROP TABLE IF EXISTS  timekeepings;
CREATE TABLE timekeepings(
	emp_id varchar(255),
    month INT,
    year INT,
    days_work int,
    days_paid_leave int,
    days_pay_without_leave int,
	FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    primary key(emp_id,month, year)
);

DROP TABLE IF EXISTS emp_has_salarys;
CREATE TABLE emp_has_salarys(
	emp_id varchar(255),
    month INT,
    year INT,
    salary float,
	FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    PRIMARY KEY(emp_id, month, year)
);



DROP TABLE IF EXISTS employees_audit;
CREATE TABLE employees_audit(
	emp_id varchar(255),
    action varchar(255),
    changed_on date,
    message varchar(255),
	FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    PRIMARY KEY(emp_id)
);


INSERT INTO departments 
value ( 'PB_01','Phòng kế toán','03- Nguyễn Văn Thoại', '0362714627'),
( 'PB_02','Phòng nhân sự','03- Nguyễn Văn Thoại', '0362714627'),
( 'PB_03','Phòng marketing','03- Nguyễn Văn Thoại', '0362714627'),
( 'PB_04','Phòng kiểm toán nội vụ','03- Nguyễn Văn Thoại', '0362714627'),
( 'PB_05','Phòng đối ngoại','03- Nguyễn Văn Thoại', '0362714627'),
( 'PB_06','Phòng kinh doanh','03- Nguyễn Văn Thoại', '0362714627'),
( 'PB_07','Văn phòng đại diện','03- Nguyễn Văn Thoại', '0362714627'),
( 'PB_08','Phòng hành chính','03- Nguyễn Văn Thoại', '0362714627');


 INSERT INTO job_positions
value ('CV_01','Tổng giám đốc'),
('CV_02','Quản lí'),
('CV_03','Giám đốc'),
('CV_04','Phó giám đốc'),
('CV_05','Bảo vệ'),
('CV_06','Trưởng phòng'),
('CV_07','Phó phòng'),
('CV_08','Thư kí'),
('CV_09','Nhân viên'),
('CV_10','Trợ lí');


INSERT INTO level_educations
value ('HV_01','Đại học','Kế toán'),
('HV_02','Cao đẳng','Kinh tế'),
('HV_03','Đại học','Quản trị kinh doanh'),
('HV_04','Tiến sĩ','Ngôn ngữ Anh'),
('HV_05','Đại học','Tài chính ngân hàng'),
('HV_06','Đại học','Marketing'),
('HV_07','Đại học','Thương mại điện tử'),
('HV_08','Đại học','Hành chính văn phòng'),
('HV_09','Đại học','Viễn thông'),
('HV_10','Đại học','Kỹ thuật và công nghệ');


INSERT INTO salarys
value 
	(1,1390000,6.20,0.1),
	(2,1390000,6.56,0.2),
	(3,1390000,6.92,0.3),
	(4,1390000,7.28,0.3),
	(5,1390000,7.64,0.4),
	(6,1390000,8.00,0.4);

INSERT INTO employees
value('EMP_01','Nguyễn Thị Thu','1984-06-20','04-Nguyễn Công Trứ-Hà Nội','Nữ','Việt Nam',1,'','CV_01','HV_01',1),
('EMP_02','Nguyễn Phương Tri','1980-03-13','43-Ba Đình-Hà Nội','Nam','Việt Nam',1,'PB_02','CV_02','HV_02',1),
('EMP_03','Hoàng Văn Huy','1990-05-17','13-Nguyễn Văn Thoại -Hà Nội','Nam','Việt Nam',1,'','CV_03','HV_03',1),
('EMP_04','David Jonsh','1987-12-12','04-Hùng Vương-Hà Nội','Nam','Canada',1,'','CV_04','HV_04',1),
('EMP_05','Trần Phương Thảo','1989-05-18','101B-Lê Hữu Trắc-Hà Nội','Nam','Việt Nam',0,'PB_05','CV_05','HV_05',1),
('EMP_06','Elly Trần ','1990-01-01','93-Phạm Văn Đằng-Hà Nội','Nữ','Việt Nam',1,'PB_06','CV_06','HV_06',1),
('EMP_07','CrishTorn','1987-03-20','23-Sinh Sắc-Hà Nội','Nam','UK',1,'PB_07','CV_07','HV_07',1),
('EMP_08','Leeon','1990-11-11','04-Trưng Trắc-Hà Nội','Nam','China',1,'','CV_08','HV_08',1),
('EMP_09','Park Jimin','1994-12-20','46-Nguyễn Huệ-Hà Nội','Nam','Korean',1,'PB_04','CV_09','HV_09',1),
('EMP_10','Min Yoongi','1993-05-15','97-Nguyễn Du-Hà Nội','Nữ','Korean',1,'PB_02','CV_06','HV_01',1);


INSERT INTO labor_contracts(contract_id,emp_id,type_contract,start_date)
value('HD_01','EMP_01','Không thời hạn','2011-01-01'),
('HD_03','EMP_03','Không thời hạn','2010-01-01'),
('HD_04','EMP_04','Không thời hạn','2008-01-01'),
('HD_08','EMP_08','Không thời hạn','2011-01-01'),
('HD_11','EMP_02','Không thời hạn','2014-11-19');

INSERT INTO labor_contracts
VALUES
('HD_02','EMP_02','Xác định thời hạn','2009-11-18','2014-11-18'),
('HD_05','EMP_05','Xác định thời hạn','2017-03-08','2020-03-08'),
('HD_06','EMP_06','Xác định thời hạn','2008-04-20','2019-04-20'),
('HD_07','EMP_07','Xác định thời hạn','2005-11-11','2023-11-11'),
('HD_09','EMP_09','Xác định thời hạn','2015-04-27','2016-04-27'),
('HD_10','EMP_10','xác định thời hạn','2011-08-02','2022-08-02');

INSERT INTO timekeepings
VALUES  ('EMP_01',8,2018,23,2,2),
		('EMP_02',8,2018,25,1,1),
		('EMP_03',8,2018,24,2,1),
		('EMP_04',8,2018,25,1,0),
		('EMP_05',8,2018,23,1,3),
		('EMP_06',8,2018,24,1,1),
		('EMP_07',8,2018,24,3,0),
		('EMP_08',8,2018,21,1,5),
		('EMP_09',8,2018,24,1,2),
		('EMP_10',8,2018,20,3,4);

