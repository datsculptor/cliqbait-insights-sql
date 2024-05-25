-- Q1 Which product obtained the highest and lowest number of views?

select * from
       (select ph.page_name as product_name, ph.product_category,
       count(*)as total_views,rank() over(order by count(*))as Most_and_Least_Recomended
       from events e			
       left join page_hierarchy ph on ph.page_id = e.page_id			
       where ph.product_category is not null			
       group by 1,2 order by 3 desc
       )as s 
where s.Most_and_Least_Recomended=1  or s.Most_and_Least_Recomended=9 


-- Q2 How many products are present within each category?

select product_category, count(*) as total_products,
group_concat(page_name separator ', ') as product_names				
from page_hierarchy						
where product_id is not null						
group by 1					
order by 2 desc		

--  Which product category boasts the highest product count?

select product_category,count(distinct product_id)as toatl_product
from page_hierarchy
where product_id is not null
group by 1
order by 2 desc
limit 1


-- Q3 What are the purchase conversion metrics for add-to-cart, page-view, page-view-to-cart, and cart abandonment, including their mean values, stratified by product?

with product_page_events as (select e.visit_id,ph.product_id,ph.page_name,
sum(case when event_type = 1 then 1 else 0 end) as page_view,
sum(case when event_type = 2 then 1 else 0 end) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
join campaign_identifier ci on ci.product_id = ph.product_id
where ph.product_id is not null
group by 1, 2, 3),
visit_purchase as (select distinct visit_id from events where event_type = 3),
combined_product_events as (select t1.visit_id,t1.product_id,t1.page_name,t1.page_view,t1.cart_add,
case when t2.visit_id is not null then 1 else 0 end as purchase
from product_page_events as t1
left join visit_purchase as t2 on t1.visit_id = t2.visit_id)
select page_name as product,
round(sum(case when cart_add = 1 and purchase = 1 then 1 else 0 end) * 100.0 / sum(page_view),2) as page_view_to_purchase_rate,
round((sum(case when cart_add > 0 and purchase = 1 then 1 else 0 end) * 100.0 / sum(cart_add)),2) as add_to_cart_to_purchase_rate,
round((sum(case when page_view > 0 and cart_add > 0 then 1 else 0 end) * 100.0 / sum(page_view)),2) as page_view_to_add_to_cart_rate,
round(sum(CASE WHEN cart_add > 0 AND purchase = 0 THEN 1 ELSE 0 END) * 100.0 / SUM(cart_add), 2) AS cart_add_to_abandoned_rate
from combined_product_events
group by 1
order by 1


-- Q4 Which product categories exhibit a propensity for concurrent viewing or purchasing behavior during a promotional campaign?

with VisitProducts as(select e.visit_id,
ph.product_category
from events e
join page_hierarchy ph on e.page_id = ph.page_id
where e.event_type = 1
),
VisitPairs as (select vp1.visit_id as visit_id1,
vp1.product_category as product_category1,
vp2.visit_id as visit_id2,
vp2.product_category as product_category2
from VisitProducts vp1
join VisitProducts vp2 on vp1.visit_id = vp2.visit_id
where vp1.product_category <> vp2.product_category
)
select product_category1,
product_category2,
count(*) as co_occurrences
from VisitPairs
group by 1,2
order by 3 desc


-- Q5 What is the tally of events for each product category?

select ph.product_category as product_category,
count(*) as event_count
from events e
join page_hierarchy ph on e.page_id= ph.page_id
group by 1
limit 3
offset 1


-- Q6 What is the count of instances where each product was added to a cart but not purchased, alongside the count of purchases for each product?

with cart_event as (select ph.product_id,
e.visit_id,
count(*) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
where ph.product_id is not null and e.event_type = 2
group by ph.product_id, e.visit_id),
visit_purchase as ( select distinct visit_id
from events
where event_type = 3),
combined_product_events as (select ce.product_id,
ce.cart_add,
case when vp.visit_id is null then 1 else 0 end as purchase
from cart_event ce
left join visit_purchase vp on ce.visit_id = vp.visit_id)
select product_id,
sum(case when cart_add = 1 and purchase = 0 then 1 else 0 end) as added_and_not_purchased,
sum(case when cart_add = 1 and purchase = 1 then 1 else 0 end) as purchases
from combined_product_events
group by product_id




-- Q7 What are the respective counts of page views, cart additions, cart additions not resulting in purchases, and purchases for each product category?

with product_page_events as (select e.visit_id,ph.product_id,ph.product_category,
sum(case when event_type = 1 then 1 else 0 end) as page_view
,sum(case when event_type = 2 then 1 else 0 end) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
where ph.product_id is not null
group by 1,2,3),
visit_purchase as (select distinct visit_id
from events
where event_type = 3),
combined_product_events as (select t1.visit_id,t1.product_id,t1.product_category,t1.page_view,t1.cart_add,
case when t2.visit_id is not null then 1 else 0 end as purchase
from product_page_events as t1
left join visit_purchase  as t2 on t1.visit_id = t2.visit_id)
select product_category,sum(page_view) as page_views,sum(cart_add) as cart_adds,
sum(case when cart_add = 1 and purchase = 1 then 1 else 0 end) as purchased,
sum(case when cart_add = 1 and purchase = 0 then 1 else 0 end) as abandoned
from combined_product_events
group by 1
order by 1




