with fg_prev as(
	with fg as(
		select 
			cast(date_trunc('month', ad_date) as date) as ad_date
			, 'Facebook' as media_source
			, c.campaign_name
			, a.adset_name
			, 1.0 * coalesce(f.spend,0) as spend
			, 1.0 * coalesce(f.impressions,0) as impressions
			, 1.0 * coalesce(f.reach,0) as reach
			, 1.0 * coalesce(f.clicks,0) as clicks
			, 1.0 * coalesce(f.leads,0) as leads
			, 1.0 * coalesce(f.value,0) as value
			,	nullif(lower(substring(f.url_parameters, 'utm_campaign=([^&#$]+)')), 'nan') as utm_campaign
		from public.facebook_ads_basic_daily f
		left join facebook_campaign c on f.campaign_id=c.campaign_id
		left join facebook_adset a on f.adset_id=a.adset_id
		union
		select 
			cast(date_trunc('month', ad_date) as date) as ad_date
			, 'Google' as media_source
			, campaign_name
			, adset_name
			, 1.0 * coalesce(spend,0) as spend --domyslna wartosc zamiast null
			, 1.0 * coalesce(impressions,0) as impressions
			, 1.0 * coalesce(reach,0) as reach
			, 1.0 * coalesce(clicks,0) as clicks
			, 1.0 * coalesce(leads,0) as leads
			, 1.0 * coalesce(value,0) as value
			, nullif(lower(substring(url_parameters, 'utm_campaign=([^&#$]+)')), 'nan') as utm_campaign
		from public.google_ads_basic_daily g
		order by ad_date desc)
	select 
		ad_date as ad_date
		, utm_campaign
		, sum(spend) as total_spend
		, sum(impressions) as total_impressions
		, sum(clicks) as total_clicks
		, sum(value) as total_value
		, round(1.0*sum(spend)/nullif(sum(clicks),0),2) as CPC
		, round(1.0*sum(spend)/1000,2) as CPM
		, round(1.0*count(clicks)/nullif(sum(impressions),0),2) as CTR
		, round(1.0*(sum(value)-sum(spend))/nullif(sum(spend),0)*100,2) as ROMI
		, LAG(ROUND(1.0 * SUM(spend) / 1000, 2)) OVER (PARTITION BY utm_campaign ORDER BY ad_date) AS prev_month_cpm
		, LAG(ROUND(1.0 * COUNT(clicks) / NULLIF(SUM(impressions), 0), 2)) OVER (PARTITION BY utm_campaign ORDER BY ad_date) AS prev_month_ctr
       	, LAG(ROUND(1.0 * (SUM(value) - SUM(spend)) / NULLIF(SUM(spend), 0) * 100, 2)) OVER (PARTITION BY utm_campaign ORDER BY ad_date) AS prev_month_romi
	from fg
	group by ad_date, utm_campaign
	order by utm_campaign desc)
select 
		ad_date
		, utm_campaign
		, CPM
		, case 
			when prev_month_cpm is not null then cpm - prev_month_cpm
			else NULL
		end as CPM_diff
		, CTR
		, case 
			when prev_month_ctr is not null then CTR - prev_month_ctr
			else NULL
		end as CTR_diff
		, ROMI
		, case 
			when prev_month_romi is not null then ROMI - prev_month_romi
			else NULL
		end as ROMI_diff
from fg_prev
where ad_date is not null
order by utm_campaign, ad_date

	


