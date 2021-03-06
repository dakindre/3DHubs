# 3DHubs - Submission for Drew Dakin

## Technology Stack
```
AWS PostgreSQL 
SQL Workbench
```
## Overview
Database was created on AWS and then queried remotely using SQL Workbench. The script used to produce the final results can be found [here](3d_script.sql). The results csv can be found [here](supplier_score_metrics.csv). An overview of the process is listed below


### Acceptance Ratio Calculation
1. Create a table of only processing data
2. Create a table of only payment data
3. Lef joined processing with payment due to dependency and kept only processessing date (account for delayed acceptance)
4. Summed entries by supplier_id and calculated ratio

### Acceptance Ratio Explanation
For the acceptance ratio I wanted to create a calculation that measured what percentage of submitted orders were ultimately accepted. That's why I ignored the accepted date and used only the processing. Otherwise many suppliers had over 100% because previous day orders were not accepted until the days after. In batch processing you want to account for retroactive fullfilment so I figured this was the best solution.

### Average Rating Calculation
1. Get most recent entry for each order for each day
2. Merge reduced table with original to get back the scores
3. Removed any entry that was a deletion or update to NULL
4. Calculated daily averages by supplier by metric
5. Calcualted the joined average of the two metrics

### Average Rating Explanation
I decided to take the most recent timestamp entry for each order for each day. This eliminated the need to process several order reviews that happened within a given day for a single order. Let's say that a user on 01/02/2017 created a review for an order and then updated it and then deleted it. Only the last event needs to be captured and counted so that's why I took MAX value for the day. With this method deletions represent only removing the entry so I deleted the deletes. Additionally any update to NULL was considered equivalent to a delete. This leaves us with only creation and updates with real numbers. The metric is then calculated using that.

### Considerations
It could be assumed that for the average rating we want to better understand user behavior and update via cursor the moving rating. With my implementation it considerst the end of the day a hard stop. That may not produce the most accurate results. A delete on the next day should in my opinion erase any create event the day before, but one could argue that either way. It didn't explicitly say in the instructions so I chose the former for the purposes of simpicity. 
