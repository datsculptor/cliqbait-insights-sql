-- Q1 Determine the page view tally for each page.

select ph.page_name as page_name,
sum(case when event_type = 1 then 1 else 0 end) as page_view,
from page_hierarchy ph
join events e on e.page_id = ph.page_id
group by 1
order by 2 desc


-- Q2 What is the distribution of events across various pages of the website, and what event sequences are observed on each page?

select p.page_id, p.page_name, 
count(distinct e.sequence_number)as unique_sequence_count, count(*)as total_sequences,
group_concat(distinct ei.event_name order by e.sequence_number separator', ')as event_sequence
from events e
join users u on u.cookie_id = e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
group by 1,2
order by 1


-- Q3 What is the bounce rate, representing the percentage of visits that involve viewing only one page, for each page?

select ph.page_name as page_name,
sum(case when sequence_number = 1 then 1 else 0 end) / count(*) as bounce_rate
from events e 
join page_hierarchy ph on ph.page_id = e.page_id
group by ph.page_name



-- Q4 What are the total number of individuals, unique visitors, and average number of visitors per page?

select ph.page_name as page_name,
count(u.user_id) as total_users,
count(distinct u.user_id) as unique_users
avg(distinct u.user_id) as unique_users
from events e 
join page_hierarchy ph on ph.page_id = e.page_id
join users u on u.cookie_id = e.cookie_id
group by 1




-- Q5 What is the highest average sequence number for each page?

select page_name as page_name,
avg(sequence_number) as avg_sequence_number
from events e 
join page_hierarchy ph on ph.page_id = e.page_id
group by 1



-- Q6 How does page engagement vary over different time periods? By examining the pattern of page views over time, can we identify seasonal trends in user behavior?

select ph.page_id, ph.page_name,
    date_format(e.event_time, '%Y-%m') as month,
    count(*) as total_page_views
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by 1,2,3
order by 1


-- Q7 Determine the average number of unique cookies for each page.

select ph.page_name as page_name,
avg(cookie_count) as average_cookie_count
from page_hierarchy ph
left join (select page_id,
count(distinct cookie_id) as cookie_count
from
events
group by 1
) as cookie_counts on ph.page_id = cookie_counts.page_id
group by 1


-- Q8 Compute the total and unique visitors for each page.

select ph.page_name as page_name,
count(e.visit_id) as total_visitors_count,
count(distinct e.visit_id) as unique_visitors_count
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by 1
order by 2 desc


-- Q9 Calculate both the total and unique cookie IDs attributed to each page

select ph.page_name as page_name,
count(e.cookie_id) as total_visitors_count,
count(distinct e.cookie_id) as unique_visitors_count
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by 1
order by 2 desc


-- Q10 What are the entry rates for each page, revealing the most prevalent starting points for visitors? How do these entry rates fluctuate among various pages?

select ph.page_name, count(*) as total_entries,
	count(distinct cookie_id) as total_users,
	round(count(*) / count(distinct cookie_id),2)as entry_rate
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by 1 
order by 4 desc


-- Q11 Compute the average duration users spend between consecutive events on each page.

select p.page_id,p.page_name, 
round(avg(case when next_event.event_time > e.event_time 
		then timestampdiff(minute, e.event_time, next_event.event_time) 
		else null end),2) as avg_time_spent_minutes
from events e
join page_hierarchy p using (page_id)
join events next_event on e.cookie_id = next_event.cookie_id 
	 and e.sequence_number + 1 = next_event.sequence_number
group by 1,2 order by 1


-- Q12 Identify Pages with Elevated Bounce Rates (Page Views Without Subsequent Cart Additions)

select page_name, count(*) as total_bounces,
round(count(*) / (select count(*) from events where event_type = 1) *100,2) as bounce_rate
from events 
join page_hierarchy on events.page_id = page_hierarchy.page_id
where not exists(select visit_id from events e2 where e2.event_type =2 and e2.visit_id = events.visit_id)
and event_type = 1
group by 1
order by 2 desc


-- Q13 What are the average interaction rates for each page?

select ph.page_name,
round(count(*)/count(distinct e.visit_id),2) as avg_interaction_rate
from events e
join page_hierarchy ph on e.page_id = ph.page_id
group by ph.page_name
order by avg_interaction_rate desc


-- Q14 What is the conversion rate for product additions to the cart on each respective page?

select p.page_name, count(distinct u.user_id) as unique_users,
count(*) as total_cart_adds,
round(count(*) / count(distinct u.user_id) ,2) as conversion_rate
from events e
join users u on u.cookie_id=e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "Add to Cart" 
group by 1


-- Q15 How effectively do our website's pages engage users, and what is the conversion rate of visitors into engaged users across these pages?

select p.page_id,p.page_name, count(distinct u.user_id) as unique_users,
count(*) as total_page_views,
round(count(*) / count(distinct u.user_id) ,2) as conversion_rate
from events e
join users u on u.cookie_id=e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "Page View" 
group by 1,2


-- Q16 Identify the predominant pages visited and user actions undertaken.

select p.page_id, p.page_name, e.event_type, ei.event_name, 
count(*) as visit_count
from events e
join event_identifier ei on e.event_type = ei.event_type
join page_hierarchy p on e.page_id = p.page_id
group by 1,2,3,4
order by 3 

-- Q17 We have a single product page designed to drive sales. How can we best measure user engagement with this page and assess its
-- effectiveness in completing purchases?

select p.page_name, count(distinct u.user_id) as unique_users,
count(*) as total_purchases,
round(count(*) / count(distinct u.user_id) ,2) as conversion_rate
from events e
join users u on u.cookie_id=e.cookie_id
join page_hierarchy p on e.page_id = p.page_id
join event_identifier ei on e.event_type = ei.event_type
where ei.event_name = "Purchase" 
group by 1