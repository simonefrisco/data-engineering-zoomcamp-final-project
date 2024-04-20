{{ config(materialized='view') }}
 
with messages as 
(
  select *
  from {{ source('staging','raw_messages') }}
)
select
    message_id
    , client_id
    , campaign_id
    , message_type
    , channel
    , CASE WHEN is_opened = 't' THEN TRUE ELSE FALSE END as FL_IS_OPENED
    , CASE WHEN is_clicked = 't' THEN TRUE ELSE FALSE END as FL_IS_CLICKED
    , CASE WHEN is_purchased  = 't' THEN TRUE ELSE FALSE END as FL_IS_PURCHASED
    , sent_at
    , date_add('ms',sent_at/1000,'1970-01-01') sent_at_parsed
    , date_add('ms',opened_first_time_at/1000,'1970-01-01') opened_first_time_at_parsed

from messages

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}