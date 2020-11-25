import mysql.connector
import pandas as pd

host = "yourHostname"
user = "yourUser"
password= "yourPassword"
database = "yourDatabase"

mydb = mysql.connector.connect(
  host=host,
  user=user,
  password= password,
  database=database
)

mycursor = mydb.cursor()

#Is AssesingProgram duplicated, Affect different from other included first and third session parameter
task_list = [['credibility','credibility'],['demographics','demographics'],['MentalHealthHistory','mental_health_history'],
             ['AnxietyIdentity','anxiety_identity'],['OA','OA'],['AnxietyTriggers','anxiety_triggers'],['rr','rr'],['bbsiq','bbsiq'],
             ['Comorbid','Comorbid'],['Wellness','wellness'],['Mechanisms','mechanisms'],['Covid19','covid19'],['TechnologyUse','technology_use'],
             ['Affect','affect'],['SessionReview','session_review'],['CoachPrompt','coach_prompt'],['ReturnIntention','return_intention'],
             ['HelpSeeking','help_seeking'],['Evaluation','evaluation'],['AssessingProgram','assessing_program']]


for i in task_list:
  if i[0] != 'Affect':

    print(i[0])

    query = "select count(distinct(study_id)) as freq,  count(distinct session_name) from task_log where task_name = '{}' " \
          "and study_id in (select id from calm.study where study_extension = 'TET' and id in (select study_id from participant where test_account = 0 and admin = 0))".format(i[0])

    query2 ="SELECT study_id, session_name, COUNT(*) FROM task_log where task_name = '{}' " \
          "and study_id in (select id from calm.study where study_extension = 'TET' and id in (select study_id from participant where test_account = 0 and admin = 0)) " \
            "GROUP BY study_id, session_name HAVING COUNT(*) > 1;".format(i[0])

    query3 = " select count(distinct participant_id) as freq, count(distinct session) from {} " \
           "where participant_id in (select id from participant where study_id in (select id from study where study_extension = 'TET') and test_account = 0 and admin = 0);".format(i[1])

    query4 =" SELECT participant_id, session, COUNT(*) FROM {} " \
          "where participant_id in (select id from participant where study_id in (select id from study where study_extension = 'TET') and test_account = 0 and admin = 0) " \
            "GROUP BY participant_id, session HAVING COUNT(*) > 1;".format(i[1])

    df_test = pd.read_sql_query(query,mydb)
    df_test2 = pd.read_sql_query(query2,mydb)
    df_test3 = pd.read_sql_query(query3, mydb)
    df_test4 = pd.read_sql_query(query4, mydb)
    print("Query 1")
    print(df_test)
    print("Query 2")
    print(df_test2)
    print("Query 3")
    print(df_test3)
    print("Query 4")
    print(df_test4)
  else:
    pass