-- Q8 What are the rates of conversion from cart addition to purchase, page view to purchase, page view to cart addition, and cart addition to abandonment 
--    for each product category?

with product_page_events as (select e.visit_id,ph.product_id,ph.product_category,
sum(case when event_type = 1 then 1 else 0 end) as page_view,
sum(case when event_type = 2 then 1 else 0 end) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
join campaign_identifier ci on ci.product_id = ph.product_id
where ph.product_id is not null
group by 1, 2, 3),
visit_purchase as (select distinct visit_id from events where event_type = 3),
combined_product_events as (select t1.visit_id,t1.product_id,t1.product_category,t1.page_view,t1.cart_add,
case when t2.visit_id is not null then 1 else 0 end as purchase
from product_page_events as t1
left join visit_purchase as t2 on t1.visit_id = t2.visit_id)
select product_category,
round(sum(case when cart_add = 1 and purchase = 1 then 1 else 0 end) * 100.0 / sum(page_view),2) as page_view_to_purchase_rate,
round((sum(case when cart_add > 0 and purchase = 1 then 1 else 0 end) * 100.0 / sum(cart_add)),2) as add_to_cart_to_purchase_rate,
round((sum(case when page_view > 0 and cart_add > 0 then 1 else 0 end) * 100.0 / sum(page_view)),2) as page_view_to_add_to_cart_rate,
round(sum(CASE WHEN cart_add > 0 AND purchase = 0 THEN 1 ELSE 0 END) * 100.0 / SUM(cart_add), 2) AS cart_add_to_abandoned_rate
from combined_product_events
group by 1
order by 1



-- Q9  Which products were added to carts by users during their website visits?

with product_sequence as (select e.visit_id,e.cookie_id as user_id,
group_concat(case when e.event_type = 2 then ph.page_name else null end order by e.sequence_number, ', ') as cart_products
from events as e
left join clique_bait.page_hierarchy as ph on e.page_id = ph.page_id
group by 1,2
)
select ps.visit_id,ps.user_id,substring_index(substring_index(ps.cart_products, ', ', n), ', ', -1) as product_added
from product_sequence as ps
join (select 1 + units.i + tens.i * 10 as n
from(select 0 as i union select 1 union select 2 union select 3 union select 4 union 
select 5 union select 6 union select 7 union select 8 union select 9) as units
cross join
(select 0 as i union select 1 union select 2 union select 3 union select 4 union 
select 5 union select 6 union select 7 union select 8 union select 9) as tens
order by n
) as numbers
on char_length(ps.cart_products) - char_length(replace(ps.cart_products, ', ', '')) >= n - 1
limit 10




-- Q10 Conduct an analysis of prevalent sequences of products added to the cart.

with cartsequences as (select u.user_id,ph.page_name,e.event_time,
row_number() over (partition by u.user_id order by e.event_time) as sequence_number
from events e
join users u on e.cookie_id = u.cookie_id
join page_hierarchy ph on e.page_id = ph.page_id
where e.event_type = 2 
)
select prev.page_name as previous_product_name,curr.page_name as current_product_name,count(*) as sequence_count
from cartsequences curr
join cartsequences prev on curr.user_id = prev.user_id and curr.sequence_number = prev.sequence_number + 1
group by 1,2
order by 3 desc


-- Q11 What insights can be gleaned from the monthly variations in user engagement across different product pages on our website?

select ph.product_id, ph.page_name,
date_format(e.event_time,"%Y-%m")as month, 
count(distinct e.visit_id)as unique_visits, count(*) as total_events
from events e
join page_hierarchy ph on e.page_id = ph.page_id where product_id is not null
group by 1,2,3 order by 3 


-- Q12 What are the sequences of products added to the cart during each user visit, including the associated visit ID and user ID?

select * from 
     ( select e.visit_id, u.user_id, count(*) as product_count,
    group_concat(case when e.event_type = 2 then ph.page_name else null end
	   order by e.sequence_number separator' >> ') as cart_sequence
    from events e
    left join page_hierarchy ph on e.page_id = ph.page_id
    join users u on e.cookie_id = u.cookie_id
    where e.event_type = 2 
    group by e.visit_id,  u.user_id
) as s
 

-- Q13 Which product attained the highest number of purchases in each respective month?

