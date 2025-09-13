-- Database Management System - Career Pathway & Reskilling Tech Platform 

CREATE DATABASE career_platform;
USE career_platform;

-- Stores all students and admins details
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    full_name VARCHAR(200) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('student','admin') NOT NULL DEFAULT 'student',
    education_level ENUM('highschool','college') NULL, -- nullable for admins
    profile_completed BOOLEAN NOT NULL DEFAULT FALSE,
    subscription_expires DATE NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Student payment subscriptions
CREATE TABLE Subscription_Plans (
    plan_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    plan_name VARCHAR(50) NOT NULL,       -- Free, Premium, School License
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    billing_cycle ENUM('monthly','yearly','one_time') DEFAULT 'monthly',
    description TEXT NULL
);

-- Table to store payment details
CREATE TABLE Payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NULL, 
    plan_id INT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    payment_method ENUM('mpesa','card','bank_transfer','other') NOT NULL,
    status ENUM('pending','completed','failed') NOT NULL DEFAULT 'pending',
    paid_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (plan_id) REFERENCES Subscription_Plans(plan_id) ON DELETE SET NULL
);

-- Students take assessments to get AI-driven career recommendations
CREATE TABLE Assessment_Types (
    assessment_type_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    code ENUM('interest','behavioral','technical','aptitude','skill') NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    delivery_mode ENUM('text_input','quiz','mcq','coding_test') NOT NULL DEFAULT 'text_input'
);

-- To store students assessment results
CREATE TABLE Assessments (
    assessment_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NOT NULL,
    assessment_type_id INT NOT NULL,
    responses JSON,
    result_summary TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (assessment_type_id) REFERENCES Assessment_Types(assessment_type_id) ON DELETE CASCADE
);

-- To store AI career path recommendations after assessment
CREATE TABLE Career_Paths (
    career_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    career_name VARCHAR(100) NOT NULL,
    assessment_id INT,
    description TEXT NULL,
    market_demand ENUM('low','medium','high') DEFAULT 'medium',
    FOREIGN KEY (assessment_id) REFERENCES Assessments(assessment_id)
);

-- Table for institutions, employers, or training organizations
CREATE TABLE Providers (
    provider_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    provider_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100) NULL,
    website VARCHAR(255) NULL,
    phone VARCHAR(50) NULL,
    description TEXT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Programs offered by providers
CREATE TABLE Reskilling_Programs (
    program_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    program_name VARCHAR(100) NOT NULL,
    provider_id INT NULL,
    description TEXT NULL,
    cost DECIMAL(10,2) DEFAULT 0.00,
    duration_weeks INT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (provider_id) REFERENCES Providers(provider_id) ON DELETE SET NULL
);

-- For college graduates only
CREATE TABLE Scholarships (
    scholarship_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    scholarship_name VARCHAR(200) NOT NULL,
    provider_id INT NULL,
    eligibility TEXT NULL,
    amount DECIMAL(10,2) NULL,
    application_deadline DATE NULL,
    FOREIGN KEY (provider_id) REFERENCES Providers(provider_id) ON DELETE SET NULL
);

-- Track student applications for scholarships
CREATE TABLE Scholarship_Applications (
    scholarship_application_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NOT NULL,
    scholarship_id INT NOT NULL,
    application_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('applied','reviewed','accepted','rejected') DEFAULT 'applied',
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (scholarship_id) REFERENCES Scholarships(scholarship_id) ON DELETE CASCADE
);
-- Trigger: ensure only college graduates can apply for scholarships - enforce business logic
DELIMITER //
CREATE TRIGGER trg_scholarship_applications_before_insert
BEFORE INSERT ON Scholarship_Applications
FOR EACH ROW
BEGIN
	DECLARE edu_level ENUM('highschool','college');
    DECLARE user_role ENUM('student','admin');

    SELECT role, education_level 
    INTO user_role, edu_level 
    FROM Users 
    WHERE user_id = NEW.user_id;

    IF NOT ( (user_role = 'student' AND edu_level = 'college') OR user_role = 'admin' ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only college graduates can apply for scholarships';
    END IF;
END;
//
DELIMITER ;

-- Track which students enroll in reskilling programs
CREATE TABLE Program_Enrollment (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NOT NULL,
    program_id INT NOT NULL,
    enrollment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('enrolled','in_progress','completed','dropped') DEFAULT 'enrolled',
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES Reskilling_Programs(program_id) ON DELETE CASCADE   
);
-- Trigger: ensure only college graduates can enroll in reskilling programs - enforce business logic
DELIMITER //
CREATE TRIGGER trg_program_enrollment_before_insert
BEFORE INSERT ON Program_Enrollment
FOR EACH ROW
BEGIN
    DECLARE edu_level ENUM('highschool','college');
    DECLARE user_role ENUM('student','admin');

    SELECT role, education_level 
    INTO user_role, edu_level 
    FROM Users 
    WHERE user_id = NEW.user_id;

    IF NOT ( (user_role = 'student' AND edu_level = 'college') OR user_role = 'admin' ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only college graduates can enroll in reskilling programs';
    END IF;
END;
//
DELIMITER ;

-- Track student progress in reskilling programs
CREATE TABLE User_Progress (
    progress_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NOT NULL,
    program_id INT NOT NULL,
    progress_percent DECIMAL(5,2) DEFAULT 0.00,
    last_updated DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (program_id) REFERENCES Reskilling_Programs(program_id) ON DELETE CASCADE
);

-- Jobs connected to career paths and providers
CREATE TABLE Jobs (
    job_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    job_title VARCHAR(100) NOT NULL,
    provider_id INT NULL,
    career_id INT NULL,
    description TEXT NULL,
    location VARCHAR(100) NULL,
    salary_range VARCHAR(50) NULL,
    posted_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (provider_id) REFERENCES Providers(provider_id) ON DELETE SET NULL,
    FOREIGN KEY (career_id) REFERENCES Career_Paths(career_id) ON DELETE SET NULL
);

-- Track student applications for jobs
CREATE TABLE Job_Applications (
    job_application_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NOT NULL,
    job_id INT NOT NULL,
    application_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('applied','reviewed','accepted','rejected') DEFAULT 'applied',
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id) ON DELETE CASCADE
);
-- Trigger: ensure only college graduates can apply for jobs - enforce business logic
DELIMITER //
CREATE TRIGGER trg_job_applications_before_insert
BEFORE INSERT ON Job_Applications
FOR EACH ROW
BEGIN
    DECLARE edu_level ENUM('highschool','college');
    DECLARE user_role ENUM('student','admin');

    SELECT role, education_level 
    INTO user_role, edu_level 
    FROM Users 
    WHERE user_id = NEW.user_id;

    IF NOT ( (user_role = 'student' AND edu_level = 'college') OR user_role = 'admin' ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only college graduates can apply for jobs';
    END IF;
END;
//
DELIMITER ;

-- Audit logs - to track important actions by users or admins for accountability, debugging, and compliance
CREATE TABLE Audit_Logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    user_id INT NULL,
    action_type ENUM('login','payment','assessment','apply_job','apply_scholarship','update_profile','other') NOT NULL,
    details TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES Users(user_id) ON DELETE SET NULL
);
