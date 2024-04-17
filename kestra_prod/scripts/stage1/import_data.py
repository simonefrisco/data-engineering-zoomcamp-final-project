import polars as pl
import pyarrow.parquet as pq

storage_options = {
    "AWS_ACCESS_KEY_ID": "{{ secret('AWS_ACCESS_KEY') }}", 
    "AWS_SECRET_ACCESS_KEY": "{{ secret('AWS_SECRET_KEY') }}", 
    "AWS_REGION" : "eu-central-1",
    'AWS_S3_ALLOW_UNSAFE_RENAME': 'true'}
# print(storage_options)

uri_messages = "{{ vars.aws_s3_bucket }}/deltalake/l0_messages"
uri_campaigns = "{{ vars.aws_s3_bucket }}/deltalake/l0_campaigns"
uri_client_first_purchase_date = "{{ vars.aws_s3_bucket }}/deltalake/l0_client_first_purchase_date"
uri_holidays = "{{ vars.aws_s3_bucket }}/deltalake/l0_holidays"

print('1. Upload Campaigns Table')
(
    pl
    .read_csv('{{workingDir}}/campaigns.csv', try_parse_dates=True)
    .write_delta(
            uri_campaigns,
            mode='append',
            storage_options=storage_options,
    )
)

print('2. Upload Client First Date')
(
    pl
    .read_csv('{{workingDir}}/client_first_purchase_date.csv', try_parse_dates=True)
    .write_delta(
            uri_client_first_purchase_date,
            mode='append',
            storage_options=storage_options,
    )
)

print('3. Upload Holidays')
(
    pl
    .read_csv('{{workingDir}}/holidays.csv', try_parse_dates=True)
    .write_delta(
            uri_holidays,
            mode='append',
            storage_options=storage_options,
    )
)

print('4.  Upload Messages')
print('4.1 Convert csv in parquet')

(
    pl
    .scan_csv("{{workingDir}}/messages-demo.csv",try_parse_dates=True)
    .with_columns([
        pl.col("date").dt.strftime('%Y-%m-%d').alias("date_day")
    ])
    .sink_parquet("{{workingDir}}/messages-demo.parquet")
)

import time
time.sleep(2)

print('4.2 Upload parquet in chunks')
parquet_file = pq.ParquetFile("{{workingDir}}/messages-demo.parquet")

for i, chunk in enumerate(parquet_file.iter_batches(200_000)):
    print(f'loading {i} chuck-th .. ')
    pl.from_arrow(chunk).write_delta(
            uri_messages,
            mode = 'append',
            delta_write_options={'partition_by' : 'date_day' },
            storage_options=storage_options,
    )