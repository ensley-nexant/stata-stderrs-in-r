# Reproducing Stata Results in R
A guide for how to recreate Stata's clustered standard errors in R

## Background
Stata offers [several methods](https://www.stata.com/manuals13/xtvce_options.pdf) for correcting standard errors to address various kinds of model mis-specification. These corrections include, among others, *robust* standard errors (for error terms that are not identically distributed) and *cluster-robust* standard errors (for observations that are not independent). Many strategies have been developed over the years to deal with these scenarios, and many have been implemented in various R packages. When using R, it isn't easy to tell which precisely replicates the Stata results.

This document will show how to take a particular standard-error-adjusting Stata command and obtain the same (more or less) results in R. 

## Data
For the purposes of the example, we use a set of panel data on cigarette sales in 46 US states from 1963 to 1992, [available as a supplement to *Econometric Analysis of Panel Data* (Baltagi 2013)](http://bcs.wiley.com/he-bcs/Books?action=resource&bcsId=4338&itemId=1118672321&resourceId=13452). This dataset is built into the `plm` package in R. It is a balanced set of panel data with all 30 years of observations present for all 46 states, for a total of 1,380 observations.

## Model
Suppose we want to regress `sales` on 

## Panel Regression in Stata
Stata deals with panel data with its `xt` series of commands. 
