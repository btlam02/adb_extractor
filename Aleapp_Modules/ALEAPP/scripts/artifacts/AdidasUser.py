# # Get Information related to users from the Adidas Running app stored in user.db
# # Author: Fabian Nunes {fabiannunes12@gmail.com}
# # Date: 2023-03-24
# # Version: 1.0
# # Requirements: Python 3.7 or higher
# import datetime

# from scripts.artifact_report import ArtifactHtmlReport
# from scripts.ilapfuncs import logfunc, tsv, timeline, open_sqlite_db_readonly


# def get_adidas_user(files_found, report_folder, seeker, wrap_text, time_offset):
#     logfunc("Processing data for Adidas User")
#     files_found = [x for x in files_found if not x.endswith('-journal')]
#     file_found = str(files_found[0])
#     db = open_sqlite_db_readonly(file_found)

#     # Get information from the table device_sync_audit
#     cursor = db.cursor()
#     cursor.execute('''
#         Select *
#         from userProperty
#     ''')

#     all_rows = cursor.fetchall()
#     usageentries = len(all_rows)
#     if usageentries > 0:
#         logfunc(f"Found {usageentries} entries in user.db")
#         report = ArtifactHtmlReport('User')
#         report.start_artifact_report(report_folder, 'Adidas User')
#         report.add_script()
#         data_headers = ('ID', 'Name', 'Height', 'Weight', 'Country', 'Gender', 'Email', 'Created At', 'Image', 'My Fitness Pal', 'Garmin Connect', 'Polar', 'LastSync')
#         data_list = []
#         for row in all_rows:
#             if row[2] == 'userId':
#                 user_id = row[1]
#             if row[2] == 'FirstName':
#                 name = row[1]
#             if row[2] == 'LastName':
#                 name = name + ' ' + row[1]
#             if row[2] == 'Height':
#                 height = row[1]
#             if row[2] == 'Weight':
#                 weight = row[1]
#             if row[2] == 'CountryCode':
#                 country = row[1]
#             if row[2] == 'Gender':
#                 gender = row[1]
#             if row[2] == 'EMail':
#                 email = row[1]
#             if row[2] == 'createdAt':
#                 created_at = row[1]
#                 #convert from timestamp to date
#                 created_at = int(created_at)
#                 created_at = datetime.datetime.utcfromtimestamp(created_at/1000).strftime('%Y-%m-%d %H:%M:%S')
#             if row[2] == 'AvatarUrl':
#                 image = row[1]
#             if row[2] == 'MY_FITNESS_PAL_CONNECTED':
#                 if row[1] == 'true':
#                     my_fitness_pal = 'Connected'
#                 else:
#                     my_fitness_pal = 'Not Connected'
#             if row[2] == 'isGarminConnected':
#                 if row[1] == 'true':
#                     garmin_connect = 'Connected'
#                 else:
#                     garmin_connect = 'Not Connected'
#             if row[2] == 'isPolarConnected':
#                 if row[1] == 'true':
#                     polar = 'Connected'
#                 else:
#                     polar = 'Not Connected'
#             if row[2] == 'lastV3SessionSyncAtLocalTime':
#                 last_sync = row[1]
#                 #convert from timestamp to date
#                 last_sync = int(last_sync)
#                 last_sync = datetime.datetime.utcfromtimestamp(last_sync/1000).strftime('%Y-%m-%d %H:%M:%S')
#         data_list.append((user_id, name, height, weight, country, gender, email, created_at, '<img src="'+image+'" alt="'+image+'" width="50" height="50">', my_fitness_pal, garmin_connect, polar, last_sync))

#         table_id = "AdidasUser"
#         report.write_artifact_data_table(data_headers, data_list, file_found, table_id=table_id, html_escape=False)
#         report.end_artifact_report()

#         tsvname = f'Adidas - User'
#         tsv(report_folder, data_headers, data_list, tsvname)

#         tlactivity = f'Adidas - User'
#         timeline(report_folder, tlactivity, data_list, data_headers)

