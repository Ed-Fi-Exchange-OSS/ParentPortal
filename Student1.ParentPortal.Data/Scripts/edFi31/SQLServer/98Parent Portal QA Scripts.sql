/****** Script for SelectTopNRows command from SSMS  ******/
-- PARENT PORTAL QA SCRIPTS --

-- Mapping users to parents.
SELECT * FROM edfi.ParentElectronicMail where ElectronicMailAddress = 'douglasloyo@gmail.com'
UPDATE edfi.ParentElectronicMail set ElectronicMailAddress = 'almaarzate12@gmail.com' WHERE ElectronicMailAddress = 'douglasloyo@gmail.com'
UPDATE edfi.ParentElectronicMail set ElectronicMailAddress = 'douglasloyo@gmail.com' WHERE ElectronicMailAddress = 'chavez.maria513827@gmail.com'
--UPDATE edfi.StaffElectronicMail set ElectronicMailAddress = 'alexander.kim@toolwise.onmicrosoft.com' where ElectronicMailAddress = 'Mallory.Bernardo@yesprep.org'

SELECT count(*) FROM [edfi].[School]; -- Schools should be > 0
SELECT count(*) FROM [edfi].[Student]; -- Students should be > 0
SELECT count(*) FROM [edfi].Parent; -- Parents should be > 0 and less than students or at least no a very big number.
SELECT count(*) FROM [edfi].Parent WHERE SexDescriptorId is not null; -- Count should be > 0. We should have Sex for Parents (but really sometimes we dont)
SELECT count(*) FROM [edfi].Student WHERE BirthSexDescriptorId is not null; -- Count should be > 0. We should have Sex for Students
Select count(*) from edfi.StudentParentAssociation;

-- Find Parents that have emails and kids associated. (These are candidates to be able to login with)
Select spa.ParentUSI, count(*) as StudentCount, pe.ElectronicMailAddress
from edfi.StudentParentAssociation spa
inner join edfi.student s on spa.StudentUSI = s.StudentUSI
inner join edfi.ParentElectronicMail pe on spa.ParentUSI = pe.ParentUSI
group by spa.ParentUSI, pe.ElectronicMailAddress
order by count(*) desc;

-- Find Students associated with parents that have basic required data. (Summary data)
SELECT count(*) FROM edfi.Student S
inner join edfi.SexDescriptor SD on S.BirthSexDescriptorId = SD.SexDescriptorId
inner join edfi.StudentParentAssociation SPA on S.StudentUSI = SPA.StudentUSI
inner join edfi.StudentSchoolAssociation SSA on S.StudentUSI = SSA.StudentUSI
inner join edfi.GradeLevelDescriptor GLD on SSA.EntryGradeLevelDescriptorId = GLD.GradeLevelDescriptorId
inner join edfi.School Sc on SSA.SchoolId = Sc.SchoolId
inner join edfi.EducationOrganization EO on Sc.SchoolId = EO.EducationOrganizationId;

-- Find Attendance Events
SELECT --COUNT(*)
D.CodeValue, D.Description
FROM edfi.StudentSchoolAttendanceEvent SSAE
INNER JOIN edfi.SchoolYearType SY on SSAE.SchoolYear = SY.SchoolYear
INNER JOIN edfi.AttendanceEventCategoryDescriptor AECD on SSAE.AttendanceEventCategoryDescriptorId = AECD.AttendanceEventCategoryDescriptorId
INNER JOIN edfi.Descriptor D on AECD.AttendanceEventCategoryDescriptorId = D.DescriptorId
WHERE SY.CurrentSchoolYear=1;


