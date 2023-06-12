Testtest
# MT-Data-TETOffensiveStudy

This repository is the knowledge base for the MindTrails TET Offensive Study (TET) dataset. For more information about the TET Offensive Study, see the [TET Offensive page](https://sites.google.com/a/virginia.edu/mindtrails-wiki/studies/calm-thinking-variations-r01) of the [MindTrails Wiki](https://sites.google.com/a/virginia.edu/mindtrails-wiki/home).

For questions, please contact Jeremy W. Eberle(https://github.com/jwe4ec) or file an issue(https://github.com/TeachmanLab/MT-Data-CalmThinkingStudy/issues). 

## Table of Contents
- [Citation](#Citation]
- [Data on Open Science Framework](#data-on-open-science-framework)
	- [Private Component](#private-component)
  	- [Public Component](#public-component)
## Citation

## Data on Open Science Framework

Raw and centrally cleaned data from the "calm" SQL database are stored in the [MindTrails TET Offensive Study](https://osf.io/xfn3k/) project on the Open Science Framework (OSF). The project has two components, with different permissions: a [Private Component](https://osf.io/sv3tn/) and a [Public Component](https://osf.io/dr2z4/).

### Private Component

The [Private Component](https://osf.io/xfn3k/) contains the full set of 67 raw data tables (with some exceptions). 66 of them are dumped from the "calm" SQL database on the "teachmanlab" Data Server via Grafana(http://128.143.231.15:3000), a multi-platform open source analytics and interactive visualization web application, on March 23, 2023. The angular training table is dumped from the "calm" SQL database on the "teachmanlab" Data Server directly from April 6, 2023. 

The exceptions are that only redacted versions of "gift_log", "import_log", and "sms_log" tables are included (redacted using [3_redact_data.R](#3_redact_dataR)). 


```
.
├── data
└── └── 1_raw_full               # 67 CSV files (e.g., "action_log-23_03_2023.csv", "evaluation_how_learn-23_03_2023.csv", 
                                 #   "import_log-23_03_2023.csv")
```

Researchers can request access to files on this component by contacting the study team ([studyteam@mindtrails.org](mailto:studyteam@mindtrails.org)).

### Public Component

The [Public Component](https://osf.io/dr2z4/) contains a partial set of raw data tables (i.e., those obtained using via Grafana that did not need redaction), redacted tables (from [3_redact_data.R](#3_redact_dataR)), and intermediately clean tables (from [4_clean_data.R](#4_clean_dataR)). The structure of a [version](#versioning)'s ZIP file is below.

Note: Tables in the `1_raw_full` folder of the [Private Component](#private-component) that are not in the `1_raw_partial` folder of this [Public Component](https://osf.io/s8v3h/) contain free-text responses that may or may not have identifiers. In the [Public Component](https://osf.io/s8v3h/), redacted versions of such tables are in `2_redacted`.



## Contact

If you are a researcher who wants to contribute to this project, please contact Bethany Teachman at bteachman@virginia.edu. Thanks!
