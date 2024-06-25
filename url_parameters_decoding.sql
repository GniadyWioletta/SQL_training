--CZEŚĆ. Nie działa mi :)
--Ale chciałabym wiedzieć, co robię źle z tą funkcją

CREATE OR REPLACE FUNCTION extract_utm_campaign(str varchar)
RETURNS varchar AS $$
DECLARE counter int=1
DECLARE code varchar
DECLARE txt varchar
DECLARE remaining varchar
SET remaining = str
begin 
	while counter<2
		Case
			WHEN leading(remaining, 3) is null then set counter=2
			ELSE 
				begin
					SET code=decode(trailing(remaining, length(remaining)-3, 'UTF-8') --fragment po fragmencie... 
					SET txt=CONCAT(txt, code)	
					SET remaining=leading(remaining, 3)
				end
		end
	end loop
  RETURN txt
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

with fg as(
	select ad_date
		, 'Facebook' as media_source
		, c.campaign_name
		, a.adset_name
		, 1.0 * coalesce(f.spend,0) as spend
		, 1.0 * coalesce(f.impressions,0) as impressions
		, 1.0 * coalesce(f.reach,0) as reach
		, 1.0 * coalesce(f.clicks,0) as clicks
		, 1.0 * coalesce(f.leads,0) as leads
		, 1.0 * coalesce(f.value,0) as value
		, f.url_parameters
	from public.facebook_ads_basic_daily f
	left join facebook_campaign c on f.campaign_id=c.campaign_id
	left join facebook_adset a on f.adset_id=a.adset_id
	union
	select ad_date
		, 'Google' as media_source
		, campaign_name
		, adset_name
		, 1.0 * coalesce(spend,0) as spend --domyslna wartosc zamiast null
		, 1.0 * coalesce(impressions,0) as impressions
		, 1.0 * coalesce(reach,0) as reach
		, 1.0 * coalesce(clicks,0) as clicks
		, 1.0 * coalesce(leads,0) as leads
		, 1.0 * coalesce(value,0) as value
		, url_parameters
	from public.google_ads_basic_daily g)
select ad_date
		, campaign_name
		, nullif(lower(url_parameters), 'NaN')  as url_parameters
		, case 
			when url_parameters = 'NaN' then Null
			when substring(url_parameters, 'utm_medium=([^&#$]+)') is not Null then substring(url_parameters, 'utm_medium=([^&#$]+)')
			else substring(url_parameters, 'utm_mediun=([^&#$]+)')
		end as url_medium
		, case
			when substring(url_parameters, 'utm_campaign=([^&#$]+)') = 'nan' then null
			when substring(substring(url_parameters, 'utm_campaign=([^&#$]+)'),'%') is not null then extract_utm_campaign(substring(url_parameters, 'utm_campaign=([^&#$]+)'))
			else substring(url_parameters, 'utm_campaign=([^&#$]+)')
		end as utm_campaign
		, sum(spend) as total_spend
		, sum(impressions) as total_impressions
		, sum(clicks) as total_clicks
		, sum(value) as total_value
		, round(1.0*sum(spend)/nullif(sum(clicks),0),2) as CPC
		, round(1.0*sum(spend)/1000,2) as CPM
		, round(1.0*count(clicks)/nullif(sum(impressions),0),2) as CTR
		, round(1.0*sum(spend)/nullif(sum(leads),0),2) as CPL
		, round(1.0*(sum(value)-sum(spend))/nullif(sum(spend),0)*100,2) as ROMI
from fg
group by ad_date, campaign_name, url_parameters, utm_campaign;
