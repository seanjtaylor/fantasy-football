source('utils.r')
library(plyr)
Drafts <- ldply(list.files('drafts'), get.df.file)
