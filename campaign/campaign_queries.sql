campaign analysis

-- Q1 What is the total count of campaigns conducted within a designated timeframe?

select count(distinct campaign_id) as total_campaigns
from campaign_identifier
where start_date >= date(start_date) and end_date <= date(end_date)



-- Q2 What are the commencement and cessation dates for each campaign?

select campaign_name as campaign_name, min(date(start_date)) as start_date, max(date(end_date)) as end_date
from campaign_identifier
group by 1




-- Q3 How many cumulative visits and distinct visits were generated for each campaign?

select ci.campaign_name as campaign_name,
count(e.visit_id) as total_visits,
count(distinct e.visit_id) as total_unique_visits
from campaign_identifier ci
join page_hierarchy ph on ci.product_id = ph.product_id
join events e on e.page_id = ph.page_id
group by 1




-- Q4 What is the mean duration of each promotional campaign?

select campaign_name as campaign_name,
avg(datediff(end_date, start_date)) as average_duration_days
from campaign_identifier
group by 1




-- Q5 How many cumulative users, distinct users, and the average unique users were engaged with each promotional campaign?

select ci.campaign_name as campaign_name,count(user_id) as total_user,
count(distinct user_id) as unique_users,
avg(distinct user_id) as average_no_of_users
from campaign_identifier ci 
join page_hierarchy ph on ci.product_id = ph.product_id
join events e on e.page_id = ph.page_id
join users u on u.cookie_id = e.cookie_id
group by 1



-- Q6 How does the distribution of event types differ across various promotional campaigns?

select ci.campaign_name as campaign_name,
e.event_type as event_type,
count(*) AS event_count
from events e
join page_hierarchy ph on ph.page_id = e.page_id
join campaign_identifier ci on ci.product_id = ph.product_id
group by 1,2



-- Q7 How many products were affiliated with each of the specified promotional campaigns?

select campaign_name,count(product_id) as product_count
from campaign_identifier
where campaign_id = 1
group by 1
union 
select campaign_name,count(product_id) as product_count
from campaign_identifier
where campaign_id = 3
group by 1
union
select campaign_name,count(product_id) as product_count
from campaign_identifier
where campaign_id = 2
group by 1




-- Q8 What are the quantities of views, cart additions, items added to cart but not purchased, and purchases in each campaign?

with product_page_events as (select e.visit_id,ph.product_id,ci.campaign_name,
sum(case when event_type = 1 then 1 else 0 end) as page_view,
sum(case when event_type = 2 then 1 else 0 end) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
join campaign_identifier ci on ci.product_id = ph.product_id
where ph.product_id is not null
group by 1,2,3
),
visit_purchase as (select distinct visit_id
from events
where event_type = 3
),
combined_product_events as (select t1.visit_id,t1.product_id,t1.campaign_name,t1.page_view,t1.cart_add,
case when t2.visit_id is not null then 1 else 0 end as purchase
from product_page_events as t1
left join visit_purchase  as t2 on t1.visit_id = t2.visit_id)
select campaign_name,sum(page_view) as page_views,sum(cart_add) as cart_adds,
sum(case when cart_add = 1 and purchase = 1 then 1 else 0 end) as purchased,
sum(case when cart_add = 1 and purchase = 0 then 1 else 0 end) as abandoned
from combined_product_events
group by 1
order by 1




-- Q9 What are the conversion rates for the following actions: adding to cart to purchase, page view to purchasing, page view to cart addition, and cart addition 
--    to abandonment, analyzed individually for each campaign?

