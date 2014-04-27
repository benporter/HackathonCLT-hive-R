#!/usr/bin/env Rscript

# Load Libraries

library(reshape2)
library(sqldf)
library(ggplot2)
library(treemap)

# Read in data

setwd("~/Hackathon")

prod_file <- "catsales.csv"
df <- read.csv(prod_file,sep="|")
# alternate methods:
#df <- read.csv(file=prod_file,sep=",",header=FALSE)
#df <- as.data.frame(do.call(rbind,strsplit(readLines(prod_file),'|',fixed=T)))
#df <- read.table(file=prod_file,header=FALSE,sep="~")

#examine data
head(df)

# assign column names
colnames(df) <- c("category","subcategory","expresslane","price","discount")

# change datatypes and view summaries
df$price <- as.double(df$price)
df$discount <- as.double(df$discount)
summary(df)

#df <- subset(df,price>=0)

# Fill in the non-EL missing value records
full_list <- sqldf("select category, subcategory
                    from df
                    group by category, subcategory")

full_list$expresslane <- 0
full_list2 <- full_list
full_list2$expresslane <- 1

nrow(full_list)
full_list <- rbind(full_list,full_list2)
nrow(full_list)

df2 <- sqldf("select l.*,
                     r.price,
                     r.discount
             from full_list l left join 
             df r on
             l.category=r.category and
             l.subcategory=r.subcategory and
             l.expresslane=r.expresslane"
             )
head(df2)
summary(df2)

for(i in 1:nrow(df2)) {
   if(is.na(df2$price[i])) {
     df2$price[i] <- 0
  }
  
  if(is.na(df2$discount[i])) {
    df2$discount[i] <- 0
  }
}

summary(df2)

# remove the subcategories
df_cat <- sqldf("select category,
                        expresslane,
                        sum(price) as price,
                        sum(discount) as discount
                 from df2
                 group by category,
                          expresslane")

head(df_cat)

# compute the percentage discount
df$percent_discount <- 1 - (df$price / (df$price + df$discount))
df_cat$percent_discount <- 1 - (df_cat$price / (df_cat$price + df_cat$discount))
summary(df_cat)

#fill in missing values with zero
for(i in 1:nrow(df_cat)) {
  if(is.na(df_cat$percent_discount[i])) {
    df_cat$percent_discount[i] <- 0
  }  
}

# subset to the 20 highest spending products
rows_to_keep <- sqldf("
      select category,price
      from (
           select df.category,sum(price) as price 
           from
           df_cat df
           group by df.category)
      order by price desc")

first20_rows <- rows_to_keep$category[1:20]

df_cat_7MM <-subset(df_cat,category %in% first20_rows)
summary(df_cat_7MM)

df_cat_7MM<- sqldf("select * from
                    df_cat_7MM
                    order by price,category,expresslane")


treemap(subset(df,price>=0),
       index="category",
       vSize="price",
       type="value",
       fontfamily.labels="ComicSans")

# bar chart
# lack of penetration with the Express Lane Channel
g <- ggplot(df_cat_7MM,aes(category,price,fill=factor(expresslane)),stat="identity") + geom_bar()
g <- g + coord_flip()
g <- g + ggtitle("Top Selling Product Categories (top 20)\n
                  Blue:  Express Lane\n
                  Red:  In-store")
g <- g + ylab("Total Sales") + xlab("Product Categories")
g

head(df_cat_7MM)
df_cat_7MM_proportion <- sqldf("select el.category,
                                       (el.el_price/nonel.nonel_price) as proportion_el
                                from
                                (select category, sum(price) as nonel_price
                                 from df_cat_7MM
                                 where expresslane = 0
                                 group by category) nonel
                                inner join
                                (select category, sum(price) as el_price
                                 from df_cat_7MM
                                 where expresslane = 1
                                 group by category) el
                                 on nonel.category = el.category
                                group by el.category")

#subset out in-store sales and look again
# yogurt does surpisingly well, try more yogurt coupons
g7 <- ggplot(df_cat_7MM_proportion,aes(category,y=proportion_el)) + geom_bar(stat = "identity")
g7 <- g7 + coord_flip()
g7 <- g7 + ggtitle("Top Selling Product Categories (top 20)\n& Their Proportion in the Express Lane")
g7 <- g7 + ylab("Percent of Total Sales") + xlab("Product Categories")
g7

#line separation chart
# they don't demand as much of a discount to purchase! the best kind of customer!!!!
g2 <- ggplot(df_cat_7MM,aes(x=category,y=percent_discount,group=factor(expresslane),
                            colour=factor(expresslane)),stat="bin") + geom_line()
g2 <- g2 + coord_flip()
g2 <- g2 + ggtitle("Express Lane vs In-store Purchase Discounts\n
                   Blue:  Express Lane\n
                   Red:  In-store")
g2 <- g2 + ylab("Percentage Discount") + xlab("Product Categories")
g2

############ Pick back up with Df2 ########################

head(df2)

df2_summ <- sqldf("select category, subcategory, sum(price) as price, sum(discount) as discount
                  from df2
                  group by category, subcategory")
df2_summ$percent_discount <- 1 - (df2_summ$price / (df2_summ$price + df2_summ$discount))

head(df2_summ)

# might be a pattern, but it's kind of hard to tell
# bottom right, people swooping in for the single item and leaving
g3 <- ggplot(df2_summ,aes(x=percent_discount,y=price)) + geom_point(shape=1)
g3 <- g3 + xlab("Percentage Discount") + ylab("Total Sales")
g3

# Log transform to lessen the impact of extremes and give transparency to the middle
# the outliers aren't going to drive your business and models built on them shouldn't be relied on
g4 <- ggplot(df2_summ,aes(x=percent_discount,y=log(price))) + geom_point(shape=1)
g4 <- g4 + xlab("Percentage Discount") + ylab("log(Total Sales)")
g4
g4 <- g4 + geom_smooth(method=lm) 
g4

# notice the decreasing marginal return beyond 20%
g5 <- ggplot(df2_summ,aes(x=percent_discount,y=log(price))) + geom_point(shape=1)
g5 <- g5 + geom_smooth() 
g5 <- g5 + xlab("Percentage Discount") + ylab("log(Total Sales)")
g5

