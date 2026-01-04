rm(list=ls())

##############
# Like in exercise 3 #
##############

# install.packages("haven")
# install.packages("fixest")
# install.packages("dplyr")

library(haven)
library(dplyr)
library(fixest)

df_city <- read_dta('data/replication-data-city.dta')
df_micro <- read_dta("data/replication-data-micro.dta")
(head(df_city))
head(df_micro)

head(df_city)
names(df_city)