with product_page_events as (select e.visit_id,ph.product_id,ci.campaign_name,
sum(case when event_type = 1 then 1 else 0 end) as page_view,
sum(case when event_type = 2 then 1 else 0 end) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
join campaign_identifier ci on ci.product_id = ph.product_id
where ph.product_id is not null
group by 1, 2, 3),
visit_purchase as (select distinct visit_id from events where event_type = 3),
combined_product_events as (select t1.visit_id,t1.product_id,t1.campaign_name,t1.page_view,t1.cart_add,
case when t2.visit_id is not null then 1 else 0 end as purchase
from product_page_events as t1
left join visit_purchase as t2 on t1.visit_id = t2.visit_id)
select campaign_name,
round(sum(case when cart_add = 1 and purchase = 1 then 1 else 0 end) * 100.0 / sum(page_view),2) as page_view_to_purchase_rate,
round((sum(case when cart_add > 0 and purchase = 1 then 1 else 0 end) * 100.0 / sum(cart_add)),2) as add_to_cart_to_purchase_rate,
round((sum(case when page_view > 0 and cart_add > 0 then 1 else 0 end) * 100.0 / sum(page_view)),2) as page_view_to_add_to_cart_rate,
round(sum(CASE WHEN cart_add > 0 AND purchase = 0 THEN 1 ELSE 0 END) * 100.0 / SUM(cart_add), 2) AS cart_add_to_abandoned_rate
from combined_product_events
group by 1
order by 1




-- Q10 What is the total count of cookie IDs and unique cookie IDs for each campaign?

select ci.campaign_name as campaign_name,
count(e.cookie_id) as total_cookies,
count(distinct e.cookie_id) as unique_cookies
from campaign_identifier ci 
join page_hierarchy ph on ci.product_id = ph.product_id
join events e on e.page_id = ph.page_id
group by 1





-- Q11 What is the average sequential order observed in each campaign?

select ci.campaign_name as campaign_name,
avg(e.sequence_number) as avg_sequence_number
from campaign_identifier ci
join page_hierarchy ph on ph.product_id = ci.product_id
join events e on e.page_id = ph.page_id
group by 1





-- Q12 What is the product abandonment rate for each campaign?

with product_page_events as (select e.visit_id,ph.product_id,ci.campaign_name,
sum(case when event_type = 1 then 1 else 0 end) as page_view,
sum(case when event_type = 2 then 1 else 0 end) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
join campaign_identifier ci on ci.product_id = ph.product_id
where ph.product_id is not null
group by 1, 2, 3
),
visit_purchase as (select distinct visit_id
from events
where event_type = 3
),
combined_product_events as (select t1.visit_id,t1.product_id,t1.campaign_name,t1.page_view,t1.cart_add,
case when t2.visit_id is not null then 1 else 0 end as purchase
from product_page_events as t1
left join visit_purchase as t2 on t1.visit_id = t2.visit_id
)
select campaign_name,
round(sum(case when cart_add = 1 and purchase = 0 then 1 else 0 end) * 1.0*100 / sum(cart_add), 2)as abandoned_rate
from combined_product_events
group by 1

-- Q13 Investigate the monthly user interaction metrics, comprising unique user counts and total visit volumes, across diverse campaigns featured in the dataset.

select ci.campaign_name,
       date_format( e.event_time,"%Y-%m") as month,
       count(distinct u.user_id) as users,
       count(*) as total_visits
from campaign_identifier ci
join page_hierarchy ph on ci.product_id = ph.product_id
join events e on e.page_id = ph.page_id
join users u on e.cookie_id=u.cookie_id
group by 1,2  order by 1,2


-- Q14 Conduct a comparative analysis of purchase rates among visits accompanied by ad clicks, visits featuring impressions but devoid of clicks, and visits
--     devoid of impressions.

with summary as (select e.visit_id,
        sum(case when e.event_type = 1 then 1 else 0 end) as page_views,
        sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds,
        max(case when e.event_type = 3 then 1 else 0 end) as purchase,
        sum(case when e.event_type = 4 then 1 else 0 end) as ad_impression,
        sum(case when e.event_type = 5 then 1 else 0 end) as ad_click
    from events e group by 1),
uplift_in_purchase_rate as ( 
	    select'with_ad_click' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
        from summary where ad_click > 0
union
       select 'with_ad_impression_without_ad_click' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
       from summary  where ad_impression > 0 and ad_click = 0
union
        select 'with_ad_impression' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
        from summary where ad_impression > 0
union
        select 'without_ad_impression' as visit_identifier,
        round(100 * avg(purchase), 2) as uplift_purchase_rate
        from summary where ad_impression = 0)
