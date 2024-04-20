import polars as pl
import pyarrow.parquet as pq

storage_options = {
    "AWS_ACCESS_KEY_ID": "{{ secret('AWS_ACCESS_KEY') }}", 
    "AWS_SECRET_ACCESS_KEY": "{{ secret('AWS_SECRET_KEY') }}", 
    "AWS_REGION" : "eu-central-1",
    'AWS_S3_ALLOW_UNSAFE_RENAME': 'true'}


print('1. Dump CSV Campaigns Table')
(
    pl
    .scan_csv('{{workingDir}}/campaigns.csv', try_parse_dates=True)
    .sink_parquet("{{workingDir}}/campaigns.parquet")
)

print('2. Dump CSV Client First Date')
(
    pl
    .scan_csv('{{workingDir}}/client_first_purchase_date.csv', try_parse_dates=True)
    .sink_parquet("{{workingDir}}/client_first_purchase_date.parquet")
)

print('3. Dump CSV Holidays')
(
    pl
    .scan_csv('{{workingDir}}/holidays.csv', try_parse_dates=True)
    .sink_parquet("{{workingDir}}/holidays.parquet")

)

print('4.  Dump CSV Messages')
(
    pl
    .scan_csv("{{workingDir}}/messages-demo.csv",try_parse_dates=True)
    .with_columns([
        pl.col("date").dt.strftime('%Y-%m-%d').alias("date_day")
    ])
    .sink_parquet("{{workingDir}}/messages.parquet")
)