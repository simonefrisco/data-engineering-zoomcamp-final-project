

# !pip install fsspec s3fs
#%% []
import deltalake
deltalake.__version__
#%% []


import polars as pl
import s3fs
campaigns = pl.read_csv("data/archive/campaigns.csv",try_parse_dates=True)

fs = s3fs.S3FileSystem()
uri_campaigns = "s3://kestra-datatalkclub-project/datalake/raw/campaigns/campaignsv3.parquet"

with fs.open(uri_campaigns, mode='wb') as f:
    campaigns.write_parquet(f)


#%% []

import polars as pl
from deltalake.schema import _convert_pa_schema_to_delta
from deltalake import write_deltalake

campaigns = pl.read_csv("data/archive/campaigns.csv",try_parse_dates=True)

delta_schema = _convert_pa_schema_to_delta(campaigns.to_arrow().schema,large_dtypes=True)

#%% []

uri_campaigns = "s3://kestra-datatalkclub-project/deltalake/campaignsv20"

(
    campaigns
        .write_delta(
            uri_campaigns,
            mode='append',
            storage_options=storage_options,
    )
)

# write_deltalake(
#     uri_campaigns, 
#     campaigns.to_arrow(),
#     mode="append",
#     large_dtypes = True , 
#     # schema_mode ="merge",
#     storage_options = storage_options ,
#     schema =  delta_schema
#     )

#%% []

data = pl.read_delta(uri_campaigns, storage_options=storage_options)
data
#%% []


# create a column with 13 different ids
partitions = campaigns.with_row_count("id_p").select(pl.col("id_p") // 100)
# group based on the created id, resulting 13 partitons
data_partitioned = campaigns.with_columns(partitions).partition_by("id_p")

# %%
client_first_purchase_date = pl.read_csv("data/archive/client_first_purchase_date.csv",try_parse_dates=True)
(
    client_first_purchase_date.shape
)
# %%
(
    client_first_purchase_date.head(10)
)
# %%
# %%
messages = pl.scan_csv("data/archive/messages-demo.csv",try_parse_dates=True)
(
    messages
    .with_columns([
        pl.col("date").dt.strftime('%Y-%m-%d').alias("date_day")
    ])
).collect()
# %%
(
    messages.head(10).collect()
)
# %%

(
    pl
    .scan_csv("data/archive/campaigns.csv",try_parse_dates=True)
    .write_delta(
            uri_campaigns,
            delta_write_options={"schema_mode": "overwrite" , 'partition_by' : 'date'  },
            storage_options=storage_options,
    )


)

pl.scan_csv("data/archive/messages-demo.csv",try_parse_dates=True)


#%% []
import polars as pl

uri_messages = "s3://kestra-datatalkclub/deltalake/messages"

#* Table Messages

(
    pl
    .scan_csv("data/archive/messages-demo.csv",try_parse_dates=True)
    .with_columns([
        pl.col("date").dt.strftime('%Y-%m-%d').alias("date_day")
    ])
    .sink_parquet("data/archive/messages-demo.parquet")
)
messages = (
        pl.read_parquet("data/archive/messages-demo.parquet")
    )
partitions = messages.with_row_count("id_p").select(pl.col("id_p") // 250_000)
data_partitioned = messages.with_columns(partitions).partition_by("id_p")
#%% []
for df in data_partitioned:
    print(df.shape)
    df.write_delta(
            uri_messages,
            mode = 'append',
            delta_write_options={'partition_by' : 'date_day'  },
            storage_options=storage_options,
    )
# %%
