# Before running any hive, ssh into the box and start a hive interactive session

# from a local terminal
ssh ben@slave01.hackathonclt.org

# from the ssh session, enter a hive interactive session
hive

#### HQL Queries ####

### After several exploratory branches, we landed on the following two queries for our analysis
## Subsetting Step:
  
# 1 - Remove the nulls and non-product related transactions such as taxes
drop table arunben.hack;
create table arunben.hack as
select * from default.hackathon_real where upc_number!= 0

# 2 - Summarize Step:

# primary dataset for analysis
create table cat_subcat_sale_dollars as
select
category_description,
subcategory_description,
express_lane,
sum(extended_price_amount) as sub_cat_sale_dollars,
sum(extended_discount_amount) as sub_cat_discount_dollars
from arunben.hack
group by category_description,subcategory_description,express_lane

### Other Queries for analysis or from unpursued branches ###

#query to get item counts for each item and the express_lane flag
use arunben;
create table express_item_sales as
select
express_lane,
upc_number,
item_description,
sum(item_quantity) as item_count
from arunben.hack
group by express_lane,upc_number,item_description

#query to get amount spent, discount received for each trip made by a house hold...
use arunben;
create table hhid_express_sales as
select
hhid,
express_lane,
receipt_number,
sum(extended_price_amount) total_bill,
sum(extended_discount_amount) as discount
from arunben.hack
group by hhid,express_lane,receipt_number
order by hhid,receipt_number,express_lane

# to understand the category description quantities
drop table if exists arunben.cat_desc_table;
create table if not exists arunben.cat_desc_table as
select CATEGORY_DESCRIPTION, express_lane, sum(ITEM_QUANTITY) as ITEM_QUANTITY
from arunben.hack group by CATEGORY_DESCRIPTION, express_lane;

#determine what the price columns are
select EXTENDED_PRICE_AMOUNT, EXTENDED_DISCOUNT_AMOUNT, DISCOUNT_QUANTITY from arunben.hack limit 30;

#trace one HH and trip to understand data structure
select HHID, RECEIPT_NUMBER, UPC_NUMBER, ITEM_DESCRIPTION, EXTENDED_PRICE_AMOUNT, EXTENDED_DISCOUNT_AMOUNT, 
DISCOUNT_QUANTITY from arunben.hack where HHID = "01330f85-6693-4bf4-9ed8-bd7fa3fb1bdc" 
and RECEIPT_NUMBER = 1219767182 order by ITEM_DESCRIPTION;

