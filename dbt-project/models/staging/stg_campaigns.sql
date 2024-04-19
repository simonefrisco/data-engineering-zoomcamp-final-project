{{ config(materialized='view') }}
 
with campaigns as 
(
  select *
  from {{ source('staging','l0_campaigns') }}
)
select
    id
    , campaign_type
    , channel
    , topic
    , started_at
    , finished_at
    , total_count
    , is_test

from campaigns
WHERE is_test != 'False' OR is_test IS NULL

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}