-- Find Missing Assignments - Count should be > 0
SELECT COUNT(*) FROM edfi.GradebookEntry GBE
INNER JOIN edfi.Descriptor D on GBE.GradebookEntryTypeDescriptorId = D.DescriptorId
INNER JOIN edfi.CourseOffering CO on GBE.LocalCourseCode = CO.LocalCourseCode and GBE.SchoolId = CO.SchoolId and GBE.SchoolYear = CO.SchoolYear and GBE.SessionName = GBE.SessionName
INNER JOIN edfi.Course C on CO.EducationOrganizationId = C.EducationOrganizationId and CO.CourseCode = C.CourseCode
INNER JOIN edfi.SchoolYearType SY on GBE.SchoolYear = SY.SchoolYear
LEFT JOIN edfi.StudentGradebookEntry SGBE on SGBE.DateAssigned = gbe.DateAssigned
                                              and SGBE.GradebookEntryTitle = gbe.GradebookEntryTitle
                                              and SGBE.LocalCourseCode = gbe.LocalCourseCode
                                              and SGBE.SchoolId = gbe.SchoolId
                                              and SGBE.SchoolYear = gbe.SchoolYear
                                              and SGBE.SectionIdentifier = gbe.SectionIdentifier
                                              and SGBE.SessionName = gbe.SessionName
WHERE SGBE.DateFulfilled is null
      and GBE.GradebookEntryTypeDescriptorId is not null
	  and D.CodeValue in ('HMWK');

-- Course Grades
-- GPA
SELECT COUNT(*) FROM edfi.StudentAcademicRecord; -- Should be > 0. We should have academic records for students
SELECT COUNT(*) FROM edfi.StudentAcademicRecord WHERE CumulativeGradePointAverage is null; -- Should be less than the total records above.
SELECT COUNT(*) FROM edfi.StudentAcademicRecord WHERE CumulativeGradePointAverage is not null; -- Should be greater than 0 and as close as possible to the normal count of records.

-- Grades by Grading Period
SELECT COUNT(*) FROM edfi.StaffSectionAssociation;
SELECT COUNT(*) FROM edfi.Grade; -- Should be > 0
SELECT COUNT(*) FROM edfi.Grade GRA -- Should be > 0
Inner Join edfi.GradeTypeDescriptor GTD on GRA.GradeTypeDescriptorId = GTD.GradeTypeDescriptorId
INNER JOIN edfi.Descriptor D on GTD.GradeTypeDescriptorId = D.DescriptorId
WHERE D.CodeValue in ('Grading Period', 'Semester', 'Final');

SELECT * FROM edfi.Grade where StudentUSI = 2160; -- Should be > 0

SELECT COUNT(*) 
FROM edfi.Grade GRA
INNER JOIN edfi.SchoolYearType SY on GRA.SchoolYear = SY.SchoolYear
INNER JOIN edfi.StaffSectionAssociation SSA on 
	GRA.LocalCourseCode = SSA.LocalCourseCode and GRA.SchoolId = SSA.SchoolId and GRA.SchoolYear=SSA.SchoolYear and GRA.SectionIdentifier=SSA.SectionIdentifier and  GRA.SessionName = SSA.SessionName
WHERE StudentUSI = 2160; -- Should be > 0

-- All grading periods in general
select count(g.LocalCourseCode), d.ShortDescription from edfi.Grade as g 
inner join edfi.Descriptor as d on GradingPeriodDescriptorId = DescriptorId
where GradingPeriodSchoolYear = 2019
group by d.ShortDescription;

-- All grading periods from a student
select count(g.LocalCourseCode), d.ShortDescription from edfi.Grade as g 
inner join edfi.Descriptor as d on GradingPeriodDescriptorId = DescriptorId
where GradingPeriodSchoolYear = 2019 and g.StudentUSI = 451
group by d.ShortDescription;