#     else:
#         logfunc('No Adidas User data available')

#     db.close()


# __artifacts__ = {
#     "AdidasUser": (
#         "Adidas-Running",
#         ('*com.runtastic.android/databases/user.db*'),
#         get_adidas_user)
# }


# Get Information related to users from the Adidas Running app stored in user.db
# Author: Fabian Nunes {fabiannunes12@gmail.com}
# Date: 2023-03-24
# Version: 1.0
# Requirements: Python 3.7 or higher
import datetime

from scripts.artifact_report import ArtifactHtmlReport
from scripts.ilapfuncs import logfunc, tsv, timeline, open_sqlite_db_readonly


def get_adidas_user(files_found, report_folder, seeker, wrap_text, time_offset):
    logfunc("Processing data for Adidas User")
    files_found = [x for x in files_found if not x.endswith('-journal')]
    file_found = str(files_found[0])
    db = open_sqlite_db_readonly(file_found)

    cursor = db.cursor()
    cursor.execute('''
        SELECT * FROM userProperty
    ''')

    all_rows = cursor.fetchall()
    usageentries = len(all_rows)
    if usageentries > 0:
        logfunc(f"Found {usageentries} entries in user.db")
        report = ArtifactHtmlReport('User')
        report.start_artifact_report(report_folder, 'Adidas User')
        report.add_script()
        data_headers = (
            'ID', 'Name', 'Height', 'Weight', 'Country', 'Gender', 'Email', 'Created At',
            'Image', 'My Fitness Pal', 'Garmin Connect', 'Polar', 'LastSync'
        )
        data_list = []

        # Initialize variables with default values
        user_id = name = height = weight = country = gender = email = created_at = image = 'N/A'
        my_fitness_pal = garmin_connect = polar = last_sync = 'N/A'

        for row in all_rows:
            key = row[2]
            value = row[1]
            if key == 'userId':
                user_id = value
            elif key == 'FirstName':
                name = value
            elif key == 'LastName':
                name = name + ' ' + value if name != 'N/A' else value
            elif key == 'Height':
                height = value
            elif key == 'Weight':
                weight = value
            elif key == 'CountryCode':
                country = value
            elif key == 'Gender':
                gender = value
            elif key == 'EMail':
                email = value
            elif key == 'createdAt':
                try:
                    created_at = datetime.datetime.utcfromtimestamp(int(value)/1000).strftime('%Y-%m-%d %H:%M:%S')
                except:
                    created_at = value
            elif key == 'AvatarUrl':
                image = value
            elif key == 'MY_FITNESS_PAL_CONNECTED':
                my_fitness_pal = 'Connected' if value == 'true' else 'Not Connected'
            elif key == 'isGarminConnected':
                garmin_connect = 'Connected' if value == 'true' else 'Not Connected'
            elif key == 'isPolarConnected':
                polar = 'Connected' if value == 'true' else 'Not Connected'
            elif key == 'lastV3SessionSyncAtLocalTime':
                try:
                    last_sync = datetime.datetime.utcfromtimestamp(int(value)/1000).strftime('%Y-%m-%d %H:%M:%S')
                except:
                    last_sync = value

        data_list.append((
            user_id, name, height, weight, country, gender, email, created_at,
            f'<img src="{image}" alt="{image}" width="50" height="50">',
            my_fitness_pal, garmin_connect, polar, last_sync
        ))

        table_id = "AdidasUser"
        report.write_artifact_data_table(data_headers, data_list, file_found, table_id=table_id, html_escape=False)
        report.end_artifact_report()

        tsvname = f'Adidas - User'
        tsv(report_folder, data_headers, data_list, tsvname)

        tlactivity = f'Adidas - User'
        timeline(report_folder, tlactivity, data_list, data_headers)

    else:
        logfunc('No Adidas User data available')

    db.close()


__artifacts__ = {
    "AdidasUser": (
        "Adidas-Running",
        ('*com.runtastic.android/databases/user.db*'),
        get_adidas_user)
}