select * from uplift_in_purchase_rate


-- Q15 Perform a comprehensive analysis of campaign performance, focusing on metrics such as page views, cart additions, purchases, and abandoned actions.

with purchases as(select ci.campaign_name, sum(case when e.event_type = 2 then 1 else 0 end)as purchased
    from page_hierarchy as ph
    join campaign_identifier ci on ph.product_id = ci.product_id
    join events e on e.page_id = ph.page_id
    where exists(select visit_id from events where event_type = 3 and e.visit_id = visit_id group by 1)
	group by 1),
rate as(select ci.campaign_name, sum(case when e.event_type = 1 then 1 else 0 end)as page_views,				
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from events e 							
    join page_hierarchy p on e.page_id=p.page_id
	join campaign_identifier ci on p.product_id = ci.product_id							
	group by 1),
abandoned as (select ci.campaign_id, ci.campaign_name, count(*) as abandoned
    from page_hierarchy ph join campaign_identifier ci on ph.product_id = ci.product_id
    join events e on e.page_id = ph.page_id
    where  e.event_type = 2
    and not exists (select visit_id from events where event_type = 3 and e.visit_id = visit_id)
    group by 1,2 )
select a.campaign_id, p.campaign_name, r.page_views, r.cart_adds, p.purchased, a.abandoned
from rate r  join purchases p on r.campaign_name = p.campaign_name
join abandoned a on a.campaign_name = p.campaign_name
group by 1,2,3,4 order by 1	

-- Q16 What are the average user engagement durations for each marketing campaigns

select campaign_name,
    avg(timestampdiff(hour, a.event_time, a.next_event_time))as avg_time_spent_hour
from (select ci.campaign_name, e.event_time,
	lead(e.event_time) over (partition by u.user_id order by e.event_time)as next_event_time
    from events e
    join users u on e.cookie_id = u.cookie_id
    join page_hierarchy p on e.page_id = p.page_id
	join campaign_identifier ci on p.product_id=ci.product_id
) as a 
group by 1

-- Q17 What are the overall conversion rates per campaign, calculated as the percentage of visits that resulted in a purchase event, based on the given dataset?

select campaign_name,
    round(sum(purchased) / count(visit_id) * 100, 2)as overall_conversion_rate_of_purchase
from (select ci.campaign_name, e.visit_id,
        sum(case when e.event_type = 2 then 1 else 0 end) as purchased
      from page_hierarchy as ph
      join campaign_identifier ci on ph.product_id = ci.product_id
      join events e on e.page_id = ph.page_id
      where e.visit_id in (select visit_id from events where event_type = 3)
	  group by 1,2
)as a 
group by 1 order by 1

-- Q18 What are the average page views, cart additions, and purchases per user interaction(visit) for each campaign?

with purchases as (select ci.campaign_name, sum(case when e.event_type = 2 then 1 else 0 end) as purchased
	  from page_hierarchy as ph
	  join campaign_identifier ci on ph.product_id = ci.product_id
	  join events e on e.page_id = ph.page_id
     where exists (select visit_id from events where event_type = 3 and e.visit_id = visit_id group by 1)
      group by 1),
rate as (select ci.campaign_name, ci.campaign_id, count(distinct e.visit_id) as total_visits,
	sum(case when e.event_type = 1 then 1 else 0 end) as page_views,
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from events e 							
	join page_hierarchy p on e.page_id = p.page_id
	join campaign_identifier ci on p.product_id = ci.product_id							
    group by 1,2)
select r.campaign_id ,r.campaign_name,  r.page_views / r.total_visits as avg_page_views_per_visit,
    r.cart_adds / r.total_visits as avg_cart_ads_per_visit,
    p.purchased / r.total_visits as avg_purchases_per_visit
from rate r left join purchases p on r.campaign_name = p.campaign_name order by 1
