{{ config(materialized='table') }}

select 
    id ID
    , channel EN_CAMPAIGN_CHANNEL
    , campaign_type EN_CAMPAIGN_TYPE
    , total_count VAL_CAMPAIGN_TOTAL_COUNT

from {{ ref('stg_campaigns') }}