-- Schedule 
SELECT --COUNT(*) -- Count should be > 0
SEC.SessionName, SSA.BeginDate, SSA.EndDate, C.CourseTitle, BSN.BellScheduleName, BSD.Date, CPMT.StartTime, CPMT.EndTime,SEC.LocationClassroomIdentificationCode,s.FirstName, s.MiddleName, s.LastSurname
FROM edfi.section SEC 
INNER JOIN edfi.SchoolYearType SY on SEC.SchoolYear=SY.SchoolYear
INNER JOIN edfi.SectionClassPeriod SCP on SEC.LocalCourseCode = SCP.LocalCourseCode and SEC.SchoolId = SCP.SchoolId and SEC.SchoolYear = SCP.SchoolYear and SEC.SectionIdentifier = SCP.SectionIdentifier and SEC.SessionName = SCP.SessionName
INNER JOIN edfi.StudentSectionAssociation SSA on SEC.SchoolId = SSA.SchoolId and SEC.LocalCourseCode = SSA.LocalCourseCode and SEC.SessionName=SSA.SessionName and SEC.SchoolYear=SSA.SchoolYear and SEC.SectionIdentifier=SSA.SectionIdentifier
INNER JOIN edfi.CourseOffering CO on SEC.SchoolId = CO.SchoolId and SEC.LocalCourseCode=CO.LocalCourseCode and SEC.SessionName=CO.SessionName and SEC.SchoolYear=CO.SchoolYear
INNER JOIN edfi.Course C on CO.SchoolId=C.EducationOrganizationId and CO.CourseCode = C.CourseCode
INNER JOIN edfi.BellScheduleClassPeriod BSN on SCP.ClassPeriodName = BSN.ClassPeriodName and SCP.SchoolId=BSN.SchoolId
INNER JOIN edfi.BellScheduleDate BSD on BSN.BellScheduleName=BSD.BellScheduleName and BSN.SchoolId=BSD.SchoolId
INNER JOIN edfi.ClassPeriodMeetingTime CPMT on SCP.SchoolId = CPMT.SchoolId and SCP.ClassPeriodName = CPMT.ClassPeriodName
INNER JOIN edfi.StaffSectionAssociation STAFFSA on SEC.SchoolId = STAFFSA.SchoolId and SEC.LocalCourseCode=STAFFSA.LocalCourseCode and SEC.SectionIdentifier = STAFFSA.SectionIdentifier and SEC.SessionName = STAFFSA.SessionName and SEC.SchoolYear = STAFFSA.SchoolYear
INNER JOIN edfi.Staff S on STAFFSA.StaffUsi = S.StaffUsi
WHERE SY.CurrentSchoolYear=1 and StudentUSI = 2160 and BSD.Date between '2019-5-13' and '2019-5-17' --and SSA.EndDate >= '2019-5-15'
order by BSD.Date, CPMT.StartTime

-- Student Assessments
SELECT --COUNT(*)
distinct A.AssessmentTitle
FROM edfi.Assessment A 
INNER JOIN edfi.StudentAssessment SA on A.AssessmentIdentifier= SA.AssessmentIdentifier and A.Namespace =SA.Namespace




SELECT * FROM edfi.Descriptor WHERE Namespace like '%GradeType%';
Update edfi.Student set BirthSexDescriptorId = 721;


select Count(*) from edfi.StaffSectionAssociation;
select Count(*) from edfi.StaffSectionAssociation WHERE BeginDate is null and EndDate is null;


SELECT --COUNT(*) 
A.AssessmentTitle, SA.StudentUSI, ARMDT.CodeValue, SASR.Result, SA.AdministrationDate
FROM edfi.StudentAssessment SA
INNER JOIN edfi.StudentAssessmentScoreResult SASR on sa.AssessmentIdentifier = SASR.AssessmentIdentifier and sa.Namespace=SASR.Namespace and sa.StudentAssessmentIdentifier=SASR.StudentAssessmentIdentifier and sa.StudentUsi=SASR.StudentUSI
INNER JOIN edfi.AssessmentReportingMethodDescriptor ARMD on SASR.AssessmentReportingMethodDescriptorId = ARMD.AssessmentReportingMethodDescriptorId
INNER JOIN edfi.Descriptor ARMDT on ARMD.AssessmentReportingMethodDescriptorId = ARMDT.DescriptorId
INNER JOIN edfi.Assessment A on sa.AssessmentIdentifier=A.AssessmentIdentifier and sa.Namespace=A.Namespace
LEFT JOIN edfi.StudentAssessmentPerformanceLevel SAPL on SA.StudentUSI = SAPL.StudentUSI and SA.AssessmentIdentifier = SAPL.AssessmentIdentifier and SA.StudentAssessmentIdentifier = SAPL.StudentAssessmentIdentifier and SA.Namespace = SAPL.Namespace and SAPL.PerformanceLevelMet=1
LEFT JOIN edfi.PerformanceLevelDescriptor PLD on SAPL.PerformanceLevelDescriptorId = PLD.PerformanceLevelDescriptorId
LEFT JOIN edfi.Descriptor PLT on PLD.PerformanceLevelDescriptorId = PLT.DescriptorId
WHERE A.AssessmentTitle = 'STAAR'
ORDER BY SA.StudentUSI