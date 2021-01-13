with 

cohort_base as (
SELECT 
  date_trunc('Month', subscription_start_date) ::date as cohort,
  date_trunc('Month', month) :: date as month,
  datediff('Month', cohort, month) as cohort_age,
  is_tcs_subscription as TCS,
  is_strictly_ka_batch as KA,
  count (distinct subscription_name) as volume,
  sum(gross_mrr)::integer as mrr,
  sum(CMRR)::integer as CMRR
from dtm_finance.monthly_zuora_subscription_dimensions

where month >= '2020-01-01' 
  and gross_mrr > 0
  and subscription_start_date <= month
  and country = 'fr'

group by 1,2,3,4,5
order by 1 desc)

,cohort_start_info as (
  SELECT
    cohort,
    TCS,
    KA,
    volume as volume_start,
    mrr as mrr_start,
    CMRR as CMRR_start
  FROM cohort_base
  WHERE cohort = month
)

SELECT
  cohort_base.cohort,
  cohort_base.cohort_age,
  cohort_base.TCS,
  cohort_base.KA,
  (1.00 * cohort_base.volume / cohort_start_info.volume_start) as churn_in_percent,
  cohort_base.volume
  
  from cohort_base
JOIN cohort_start_info on 
  cohort_base.cohort = cohort_start_info.cohort 
  and cohort_base.TCS = cohort_start_info.TCS 
  and cohort_base.KA = cohort_start_info.KA

where cohort_base.TCS = 'f'
  and cohort_base.KA = 'f'
  and cohort_base.cohort >= '2020-01-01'
