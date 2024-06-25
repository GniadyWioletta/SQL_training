# max_ROMI_with_given_revenue_limit

Two_medias ->Connects two databases - Facebook and Googgle ads data with left join
camp_ROMI -> takes Two_medias data and aggregates it grouping by campaign name. It takes only data its revenue is hiher than 50000. Sorts the data from the highest ROMI.
The table shows adset_name and campaign name with the highest ROMI.

# url_parameters_decoding

Two_medias ->Connects two databases - Facebook and Googgle ads data with left join
url_parameters split into url_medium and utm_campaign
utm_campaign -> by function extract_utm_campaign decodes segment after segment

# CTR_CPM_ROMI_difference_with_previous_month

Connects two databases
getting previous month ROMI lag an partition option
presenting the diference for ROMI with current and previous month


