{{ config(materialized='table') }}

with
    messages as (
        select * from {{ ref('stg_messages') }}
    ),
    campaigns as (
        select * from {{ ref('stg_campaigns') }}
    )

select 
        message_id ID_MESSAGE
    , client_id ID_CLIENT
    , campaign_id ID_CAMPAIGN
    , message_type EN_MESSAGE_TYPE
    , messages.channel EN_MESSAGE_CHANNEL
    , FL_IS_OPENED
    , FL_IS_CLICKED
    , FL_IS_PURCHASED
    , sent_at_parsed DT_SENT_AT
    , opened_first_time_at_parsed DT_OPEN_FIRST_TIME

    , c.channel EN_CAMPAIGN_CHANNEL
    , c.campaign_type EN_CAMPAIGN_TYPE
    , c.total_count VAL_CAMPAIGN_TOTAL_COUNT

FROM 
    messages
LEFT JOIN campaigns c ON c.id = messages.campaign_id