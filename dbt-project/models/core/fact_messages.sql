{{ config(materialized='table') }}

with
    messages as (
        select * from {{ ref('stg_messages') }}
    ),
    first_touch as (
        select * from {{ ref('stg_first_touch') }}
    )

select 
    m.message_id ID_MESSAGE
    , m.client_id ID_CLIENT
    , m.campaign_id ID_CAMPAIGN
    , m.message_type EN_MESSAGE_TYPE
    , m.channel EN_MESSAGE_CHANNEL
    , FL_IS_OPENED
    , FL_IS_CLICKED
    , FL_IS_PURCHASED
    , m.sent_at_parsed DT_SENT_AT
    , m.opened_first_time_at_parsed DT_OPEN_FIRST_TIME

    , c.first_purchase_date DT_FIRST_PURCHASE

FROM 
    messages m
LEFT JOIN first_touch c ON c.client_id = m.client_id