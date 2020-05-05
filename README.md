# Reproducing Stata Results in R
A guide for how to recreate Stata's clustered standard errors in R.

See `plm_cigar.R` for a commented R script that matches Stata's output.

## Background
Stata offers [several methods](https://www.stata.com/manuals13/xtvce_options.pdf) for correcting standard errors to address various kinds of model mis-specification. These corrections include, among others, *robust* standard errors (for error terms that are not identically distributed) and *cluster-robust* standard errors (for observations that are not independent). Many strategies have been developed over the years to deal with these scenarios, and many have been implemented in various R packages. When using R, it isn't easy to tell which precisely replicates the Stata results.

This document will show how to take a particular standard-error-adjusting Stata command and obtain the same (more or less) results in R. 

## Data
For the purposes of the example, we use a set of panel data on cigarette sales in 46 US states from 1963 to 1992, [available as a supplement to *Econometric Analysis of Panel Data* (Baltagi 2013)](http://bcs.wiley.com/he-bcs/Books?action=resource&bcsId=4338&itemId=1118672321&resourceId=13452). This dataset is built into the `plm` package in R. It is a balanced set of panel data with all 30 years of observations present for all 46 states, for a total of 1,380 observations.

## Model
Suppose we want to regress cigarette sales (`sales`) in packs per capita on several state-level characteristics: price per pack (`price`), population over the age of 16 (`pop16`), consumer price index (`cpi`), and per capita disposable income (`ndi`).

## Panel Regression in Stata
Stata deals with panel data with its `xt` series of commands. First we must specify the panel index of the data with `xtset`.

```
xtset state year
```

Then the regression is run with `xtreg`. To correct the standard errors, we use the `vce` option.

```
xtreg sales price pop16 cpi ndi, vce(cluster state)
```

The output is as follows:

```
Random-effects GLS regression                   Number of obs     =      1,380
Group variable: state                           Number of groups  =         46

R-sq:                                           Obs per group:
     within  = 0.4357                                         min =         30
     between = 0.0313                                         avg =       30.0
     overall = 0.0648                                         max =         30

                                                Wald chi2(4)      =     197.13
corr(u_i, X)   = 0 (assumed)                    Prob > chi2       =     0.0000

                                 (Std. Err. adjusted for 46 clusters in state)
------------------------------------------------------------------------------
             |               Robust
       sales |      Coef.   Std. Err.      z    P>|z|     [95% Conf. Interval]
-------------+----------------------------------------------------------------
       price |  -.5325603   .1043968    -5.10   0.000    -.7371742   -.3279464
       pop16 |   .0007286   .0015399     0.47   0.636    -.0022896    .0037468
         cpi |   .9542556   .1832074     5.21   0.000     .5951757    1.313336
         ndi |  -.0045196   .0024277    -1.86   0.063    -.0092779    .0002386
       _cons |   121.8651   5.674334    21.48   0.000     110.7436    132.9866
-------------+----------------------------------------------------------------
     sigma_u |  20.917233
     sigma_e |  13.224046
         rho |  .71444536   (fraction of variance due to u_i)
------------------------------------------------------------------------------
```

## Panel Regression in R
In R, the `plm` panel regression package gives us the ability to replicate the adjustment Stata makes with `vce`. Similarly to `xtset`, we must specify the panel structure with a call to `pdata.frame`.

```
cig <- pdata.frame(Cigar, index = c('state', 'year')
```

Then we fit the regression model with the `plm` function. In Stata, the default behavior of `xtreg` is to fit a GLS random effects model. The analogous model can be fit in R by passing the argument `model = 'random'` to `plm()`.

```
model <- plm(sales ~ price + pop16 + cpi + ndi, data = cig, model = 'random')
```

Running `summary(model)` produces the following output:

```
Oneway (individual) effect Random Effect Model 
   (Swamy-Arora's transformation)

Call:
plm(formula = sales ~ price + pop16 + cpi + ndi, data = cig, 
    model = "random")

Balanced Panel: n = 46, T = 30, N = 1380

Effects:
                 var std.dev share
idiosyncratic 174.88   13.22 0.286
individual    437.53   20.92 0.714
theta: 0.8853

Residuals:
     Min.   1st Qu.    Median   3rd Qu.      Max. 
-48.97120  -6.91624  -0.59761   5.52430 123.31778 

Coefficients:
               Estimate  Std. Error  z-value Pr(>|z|)    
(Intercept)  1.2187e+02  3.5329e+00  34.4941   <2e-16 ***
price       -5.3256e-01  3.3975e-02 -15.6749   <2e-16 ***
pop16        7.2858e-04  4.8340e-04   1.5072   0.1318    
cpi          9.5426e-01  5.0563e-02  18.8728   <2e-16 ***
ndi         -4.5196e-03  4.5942e-04  -9.8377   <2e-16 ***
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Total Sum of Squares:    424520
Residual Sum of Squares: 246460
R-Squared:      0.41944
Adj. R-Squared: 0.41775
Chisq: 993.416 on 4 DF, p-value: < 2.22e-16
```

Notice that the coefficient estimates are the same in both Stata and R, but the standard errors are quite different because the R ones are currently unadjusted.

### Adjusting the R standard errors
The next step is to transform the coefficient covariance matrix from our fitted model. The `vcovHC` function does this. The trick is to specify `type = 'sss'` in this call. This performs the Stata adjustment (I think it's an abbreviation for something like "Stata small sample").

```
vcov_adj <- vcovHC(model, type = 'sss', cluster = 'group')
```

Then, pass the transformed matrix to the `summary` function.

```
summary(model, vcov = vcov_adj)
```

The output now looks like this:

```
Oneway (individual) effect Random Effect Model 
   (Swamy-Arora's transformation)

Note: Coefficient variance-covariance matrix supplied: vcov_adj

Call:
plm(formula = sales ~ price + pop16 + cpi + ndi, data = cig, 
    model = "random")

Balanced Panel: n = 46, T = 30, N = 1380

Effects:
                 var std.dev share
idiosyncratic 174.88   13.22 0.286
individual    437.53   20.92 0.714
theta: 0.8853

Residuals:
     Min.   1st Qu.    Median   3rd Qu.      Max. 
-48.97120  -6.91624  -0.59761   5.52430 123.31778 

Coefficients:
               Estimate  Std. Error z-value  Pr(>|z|)    
(Intercept)  1.2187e+02  5.6743e+00 21.4765 < 2.2e-16 ***
price       -5.3256e-01  1.0440e-01 -5.1013 3.373e-07 ***
pop16        7.2858e-04  1.5399e-03  0.4731   0.63612    
cpi          9.5426e-01  1.8321e-01  5.2086 1.903e-07 ***
ndi         -4.5196e-03  2.4277e-03 -1.8617   0.06265 .  
---
Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

Total Sum of Squares:    424520
Residual Sum of Squares: 246460
R-Squared:      0.41944
Adj. R-Squared: 0.41775
Chisq: 197.131 on 4 DF, p-value: < 2.22e-16
```

Now, the standard errors (and consequently, the test statistics and *p*-values) agree with Stata's output to several decimal places.

## Various model types in Stata and R
The random effects model shown above is just one of a few model specifications we can choose from. This table illustrates how to specify the options in Stata and R to get the output from each specification to agree. To save space, the regressions in the table only use a single dependent variable, `price`. Keep in mind that cluster-robust standard errors are not used here, but the procedures above can be followed to make that correction in all cases. Also, this is not an exhaustive list.

| Model | Stata | R |
| --- | --- | --- |
| Random effects | `xtreg sales price, re` | `plm(sales ~ price, model = 'random', data = cig)` |
| Fixed effects | `xtreg sales price, fe` | `plm(sales ~ price, model = 'within', data = cig)` |
| Between-effects | `xtreg sales price, be` | `plm(sales ~ price, model = 'between', data = cig)` |
