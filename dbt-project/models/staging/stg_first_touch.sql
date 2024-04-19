{{ config(materialized='view') }}
 
with first_touch as 
(
  select *
  from {{ source('staging','l0_first_touch') }}
)
select
     client_id
    , first_purchase_date

from first_touch

-- dbt build --select <model.sql> --vars '{'is_test_run: false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}