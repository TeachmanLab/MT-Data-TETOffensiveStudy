#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 14 12:24:27 2021

@author: soniabaee
"""

import sys, os, glob, argparse
import numpy as np
import time
import pandas as pd
import matplotlib.pyplot as plt
from collections import defaultdict, OrderedDict


import mysql.connector

from datetime import date
random_state = 4444

plt.rcParams['figure.figsize'] = [20, 8]  # Bigger images


class data_integrity:
    def __init__(self, args):
        
        self.host = args.host
        self.user = args.user
        self.password = args.password
        self.database = args.database
        self.auth_plugin = args.auth_plugin
        
        self.mydb = ''
        
        self.data_directory = args.directory
        self.input_dir = args.input_dir
        
        self.study = args.study
        self.data = pd.DataFrame()
        self.data_summary = pd.DataFrame()
        
        self.flagged_ps_session = []
        self.flagg_study_id = []
        
        self.tasks = []
        self.dataset_dfs = OrderedDict()
        self.study_session_order = defaultdict()
        
        self.output_dir = args.output_dir
        self.report = pd.DataFrame()
        
    def connect_database(self):
        '''       
        Returns
        -------
        mydb : TYPE
            DESCRIPTION.

        '''
        mydb = mysql.connector.connect(
            host=self.host,
            user=self.user,
            password= self.password,
            database=self.database,
            auth_plugin = self.auth_plugin
            )

        self.mydb = mydb
        
        return mydb
    
    def get_data_tables(self):
        '''
        

        Returns
        -------
        dataset_dfs : TYPE
            DESCRIPTION.

        '''
        
        mydb = self.mydb
        study_name = self.study
        
        task_tables = defaultdict(list)
        if study_name == 'TET':
            ## extract all the tables in this dataset
            query = "show tables;"
            task_tables = pd.read_sql_query(query,mydb)
            
            self.tasks = task_tables
            #exclude log and administrative tables except action_log
            task_tables = task_tables[~task_tables.Tables_in_calm.isin(["attrition_prediction", "coach_log", 
                                                                        "condition_assignment_settings", "data",
                                                                       "demographics_race", "error_log",
                                                                       "evaluation_coach_help_topics", "evaluation_devices",
                                                                       "evaluation_how_learn", "evaluation_places",
                                                                       "evaluation_preferred_platform", 
                                                                       "evaluation_reasons_control",
                                                                       "export_log", "gift_log", "id_gen", "import_log", "media",
                                                                       "mental_health_change_help",
                                                                       "mental_health_disorders",
                                                                       "mental_health_help",
                                                                       "mental_health_why_no_help",
                                                                       "missing_data_log",
                                                                       "password_token",
                                                                       "random_condition",
                                                                       "reasons_for_ending_change_med",
                                                                       "reasons_for_ending_device_use",
                                                                       "reasons_for_ending_location",
                                                                       "reasons_for_ending_reasons",
                                                                       "session_review_distractions",
                                                                       "sms_log", "stimuli", "verification_code", "visit"])]
        
            
            dataset_dfs = OrderedDict()
            
            ## overview of each table in the study
            for tbl in task_tables.values:
                tblName = tbl
                print("--------------------------------------")
                print("The name of the table is: {}".format(tblName[0]))
                select_query = "select * from {}".format(tblName[0])
                df = pd.read_sql_query(select_query,mydb)
                dataset_dfs[tblName[0]] = df
                print("--------------------------------------")
                if tblName[0] != 'participant':
                    query = "select count(distinct(study_id)) as freq,  count(distinct session_name) as sessions from task_log where task_name = '{}' " \
                              "and study_id in (select id from calm.study where study_extension = {} and id in (select study_id from participant where test_account = 0 and admin = 0))".format(tblName[0], repr(study_name))
                    data = pd.read_sql_query(query,mydb)
                    if data['freq'].values[0] > 0:
                        print("The name of the table is: {} \nthe frequency values: {} \nthe number of sessions:  {}".format(tblName[0],data['freq'].values[0],data['sessions'].values[0]))
                        print("--------------------------------------")
            
            
                    query ="SELECT study_id, session_name, COUNT(*) as count from task_log where task_name = '{}' " \
                              "and study_id in (select id from calm.study where study_extension = {} and id in (select study_id from participant where test_account = 0 and admin = 0)) " \
                                "GROUP BY study_id, session_name HAVING COUNT(*) > 1;".format(tblName[0], repr(study_name))
                    data = pd.read_sql_query(query,mydb)
                    if data.shape[0] > 0:
                        print("The name of the table is: {} \nthe study_id: {} \nthe session:  {} \nthe number of duplications:  {}".format(tblName[0],data['study_id'].values[0],data['session_name'].values[0], data['count'].values[0]))
                        print("--------------------------------------")
            
                    query = ""
                    if tblName[0] == 'action_log':
                        query = " select count(distinct participant_id) as freq, count(distinct session_name) as count_session from {} " \
                                "where participant_id in (select id from participant where study_id in (select id from study where study_extension = {}) and test_account = 0 and admin = 0);".format(tblName[0], repr(study_name))
                    elif tblName[0] == 'study':
                        query = " select count(distinct id) as freq, count(distinct current_session) as count_session from {} " \
                                "where id in (select study_id from participant where study_id in (select id from study where study_extension = {}) and test_account = 0 and admin = 0);".format(tblName[0], repr(study_name))
                    elif tblName[0] == 'task_log':
                        query = " select count(distinct id) as freq, count(distinct session_name) as count_session from {} " \
                                "where id in (select study_id from participant where study_id in (select id from study where study_extension = {}) and test_account = 0 and admin = 0);".format(tblName[0], repr(study_name))
                    else:
                        query = " select count(distinct participant_id) as freq, count(distinct session) as count_session from {} " \
                                "where participant_id in (select id from participant where study_id in (select id from study where study_extension = {}) and test_account = 0 and admin = 0);".format(tblName[0], repr(study_name))
                    data = pd.read_sql_query(query,mydb)
                    if data.shape[0] > 0:
                        print("The name of the table is: {} \nthe frequency: {} \nthe number of sessions:  {} ".format(tblName[0],data['freq'].values[0],data['count_session'].values[0]))
                        print("--------------------------------------")
                    
                    
                    if tblName[0] == 'action_log':
                        query = " SELECT participant_id, session_name, COUNT(*) as dup FROM {} " \
                                  "where participant_id in (select id from participant where study_id in (select id from study where study_extension = 'TET') and test_account = 0 and admin = 0) " \
                                    "GROUP BY participant_id, session_name HAVING COUNT(*) > 1;".format(tblName[0], repr(study_name))
                    elif tblName[0] == 'study':
                        query = " SELECT id, current_session, COUNT(*) as dup FROM {} " \
                                  "where id in (select study_id from participant where study_id in (select id from study where study_extension = 'TET') and test_account = 0 and admin = 0) " \
                                    "GROUP BY id, current_session HAVING COUNT(*) > 1;".format(tblName[0], repr(study_name))
                    elif tblName[0] == 'task_log':
                        query = " SELECT id, session_name, COUNT(*) as dup FROM {} " \
                              "where id in (select id from participant where study_id in (select id from study where study_extension = 'TET') and test_account = 0 and admin = 0) " \
                                "GROUP BY id, session_name HAVING COUNT(*) > 1;".format(tblName[0], repr(study_name))
                    else:
                        query = " SELECT participant_id, session, COUNT(*) as dup FROM {} " \
                              "where participant_id in (select id from participant where study_id in (select id from study where study_extension = 'TET') and test_account = 0 and admin = 0) " \
                                "GROUP BY participant_id, session HAVING COUNT(*) > 1;".format(tblName[0], repr(study_name))
                    data = pd.read_sql_query(query,mydb)
                    if data.shape[0] > 0:
                        print("The name of the table is: {} \nthe participant/study id: {} \nthe number of sessions:  {} \nthe number of duplication: {} ".format(tblName[0],data.iloc[:,0].values[0],data.iloc[:,1].values[0], data['dup'].values[0]))
                        print("--------------------------------------")
        
        self.dataset_dfs = dataset_dfs
        
        return dataset_dfs


    def TET_structure(self):
        '''
        
        Returns
        -------
        tet_session_task_order : TYPE
            DESCRIPTION.

        '''
        
        
        # create task structure for TET
        #dictionary to store tasks in a session
        tet_session_task_order = defaultdict(list)
        
        #I commented out Eligibility since the participant can retake the DASS or OA multiple times
        #Maybe it would be better to check if the participant completed eligibility or if they did the DASS and OA at least once
        #tet_session_task_order["Eligibility"] =np.array(["DASS21_AS","OA"])
        
        tet_session_task_order["preTest"] = ["Credibility","Demographics","MentalHealthHistory","AnxietyIdentity","AnxietyTriggers",
                                                  "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","TechnologyUse"]
        
        tet_session_task_order["firstSession"] = ["preAffect","1","postAffect","CC","SessionReview","OA","CoachPrompt","Gidi","ReturnIntention"]
        
        tet_session_task_order["secondSession"] = ["2","SessionReview","OA","ReturnIntention"]
        
        tet_session_task_order["thirdSession"] = ["preAffect","3","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                                       "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","ReturnIntention"]
        
        tet_session_task_order["fourthSession"] = ["4","SessionReview","OA","ReturnIntention"]
        
        tet_session_task_order["fifthSession"] = ["preAffect","5","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                                       "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking",
                                                       "Evaluation","AssessingProgram"]
        
        tet_session_task_order["PostFollowUp"] = ["AnxietyIdentity","OA","DASS21_AS",
                                                       "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"]
        
        
        return tet_session_task_order
    
    def GIDI_structure(self):
        '''
        
        Returns
        -------
        gidi_session_task_order : TYPE
            DESCRIPTION.

        '''
        
        # create task structure for GIDI
        #dictionary to store tasks in a session
        gidi_session_task_order = defaultdict()
        
        #I commented out Eligibility since the participant can retake the DASS or OA multiple times
        #Maybe it would be better to check if the participant completed eligibility or if they did the DASS and OA at least once
        #gidi_session_task_order["Eligibility"] =np.array(["OA","DASS21_AS"])
        
        gidi_session_task_order["preTest"] = ["Credibility","Demographics","MentalHealthHistory","AnxietyIdentity","AnxietyTriggers",
                                                  "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","TechnologyUse"]
        
        gidi_session_task_order["firstSession"] = ["preAffect","1","postAffect","CC","SessionReview","OA","CoachPrompt","Gidi","ReturnIntention"]
        
        gidi_session_task_order["secondSession"] = ["2","SessionReview","OA","ReturnIntention"]
        
        gidi_session_task_order["thirdSession"] = ["preAffect","3","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                                       "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","ReturnIntention"]
        
        gidi_session_task_order["fourthSession"] = ["4","SessionReview","OA","ReturnIntention"]
        
        gidi_session_task_order["fifthSession"] = ["preAffect","5","postAffect","CC","SessionReview","AnxietyIdentity","OA","DASS21_AS",
                                                       "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking",
                                                       "Evaluation","AssessingProgram"]
        
        gidi_session_task_order["PostFollowUp"] = ["AnxietyIdentity","OA","DASS21_AS",
                                                       "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"]
        
        gidi_session_task_order["PostFollowUp2"] = ["AnxietyIdentity","OA","DASS21_AS",
                                                       "recognitionRatings","RR","BBSIQ","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"]
        
        return gidi_session_task_order

    def Kaiser_structure(self):
        '''
        

        Returns
        -------
        kaiser_session_task_order : TYPE
            DESCRIPTION.

        '''
        
        # create task structure for Kaiser
        #dictionary to store tasks in a session
        kaiser_session_task_order = dict()
        
        kaiser_session_task_order["preTest"] = ["Identity","Credibility","Demographics","MentalHealthHistory","OA","DASS21_AS",
                                                         "AnxietyTriggers","recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","TechnologyUse"]
        
        kaiser_session_task_order["firstSession"] = ["preAffect","1","postAffect","CC","SessionReview","OA","CoachPrompt","ReturnIntention"]
        
        kaiser_session_task_order["secondSession"] = ["2","SessionReview","OA","ReturnIntention"]
        
        kaiser_session_task_order["thirdSession"] = ["preAffect","3","postAffect","CC","SessionReview","OA","DASS21_AS",
                                                       "recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","ReturnIntention"]
        
        kaiser_session_task_order["fourthSession"] = ["4","SessionReview","OA","ReturnIntention"]
        
        kaiser_session_task_order["fifthSession"] = ["preAffect","5","postAffect","CC","SessionReview","OA","DASS21_AS",
                                                       "recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking",
                                                       "Evaluation","AssessingProgram"]
        
        kaiser_session_task_order["PostFollowUp"] = ["OA","DASS21_AS", "recognitionRatings","RR","Comorbid","Wellness","Mechanisms","Covid19","HelpSeeking"]
        
        return kaiser_session_task_order
        
    def Spanish_structure(self):
        '''
        
        Returns
        -------
        spanish_session_task_order : TYPE
            DESCRIPTION.

        '''
        
        # create task structure for Spanish
        #dictionary to store tasks in a session
        spanish_session_task_order = defaultdict()
        
        spanish_session_task_order["Eligibility"] = ["OA","DASS21_AS"]
        
        spanish_session_task_order["preTest"] = ["Demographics","MentalHealthHistory","Acculturation","Ethnicity"
                                                          "Comorbid", "recognitionRatings","RR","Covid19","preAffect","1","postAffect","CC"]
        
        spanish_session_task_order["secondSession"] = ["preAffect","2","postAffect","OA","Comorbid","DASS21_AS","recognitionRatings","RR","Evaluation"] 
        
        return spanish_session_task_order

    def study_structure(self):
        '''
        
        Returns
        -------
        study_session_order : TYPE
            DESCRIPTION.

        '''
        
        
        #TODO: change to the parameter for maintanence
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
        study_session_order = self.study_session_order
        study_name = 'TET'
        study_session_order[study_name] = self.TET_structure()
        study_name = 'GIDI'
        study_session_order[study_name] = self.GIDI_structure()
        study_name = 'Kaiser'
        study_session_order[study_name] = self.Kaiser_structure()
        study_name = 'spanish'
        study_session_order[study_name] = self.Spanish_structure()
        
       
        
        self.study_session_order = study_session_order
        
        return study_session_order
        
    #TODO: there is no participant ID in tasklog table
    def step2(self):
        '''
        

        Returns
        -------
        flagged_ps_session : TYPE
            DESCRIPTION.

        '''
        
        dataset_dfs = self.dataset_dfs
        study_session_order = self.study_session_order
        study_to_check = self.study
        
        taslog_data = dataset_dfs['task_log']
        
        #we create a new column named Task
        #combined the tag with the task_name, it only affects the Affect task name. Changes it to preAffect of postAffect
        taslog_data["Task"] = taslog_data["tag"].fillna('') + taslog_data["task_name"]
        
        print(taslog_data.columns)
        
        #imake df with the important columns for the data integrity check
        selected_clms = ["study_id","participantID","date_completed","session_name","Task"]
        sub_tasklog_data = taslog_data[selected_clms]
        
        #remove task_name SESSION_COMPLETE that just indicates if you completed all tasks in the session and is not a specific task in the study
        sub_tasklog_data = sub_tasklog_data[sub_tasklog_data["Task"] != "SESSION_COMPLETE"]
        
        #take into account all sessions except Eligibility
        sub_tasklog_data = sub_tasklog_data[sub_tasklog_data["session_name"] != "Eligibility"]
        
        #store distinct participant IDs found in the task log
        participant_ids = sub_tasklog_data["participantID"].unique()
        
        #list to add participant ids and sessions that do not match study task sequence order
        flagged_ps_session = list()
        
        checking_tasklog_data = sub_tasklog_data
        # loop over each participant in study
        for p in participant_ids:
            # get participant task information and store in df
            df_p = checking_tasklog_data[checking_tasklog_data["participantID"] == p]
            
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
                flagged_ps_session.append([p,study_id, "SessionOrder", length_diff, differences[0], differences[1], None, study_sessions_array, p_sessions_array])
        
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
                    flagged_ps_session.append([p,study_id, session, length_diff, differences[0], differences[1], max_date, study_session_order[study_to_check][session][:], p_ordered_tasks])
                    
        
        self.flagged_ps_session = flagged_ps_session
        
        return flagged_ps_session
        
        
        
    def final_touch_step2(self, report_df):
        
        
        report_df = report_df
        study_to_check = self.study
        
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
        

        return report_df
        
     
    def task_log_and_taskname(self):
        
        dataset_dfs = self.dataset_dfs
        study_to_check = self.study
        
        #extract the study specific participants
        participant_data = dataset_dfs['participant']
        participant_data = participant_data.query("test_account == 0 and admin == 0")
        
        study_data = dataset_dfs['study']
        study_data = study_data[study_data.id.isin(participant_data.study_id.values)]
        study_data = study_data.query('study_extension == {}'.format(repr(study_to_check)))
        
        taskLog_data = dataset_dfs['task_log']
        taskLog_data = taskLog_data[taskLog_data.study_id.isin(study_data.id.values)]

        participant_session_task = []
        duplicated_tasks_taskLog = []
        duplicated_tasks = []
        
        for task_name in dataset_dfs.keys():
            
            print(task_name)
            tmp_tasklog_task = taskLog_data[taskLog_data.task_name == task_name]
            
            # add them to the flag participants 
            duplicated_rows = tmp_tasklog_task[tmp_tasklog_task.duplicated(['study_id', 'session_name'], keep=False)]
            if duplicated_rows.shape[0] > 0:
                duplicated_tasks_taskLog.append(duplicated_rows)
                
        flagg_study_id = duplicated_tasks_taskLog.study_id.unique()
        
        return duplicated_tasks_taskLog
    
def parse_args():
    '''
    Returns
    -------
    args : TYPE
        DESCRIPTION.

    '''
    parser = argparse.ArgumentParser()

    # server
    parser.add_argument('--host', type=str, default='127.0.0.1')
    parser.add_argument('--user', type=str, default='root')
    parser.add_argument('--password', type=str, default='soniabaee')
    parser.add_argument('--database', type=str, default='calm')
    parser.add_argument('--auth_plugin', type=str, default='mysql_native_password')

    # Dataset
    parser.add_argument('--study', type=str, choices=['TET','GIDI','KAISER','SPANISH'], default='TET')
    parser.add_argument('--task', type=str, choices=['step1', 'step2', 'step3'], default='step1')
    
    
    # directory
    parser.add_argument('--directory', type=str, default='../MindTrails/TET/MT-Data-TETOffensiveStudy')
    parser.add_argument('--input_dir', type=str, default='../MindTrails/TET/MT-Data-TETOffensiveStudy/data')
    parser.add_argument('--output_dir', type=str, default='../MindTrails/TET/MT-Data-TETOffensiveStudy/output')


    # selected data stream
    parser.add_argument('--data_stream_type', type=str, choices=['-cal', '-raw'], default='-cal', help= 'select calibrated or raw data, defalut is calibrated')
    parser.add_argument('--data_stream', type=list, choices=['ppg', 'accelometer', 'gsr', 'gyroscope', 'magnetometer', 'all'], default=[ 'gsr', 'ppg'], help= 'we can select one or all')


    # visualization
    parser.add_argument('--visualization', type=bool,  default=False, help= 'if you want to visualize your data')

    args = parser.parse_args()
    return args



if __name__ == '__main__':
    #-------------------------------------
    # Base on args given, compute new args
    args = parse_args()
    #-------------------------------------
    data_integrity = data_integrity(args)
    data_integrity.connect_database()
    data_integrity.get_data_tables()
    # study_session_order = data_integrity.study_structure()
    # flagged_ps_session = data_integrity.step2()
    # #store flagged information in df
    # report_df = pd.DataFrame(flagged_ps_session, 
    #                          columns=["ParticipantID","StudyID", "Session", "PTaskLength", "Diff_P_S",
    #                                   "Diff_S_P", "Last_Date","SessionOrder", "ParticipantOrder"])
    
    # print(report_df.describe())
    # #Todo; need to integrate this to step2 function and add it as a seperate function
    # cleaned_report = data_integrity.final_touch_step2(report_df)
    # #save report to CSV file
    # cleaned_report.to_csv('{}_{}_DataIntegrityS2_Report.csv'.format(args.study, time.strftime("%Y%m%d")), index=False)
    
    duplicated_tasks_taskLog = data_integrity.task_log_and_taskname()
    
    
    
    
    
    
    
