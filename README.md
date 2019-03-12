# 3DHubs

## Technology Stack
```
AWS PostgreSQL 
SQL Workbench
```
## Overview
Database was created on AWS and then queried remotely using SQL Workbench. The script used to produce the final results can be found [here](3d_script.sql). An overview of the process is listed below

### Master Table
1. Create reduced Master table with only necessary metrics

### Acceptance Ratio Calculation
1. Create a table of only processing data
2. Create a table of only payment data
3. Merged tables and kept only processessing data date
4. Summed entries by supplier_id and calculated ratio

### Average Rating Calculation
1. Get most recent entry for each order for each day
2. Merge reduced table with original to get back the scores
3. Removed any entry that was a deletion or update to NULL
4. Calculated daily averages by supplier by metric
5. Calcualted the joined average of the two metrics

### Joined Metric Table
1. Union two tables that result in the [data set](supplier_score_metrics.csv)


## Explanation of Methods

### Acceptance Ratio
For the acceptance ratio I wanted to create a calculation that measured what percentage of submitted orders were ever accepted. That's why I ignored the accepted date and used only the processing. Otherwise many suppliers had over 100% because previous day orders were not accepted till later. In batch processing you want to account for retroactive fullfilment. 

### Average Rating
I decided to take the most recent timestamp entry for each order for each day. This eliminated the need to process several order reviews that happened in a  
