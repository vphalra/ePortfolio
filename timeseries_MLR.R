library(readr)
library(dplyr)
library(ggplot2)
library(forecast)
library(lubridate)

# data prep
data <- read_csv('NYC_TRANSACTION_DATA.csv')

# filtering data for residential property sales in Gravesend from 2009
data$SALE_DATE <- as.Date(data$SALE_DATE, format = '%Y-%m-%d')
data$sale_year <- format(data$SALE_DATE, '%Y')

gravesend_residential_sales <- data %>%
  filter(NEIGHBORHOOD_ID == 110, RESIDENTIAL_UNITS > 0, 
         as.numeric(sale_year) >= 2009)

# aggregating data by quarter
quarterly_sales <- gravesend_residential_sales %>%
  mutate(quarter = floor_date(SALE_DATE, 'quarter')) %>%
  group_by(quarter) %>%
  summarise(total_sales = sum(SALE_PRICE, na.rm = TRUE))

print(quarterly_sales)

# plot quarterly sales
ggplot(quarterly_sales, aes(x = quarter, y = total_sales)) +
  geom_line() +
  labs(title = 'quarterly residential sales in Gravesend from 2009',
       x = 'quarter',
       y = 'total sales ($)') +
  theme_minimal()

# converting data to a time series object
ts_sales <- ts(quarterly_sales$total_sales, start = c(2009, 1), frequency =  4)
fit <- auto.arima(ts_sales)
summary(fit)

# forecasting 
forecast_sales <- forecast(fit, h = 8)
print(forecast_sales)

autoplot(forecast_sales) +
  labs(title = '8 quarter forecast of residential sales in Gravesend',
       x = 'quarters',
       y = 'total sales ($)') +
  theme_minimal()

# multiple regression
regression_quarterly_sales <- gravesend_residential_sales %>%
  mutate(quarter = floor_date(SALE_DATE, 'quarter')) %>%
  group_by(quarter) %>%
  summarise(total_sales = sum(SALE_PRICE, na.rm = TRUE)) %>%
  ungroup() %>%
  mutate(
    time = 1:n(), # create a time variable (quarter index)
    quarter_factor = as.factor(quarter(quarter)) # create a factor for seasonality
  )

print(head(regression_quarterly_sales))

# fitting a multiple regression model including time and seasonality
fit_regression <- lm(total_sales ~ time + quarter_factor,
                     data = regression_quarterly_sales)
summary(fit_regression)

# creating future time points for the next 8 quarters
future_quarters <- data.frame(
  time = (nrow(regression_quarterly_sales) + 1):(nrow(regression_quarterly_sales) + 8),
  quarter_factor = as.factor(rep(1:4, length.out = 8))
)

print(future_quarters)

future_forecast <- predict(fit_regression, newdata = future_quarters)

forecasted_sales <- data.frame(
  quarter = seq(max(regression_quarterly_sales$quarter) + months(3), 
                by = '3 months', length.out = 8),
  forecasted_sales = future_forecast
)

print(forecasted_sales)

# multiple regression model
regression_data <- data %>%
  filter(NEIGHBORHOOD_ID == 110, RESIDENTIAL_UNITS > 0) %>%
  select(SALE_PRICE, sale_year, YEAR_BUILT, BUILDING_CLASS_FINAL_ROLL,
         GROSS_SQUARE_FEET, RESIDENTIAL_UNITS) %>%
  mutate(
    sale_year = as.numeric(sale_year),
    BUILDING_CLASS_FINAL_ROLL = as.factor(BUILDING_CLASS_FINAL_ROLL) #convert building type to a factor (categorical variable)
    
  )
print(head(regression_data))

fit_sale_price <- lm(SALE_PRICE ~ sale_year + YEAR_BUILT + 
                       BUILDING_CLASS_FINAL_ROLL + RESIDENTIAL_UNITS,
                     data = regression_data)
summary(fit_sale_price)

# Bargain and overpriced property
residuals <- residuals(fit_sale_price)

min_residual_index <- which.min(residuals)
max_residual_index <- which.max(residuals)

bargain_property <- regression_data[min_residual_index, ]
overpriced_property <- regression_data[max_residual_index, ]

print(as.data.frame(bargain_property))
print(as.data.frame(overpriced_property))

# check for multi colinearity
numeric_data <- regression_data %>%
  select(SALE_PRICE, sale_year, YEAR_BUILT, GROSS_SQUARE_FEET, RESIDENTIAL_UNITS)

# Compute the correlation matrix
correlation_matrix <- cor(numeric_data, use = "complete.obs")

# Print the correlation matrix
print(correlation_matrix)

