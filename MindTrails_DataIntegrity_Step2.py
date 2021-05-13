import pandas as pd
import numpy as np
import time

'''
Get task log from database

SQL Code to get table from Grafana or directly from the database

CALM DATABASE
TET:
SELECT A.date_completed,A.session_name,A.tag,A.task_name,A.study_id,B.participantID,C.study_extension
FROM task_log A 
LEFT JOIN (SELECT id AS participantID, study_id FROM participant
WHERE test_account = 0 AND admin = 0) B ON A.study_id = B.study_id
LEFT JOIN (SELECT id, study_extension FROM study) C ON A.study_id = C.id
WHERE study_extension LIKE 'TET' AND participantID >= 2010;

GIDI:
SELECT A.date_completed,A.session_name,A.tag,A.task_name,A.study_id,B.participantID,C.study_extension
FROM task_log A 
LEFT JOIN (SELECT id AS participantID, study_id FROM participant
WHERE test_account = 0 AND admin = 0) B ON A.study_id = B.study_id
LEFT JOIN (SELECT id, study_extension FROM study) C ON A.study_id = C.id
WHERE study_extension LIKE 'GIDI' AND participantID >= 2010;

KAISER DATABASE
KAISER:
SELECT A.date_completed,A.session_name,A.tag,A.task_name,A.study_id,B.participantID
FROM task_log A
LEFT JOIN (SELECT id AS participantID, study_id FROM participant) B ON A.study_id = B.study_id
WHERE participantID >= 34


EXPORT TASK LOG DATA FOR STUDY INTO A CSV FILE
'''
#Input study that is going to be checked
study_to_check = input("Which study to you want to check? TET,GIDI,KAISER,SPANISH: ")

#read data from csv file
#change this to the file of the study that is being checked
task_log_df = pd.read_csv("KAISER-TaskLog-data-2021-04-21 18_03_27.csv")

#we create a new column named Task
#combined the tag with the task_name, it only affects the Affect task name. Changes it to preAffect of postAffect
task_log_df["Task"] = task_log_df["tag"].fillna('')+task_log_df["task_name"]

#imake df with the important columns for the data integrity check
#we could probably skip this step by extracting only those columns from the SQL database
df_task = task_log_df[["study_id","participantID","date_completed","session_name","Task"]]


'''
We are going to hardcode the study structure

Based on the MT Program Schedule files for TET,GIDI,KAISER,SPANISH

If it changes throughout the study for some reason then we will have to adjust the code as well

Important changes affecting study order for TET and GIDI
Taken from the Issues and Changes Log

#4/7/2020 TET study Launched
#4/23/2020 Covid-19 questionnaire added preTest
#5/8/2020 OA added to eligibility
#5/12/2020 OA is removed from preTest
#7/10/2020 GIDI study launched
#12/07/2020 GIDI study disabled, no new accounts can be created
'''
#study session dictionary
#dictionary to store sessions in a study
study_session_order = dict()

'''
----------------------------------
TET
----------------------------------
'''
# create task structure for TET
#dictionary to store tasks in a session
tet_session_task_order = dict()

#I commented out Eligibility since the participant can retake the DASS or OA multiple times
#Maybe it would be better to check if the participant completed eligibility or if they did the DASS and OA at least once
#tet_session_task_order["Eligibility"] =np.array(["DASS21_AS","OA"])

tet_session_task_order["preTest"] = np.array(["Credibility","Demographics","MentalHealthHistory","AnxietyIdentity","AnxietyTriggers",
                                          "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","TechnologyUse"])

tet_session_task_order["firstSession"] = np.array(["preAffect","1","postAffect","CC","SessionReview","OA","CoachPrompt","Gidi","ReturnIntention"])

tet_session_task_order["secondSession"] = np.array(["2","SessionReview","OA","ReturnIntention"])

