###
### The output of this script matches (to 4-6 decimal places) the output
### of the following Stata command:
###
###     xtreg sales price pop16 cpi ndi, vce(cluster state)
###

library(plm)

# load data
data(Cigar)

# define panel structure
cig <- pdata.frame(Cigar, index = c('state', 'year'))

# fit regression model to panel data
model <- plm(sales ~ price + pop16 + cpi + ndi, data = cig, model = 'random')

# adjust the variance-covariance matrix
vcov_adj <- vcovHC(model, type = 'sss', cluster = 'group')

# perform inference with the adjusted vcov matrix
summary(model, vcov = vcov_adj)