select * from(select 
    month, product_name, product_category, purchased_count,
    row_number() over(partition by month order by purchased_count desc) as row_num
from (select date_format(e.event_time,"%Y-%m")as month, ph.page_name as product_name,
      ph.product_category, sum(case when e.event_type = 2 then 1 else 0 end) as purchased_count
    from page_hierarchy ph 
    join events e on e.page_id = ph.page_id
    where ph.product_id is not null
    and exists(select 1 from events where event_type = 3 and e.visit_id=visit_id group by visit_id)
    group by 1,2,3
)as s 
)as m where m.row_num <= 1


-- Q14 What is the average duration of user engagement on each product page?

select product_id,page_name,
round(avg(timestampdiff(minute, event_time, next_event_time)),2)as avg_time_spent_minute
from(select 
    e.page_id,e.event_time,
	lead(e.event_time) over (partition by e.page_id order by e.event_time)as next_event_time
	from events e)as time_spent 
join page_hierarchy p on time_spent.page_id = p.page_id where p.product_id is not null
group by product_id,page_name


-- Q15 What insights can be derived from the conversion funnel analysis for user interactions on our platform, and how does it differ across various product pages?
 
with purchases as(select p.page_name,
    sum(case when e.event_type = 2 then 1 else 0 end)as purchased
    from page_hierarchy as p  join events e on e.page_id = p.page_id
   where exists(select visit_id from events where event_type=3 and e.visit_id=visit_id group by 1)
	group by 1),
rate as(select p.page_name, sum(case when e.event_type=1 then 1 else 0 end)as page_views,				
	sum(case when e.event_type = 2 then 1 else 0 end) as cart_adds
	from  events e join page_hierarchy p on e.page_id=p.page_id
	group by 1),
abandoned as (select p.page_name, count(*) as abandoned
    from page_hierarchy p  join events e on e.page_id = p.page_id 
  where e.event_type=2 and not exists(select visit_id from events where event_type=3 and e.visit_id=visit_id)
    group by 1 )
select a.page_name as product_name,round(avg(r.cart_adds/r.page_views)*100,2)as pageview_to_cartadd_rate, 
round(avg(p.purchased / r.cart_adds)*100 ,2)  as cartadd_to_purchase_rate,
round(avg(p.purchased /r.page_views) *100,2) as pageview_to_purchase_rate,
round(avg(a.abandoned /r.cart_adds) *100,2)  as cartadd_to_abandoned_rate
from Rate r  join purchases p on r.page_name = p.page_name
join abandoned a on a.page_name = p.page_name group by 1 order by 3 desc


-- Q16 What product exhibited the highest likelihood of abandonment?

with abandoned as (select ph.product_id,ph.page_name, ph.product_category, 
	count(*) as abandoned from page_hierarchy ph
    join events e on e.page_id = ph.page_id
    where  e.event_type = 2
    and not exists (select visit_id from events where event_type = 3 and e.visit_id = visit_id)
    group by 1,2,3 ),
cp as(select  ph.product_id,sum(case when e.event_type = 2 then 1 else 0 end)as cart_add
from events e
join page_hierarchy ph on ph.page_id = e.page_id
where ph.product_id is not null group by 1
)
select a.product_id, a.page_name as product_name, a.product_category, 
(a.abandoned/cp.cart_add)*100 as cartadd_to_abandaned_rate
from cp  join abandoned a on a.product_id = cp.product_id  
order by 4 desc limit 1


-- Q17 What is the comprehensive breakdown of page view counts, cart additions, abandoned carts, and purchase frequencies for each product?

with product_page_events as (select e.visit_id,ph.product_id,ph.page_name,ph.product_category,
sum(case when event_type = 1 then 1 else 0 end) as page_view,
sum(case when event_type = 2 then 1 else 0 end) as cart_add
from events e
join page_hierarchy ph on e.page_id = ph.page_id
where ph.product_id is not null
group by 1,2,3,4),
visit_purchase as (select distinct visit_id
from events
where event_type = 3),
combined_product_events as (select t1.visit_id,t1.product_id,t1.page_name,t1.product_category,t1.page_view,
t1.cart_add,case when t2.visit_id is not null then 1 else 0 end as purchase
from product_page_events as t1
left join visit_purchase  as t2 on t1.visit_id = t2.visit_id)
select page_name as product,
sum(page_view) as page_views,
sum(cart_add) as cart_adds,
sum(case when cart_add = 1 and purchase = 0 then 1 else 0 end) as abandoned,
sum(case when cart_add = 1 and purchase = 1 then 1 else 0 end) as purchases
from combined_product_events
group by  product


-- Q18 How are user interactions distributed across various product pages, taking into account the unique aspects of user visits, sequences, and 
--     cookies for each product?

select p.product_id, p.page_name as product_name,
count(distinct e.sequence_number)as unique_sequences,
count(distinct u.user_id) as unique_users,
count(distinct e.cookie_id) as unique_cookies,
count(distinct e.visit_id) as unique_visits,
count(*) as total_interactions
from users u
join events e on e.cookie_id = u.cookie_id
join page_hierarchy p on p.page_id = e.page_id
where p.product_id is not null group by 1,2