tet_session_task_order["thirdSession"] = np.array(["preAffect","3","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                               "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","ReturnIntention"])

tet_session_task_order["fourthSession"] = np.array(["4","SessionReview","OA","ReturnIntention"])

tet_session_task_order["fifthSession"] = np.array(["preAffect","5","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                               "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking",
                                               "Evaluation","AssessingProgram"])

tet_session_task_order["PostFollowUp"] = np.array(["AnxietyIdentity","OA","DASS21_AS",
                                               "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"])

#store session task order in study_session_order dictionary
study_session_order["TET"] = tet_session_task_order

'''
----------------------------------
GIDI
----------------------------------
'''
# create task structure for GIDI
#dictionary to store tasks in a session
gidi_session_task_order = dict()

#I commented out Eligibility since the participant can retake the DASS or OA multiple times
#Maybe it would be better to check if the participant completed eligibility or if they did the DASS and OA at least once
#gidi_session_task_order["Eligibility"] =np.array(["OA","DASS21_AS"])

gidi_session_task_order["preTest"] = np.array(["Credibility","Demographics","MentalHealthHistory","AnxietyIdentity","AnxietyTriggers",
                                          "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","TechnologyUse"])

gidi_session_task_order["firstSession"] = np.array(["preAffect","1","postAffect","CC","SessionReview","OA","CoachPrompt","Gidi","ReturnIntention"])

gidi_session_task_order["secondSession"] = np.array(["2","SessionReview","OA","ReturnIntention"])

gidi_session_task_order["thirdSession"] = np.array(["preAffect","3","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                               "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","ReturnIntention"])

gidi_session_task_order["fourthSession"] = np.array(["4","SessionReview","OA","ReturnIntention"])

gidi_session_task_order["fifthSession"] = np.array(["preAffect","5","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                               "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking",
                                               "Evaluation","AssessingProgram"])

gidi_session_task_order["PostFollowUp"] = np.array(["AnxietyIdentity","OA","DASS21_AS",
                                               "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"])

gidi_session_task_order["PostFollowUp2"] = np.array(["AnxietyIdentity","OA","DASS21_AS",
                                               "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"])

#store session task order in study_session_order dictionary
study_session_order["GIDI"] = gidi_session_task_order

'''
----------------------------------
KAISER
----------------------------------
'''
# create task structure for Kaiser
#dictionary to store tasks in a session
kaiser_session_task_order = dict()

kaiser_session_task_order["preTest"] = np.array(["Identity","Credibility","Demographics","MentalHealthHistory","OA","DASS21_AS",
                                                 "AnxietyTriggers","recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","TechnologyUse"])

kaiser_session_task_order["firstSession"] = np.array(["preAffect","1","postAffect","CC","SessionReview","OA","CoachPrompt","ReturnIntention"])

kaiser_session_task_order["secondSession"] = np.array(["2","SessionReview","OA","ReturnIntention"])

kaiser_session_task_order["thirdSession"] = np.array(["preAffect","3","postAffect","CC","SessionReview","OA","DASS21_AS",
                                               "recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","ReturnIntention"])

kaiser_session_task_order["fourthSession"] = np.array(["4","SessionReview","OA","ReturnIntention"])

kaiser_session_task_order["fifthSession"] = np.array(["preAffect","5","postAffect","CC","SessionReview","OA","DASS21_AS",
                                               "recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking",
                                               "Evaluation","AssessingProgram"])

kaiser_session_task_order["PostFollowUp"] = np.array(["OA","DASS21_AS",
                                               "recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"])

#store session task order in study_session_order dictionary
study_session_order["KAISER"] = kaiser_session_task_order

'''
----------------------------------
SPANISH
----------------------------------
'''
# create task structure for Spanish
#dictionary to store tasks in a session
spanish_session_task_order = dict()

spanish_session_task_order["Eligibility"] =np.array(["OA","DASS21_AS"])

spanish_session_task_order["preTest"] = np.array(["Demographics","MentalHealthHistory","Acculturation","Ethnicity"
                                                  "Comorbid", "recognitionRatings","RR","Covid19","preAffect","1","postAffect","CC"])

spanish_session_task_order["secondSession"] = np.array(["preAffect","2","postAffect","OA","Comorbid","DASS21_AS","recognitionRatings","RR","Evaluation"])

#store session task order in study_session_order dictionary
study_session_order["SPANISH"] = spanish_session_task_order


'''
----------------------------------
DATA INTEGRITY STEP 2
----------------------------------
'''



#remove task_name SESSION_COMPLETE that just indicates if you completed all tasks in the session and is not a specific task in the study
df_taskLog = df_task[df_task["Task"] != "SESSION_COMPLETE"]

#take into account all sessions except Eligibility
df_taskLog = df_taskLog[df_taskLog["session_name"] != "Eligibility"]

#store distinct participant IDs found in the task log
participant_ids = df_taskLog["participantID"].unique()

#list to add participant ids and sessions that do not match study task sequence order
flagged_ps_session = list()

# loop over each participant in study
for p in participant_ids:
    # get participant task information and store in df
    df_p = df_taskLog[df_taskLog["participantID"] == p]

    study_id_p = df_p["study_id"].unique()
    #get participant study_id
    study_id = np.max(study_id_p)

    # get sessions that participant has completed or is currently working on
    p_sessions = df_p["session_name"].unique()

    #store sessions in an array
    p_sessions_array = np.array(p_sessions)
    #calculate length of sessions array
    lenght_p_sessions = len(p_sessions_array)

    #get sessions for study using the dictionary keys values in study_session_order
    study_sessions_list = list(study_session_order[study_to_check].keys())

    #store study_sessions_list in an array
    study_sessions_array = np.array(study_sessions_list)

    #if the participant session order is not the same as the study session order then flag
    #checking to see if the participant skipped a session
    if not np.array_equal(p_sessions_array, study_sessions_array[:lenght_p_sessions]):
        # difference between the two sets, set1 - set2
        diff1 = np.setdiff1d(p_sessions_array, study_sessions_array[:lenght_p_sessions])

        # difference between the two sets, set2- set1
        diff2 = np.setdiff1d(study_sessions_array[:lenght_p_sessions], p_sessions_array)

        #store in list
        differences = [diff1, diff2]

        #calculate the difference between the two arrays
        length_diff = lenght_p_sessions - len(study_sessions_array[:lenght_p_sessions])

        #append information to flagged list
        flagged_ps_session.append(
            [p,study_id, "SessionOrder", length_diff, differences[0], differences[1], None, study_sessions_array, p_sessions_array])

    #loop over each session that the participant has completed or is currently working on
    for session in p_sessions:
        #get participant information for the specific session
        p_session_tasks = df_p[df_p["session_name"] == session]

        #order the values based on completion date
        p_session_tasks.sort_values(by=['date_completed'], ascending=True)

        #store ordered task in array
        p_ordered_tasks = np.array(p_session_tasks["Task"])

        #calculate the length of the array
        length_tasks = len(p_ordered_tasks)

        #get the max date from the tasks that were completed in a session
        #we will use this to check with the dates when changes were made to the study session task structure
        max_date = p_session_tasks.date_completed.max()

        #check to see if participant task array matches the study ordered task array
        #if not flag participant id and session
        if not np.array_equal(p_ordered_tasks, study_session_order[study_to_check][session][:length_tasks]):
            #difference between the two sets, set1 - set2
            diff1 = np.setdiff1d(p_ordered_tasks, study_session_order[study_to_check][session][:length_tasks])

            #difference between the two sets, set2- set1
            diff2 = np.setdiff1d(study_session_order[study_to_check][session][:length_tasks], p_ordered_tasks)

            #store in list
            differences = [diff1, diff2]

            #calculate the difference between the two arrays
            length_diff = length_tasks - len(study_session_order[study_to_check][session][:length_tasks])

            #append information to flagged list
            flagged_ps_session.append([p,study_id, session, length_diff, differences[0], differences[1], max_date,
                                       study_session_order[study_to_check][session][:], p_ordered_tasks])

#store flagged information in df
report_df = pd.DataFrame(flagged_ps_session,
                         columns=["ParticipantID","StudyID", "Session", "PTaskLength", "Diff_P_S", "Diff_S_P", "Last_Date",
                                  "SessionOrder", "ParticipantOrder"])
#change date column to datetime type
report_df['Last_Date'] = pd.to_datetime(report_df['Last_Date'])
#change array difference to string type
#mainly to avoid errors when using these columns later on
report_df['Diff_P_S'] = report_df['Diff_P_S'].astype(str)
report_df['Diff_S_P'] = report_df['Diff_S_P'].astype(str)

#the current code will flag participans in TET since changes to the study structure were made throughout the course of the study
#we could also ignore this and just identify in the report file that the flag p is appearing because of the changes in the study structure
#for now TET is the only study where we have to do this
if study_to_check == "TET":
    #4/7/2020 TET study Launched
    #4/23/2020 Covid-19 questionnaire added preTest
    #5/8/2020 OA added to eligibility
    #5/12/2020 OA is removed from preTest
    #7/10/2020 GIDI study launched
    #12/07/2020 GIDI study disabled, no new accounts can be created

    #7/10/2020 GIDI study launched
    #participants who started TET before GIDI launched and therefore do not have GIDI in their tasks for the first session
    report_index = np.array(report_df[(report_df["Diff_S_P"] == "['Gidi']") & (
                report_df["Diff_P_S"] == "['ReturnIntention']") & (report_df["Last_Date"] < "2020-08-10")].index)

    #remove those cases from list
    report_df = report_df.drop(report_index)

    #12/07/2020 GIDI study disabled, no new accounts can be created
    #participants who enrolled in TET after GIDI study disabled and therefore do not have GIDI in their tasks for the first session
    report_index_2 = np.array(report_df[(report_df["Diff_S_P"] == "['Gidi']") & (
                report_df["Diff_P_S"] == "['ReturnIntention']") & (report_df["Last_Date"] > "2020-12-07")].index)

    #remove those cases from list
    report_df = report_df.drop(report_index_2)

    #participants who started TET with OA in preTest which was removed on 5/12/2020 and COVID 19 Q which was added on 4/23/2020. Remove any flagged id before 4/23/2020
    #since they are supposed to have OA and no Covid19 Q
    report_index_3 = np.array(report_df[
                                  (report_df["Diff_S_P"] == "['Covid19']") & (report_df["Diff_P_S"] == "['OA']") & (
                                              report_df["Last_Date"] < "2020-04-23")].index)
    #remove those cases from list
    report_df = report_df.drop(report_index_3)

    #5/12/2020 OA is removed from preTest
    report_index_4 = np.array(
        report_df[(report_df["Diff_P_S"] == "['OA']") & (report_df["Last_Date"] < "2020-05-12")].index)

    #remove those cases from list
    report_df = report_df.drop(report_index_4)

#save report to CSV file
report_df.to_csv('{}_{}_DataIntegrityS2_Report.csv'.format(study_to_check, time.strftime("%Y%m%d")), index=False)