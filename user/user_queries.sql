-- Q1 Analysis of Unique Users, Unique Cookies, and Total Interactions Recorded.

select count(distinct u.user_id) as unique_users,
count(distinct u.cookie_id) as unique_cookies,
count(*) as total_interactions
from users u
join events e on e.cookie_id = u.cookie_id


-- Q2 Analyze User Behavior Regarding Page Visits and Determine the Most Frequently Visited Page.

select *
from ( select u.user_id, p.page_name, count(*) as count_of_visits,
row_number () over(partition by user_id order by count(*) desc) as row_no
from events as e
right join users as u on u.cookie_id = e.cookie_id
join page_hierarchy as p on p.page_id = e.page_id
where p.product_id is not null
group by 1, 2
)as s
where s.row_no = 1


-- Q3 What insights can be derived from the variation in user engagement, considering the number of unique users, visit counts, and total events recorded each month?

select date_format(event_time, "%Y-%m") as date,
count(distinct u.user_id) as unique_users,
count(distinct u.cookie_id) as unique_cookies,
count(distinct visit_id) as visit_count,
count(*) as event_count
from events e
join users u on e.cookie_id = u.cookie_id
group by date order by date


-- Q4 How has the number of active users evolved in each month?

select date_format(u.start_date, '%Y-%m') as registration_month,
count(distinct u.user_id) as total_active_users
from users u
group by 1
order by 1


-- Q5 What insights can be gleaned from the user retention rate across multiple visits?

select count(user_id) as total_users,
count(case when visit_count > 1 then user_id end) as returning_users,
(count(case when visit_count > 1 then user_id end) / count(user_id)) * 100 as retention_rate
from (select u.user_id, COUNT(*) as visit_count
from events e
join users u on u.cookie_id = e.cookie_id
group by user_id
) as user_visits


-- Q6 What insights can be derived regarding the peak hours for user activity on the site?

select hour(event_time) as hour_of_day,
count(*) as activity_count
from events
group by 1
order by 2 desc


-- Q7 What are the session count and total events triggered by each user?

select u.user_id, count(distinct e.visit_id) as session_count,
count(*) as total_events_triggered,
round (count(*)/count(distinct e.visit_id),2)as avg_events_per_session
from users u
join events e on u.cookie_id = e.cookie_id
group by u.user_id	


-- Q8 What is the average number of cookies per user?

select avg(cookie_count) as average_cookies_per_user
from (select user_id,
count(distinct cookie_id) as cookie_count
from users
group by user_id) as user_cookie_counts


-- Q9 How does the event distribution vary among users, and what insights can be derived from this analysis?

select user_id,
sum(case when ei.event_name = 'Page View' then 1 else 0 end) as page_view_count,
sum(case when ei.event_name = 'Add to Cart' then 1 else 0 end) as add_cart_count,
sum(case when ei.event_name = 'Purchase' then 1 else 0 end) as purchase_count,
sum(case when ei.event_name = 'Ad Click' then 1 else 0 end) as ad_click_count,
sum(case when ei.event_name = 'Ad Impression' then 1 else 0 end) as ad_impression_count
from users u
join events e on u.cookie_id = e.cookie_id
join event_identifier ei on e.event_type = ei.event_type
group by 1



-- Q10 What is the average duration of each user session on the website?

select user_id, round(avg(session_duration_seconds)/60,2) as avg_session_duration_in_minutes
from (select u.user_id,visit_id,
    max(event_time) - min(event_time) as session_duration_seconds
    from events e
    join users u on e.cookie_id = u.cookie_id
    group by 1,2
) as session_durations group by 1 


-- Q11 How many unique visits do all users make per month?

select month(event_time) as month,
count(distinct visit_id) as uniqe_visit
from events 
group by 1


-- Q12 What insights can be derived from the analysis of user engagement and interaction patterns, and how do users respond to different types of events?

select u.user_id, count(e.event_type) as total_impressions,
sum(case when e.event_type = 1 then 1 else 0 end) as page_view,
sum(case when e.event_type = 2 then 1 else 0 end) as cart_add,
sum(case when e.event_type = 3 then 1 else 0 end) as purchases,
sum(case when e.event_type = 4 then 1 else 0 end) as ad_impression,
sum(case when e.event_type = 5 then 1 else 0 end) as ad_click
from users u
join events e on u.cookie_id = e.cookie_id
group by 1


-- Q13 Calculate the total and distinct number of cookies for each user, and derive insights from the analysis.

select u.user_id,
count(e.cookie_id)as total_cookies,
count(distinct e.cookie_id)as unique_cookie
from users u
join events e on e.cookie_id = u.cookie_id
group by 1


-- Q14 Determine the most common user journey from the Home Page to the Purchase Confirmation, and extract insights from the findings.

select event_sequence, count(*) as sequence_count 
from (select u.user_id,
	group_concat(distinct ei.event_name order by e.event_time separator ' >> ')as event_sequence
     from events e
     join users u on u.cookie_id = e.cookie_id
     join event_identifier ei on ei.event_type = e.event_type
     group by 1) as sa 
     where event_sequence like "%Purchase"
group by 1 order by 2 desc


-- Q15 What are the average time intervals between consecutive events for each user?

with event_intervals as (
select u.user_id, e.event_time,
timestampdiff(hour,lag(e.event_time) over(partition by u.user_id order by e.event_time), e.event_time) as time_interval
from events e
join users u on e.cookie_id = u.cookie_id)
select user_id, round(avg(time_interval),2) as avg_time_between_events_in_hours
from event_intervals group by user_id


-- Q16 Identify the unique users who have made purchases and their corresponding purchase frequencies.

select distinct u.user_id, count(*)as purchase
from users u
join events e on u.cookie_id = e.cookie_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "purchase"
group by user_id 
order by 2 desc


-- Q17 What is the number of distinct users who proceed to checkout but do not complete a purchase?

select user_id as userid_which_checkout_but_not_purchase 
from (select u.user_id,
    max(case when ei.event_name= "Page View"and p.page_name = "Checkout"then 1 else 0 end)as checkout,
    max(case when ei.event_name= "Purchase" then 1 else 0 end) as purchase
from users u
join events e on  u.cookie_id = e.cookie_id
join event_identifier ei on ei.event_type= e.event_type
join page_hierarchy p on e.page_id = p.page_id
group by 1
having checkout = 1 and purchase= 0)as s


-- Q18 How many users have initiated cart additions without completing a purchase, and what is the frequency of their visits?

select u.user_id,count(*)as visit_count, 
count(distinct e.cookie_id) as abandoned_checkouts_count
from events e
join users u on u.cookie_id=e.cookie_id
join event_identifier ei on e.event_type=ei.event_type
where ei.event_name = "Add to Cart"
and u.cookie_id not in(
          select e.cookie_id from events e 
          join event_identifier ei on e.event_type=ei.event_type
          where ei.event_name = "Purchase")
group by u.user_id


-- Q19 Compute the average conversion rates for page views to cart additions, cart additions to purchases, page views to purchases, and cart additions 
--     to abandoned actions across all pages.

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
select round(avg(r.cart_adds/r.page_views)*100,2)as pageview_to_cartadd_rate, 
round(avg(p.purchased / r.cart_adds)*100 ,2)  as cartadd_to_purchase_rate,
round(avg(p.purchased /r.page_views) *100,2) as pageview_to_purchase_rate,
round(avg(a.abandoned /r.cart_adds) *100,2)  as cartadd_to_abandoned_rate
from Rate r  join purchases p on r.page_name = p.page_name
join abandoned a on a.page_name = p.page_name 