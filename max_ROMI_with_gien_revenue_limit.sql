with Two_medias as(
	select ad_date
		, 'Facebook' as media_source
		, c.campaign_name
		, a.adset_name
		, f.spend
		, f.impressions
		, f.reach
		, f.clicks
		, f.leads
		, f.value
	from public.facebook_ads_basic_daily f
	left join facebook_campaign c on f.campaign_id=c.campaign_id
	left join facebook_adset a on f.adset_id=a.adset_id
	union
	select ad_date
		, 'Google' as media_source
		, campaign_name
		, adset_name
		, spend
		, impressions
		, reach
		, clicks
		, leads
		, value
	from public.google_ads_basic_daily g),
camp_ROMI as(
	select campaign_name
		, sum(spend) as total_spend
		, sum(impressions) as total_views
		, sum(clicks) as total_clicks
		, sum(value) as total_conv
		, round(1.0*(sum(value)-sum(spend))/nullif(sum(spend),0)*100,2) as ROMI
		, ROW_NUMBER() OVER (ORDER BY ROUND(1.0 * (SUM(value) - SUM(spend)) / NULLIF(SUM(spend), 0) * 100, 2) DESC) AS row_num
	from Two_medias
	group by campaign_name
	having sum(spend)>500000
	order by round(1.0*(sum(value)-sum(spend))/nullif(sum(spend),0)*100,2) desc)
select
    campaign_name
    , adset_name
    , sum(spend) as total_spend
	, sum(impressions) as total_views
	, sum(clicks) as total_clicks
	, sum(value) as total_conv
	, round(1.0*(sum(value)-sum(spend))/nullif(sum(spend),0)*100,2) as ROMI
from Two_medias
where campaign_name = (SELECT campaign_name FROM camp_ROMI WHERE row_num = 1)
group by campaign_name, adset_name
order by round(1.0*(sum(value)-sum(spend))/nullif(sum(spend),0)*100,2) desc;







