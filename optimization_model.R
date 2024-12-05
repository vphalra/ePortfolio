library(readr)
library(ggplot2)
library(dplyr)
library(lubridate)

setwd('/Users/lvphalra/Desktop/BU/AD 571/NYC_RE')

# Load data
data <- read_csv('NYC_TRANSACTION_DATA.csv')

# Data Prep (get rid of erroneous sale price and sqft entries)
data <- subset(data, !is.na(GROSS_SQUARE_FEET) & !is.na(SALE_PRICE) &
                 SALE_PRICE > 0 & GROSS_SQUARE_FEET > 0)

# Sort date format and extract year
data$SALE_DATE <- as.Date(data$SALE_DATE, format = '%Y-%m-%d')
data$sale_year <- year(data$SALE_DATE)  # Use year() from lubridate

# Filter all commercial and residential properties in Gravesend
gravesend_total_sales <- data %>%
  filter(NEIGHBORHOOD_ID == 110, SALE_PRICE > 0, GROSS_SQUARE_FEET > 0)

# Create a time index (e.g., 1 for Q1, 2 for Q2, etc.)
gravesend_total_sales <- gravesend_total_sales %>%
  mutate(quarter = quarter(SALE_DATE, with_year = TRUE)) %>%
  group_by(quarter) %>%
  summarise(total_sales = sum(SALE_PRICE, na.rm = TRUE)) %>%
  mutate(time_index = 1:n())

# Fit a linear regression model with time_index as the predictor
sales_model <- lm(total_sales ~ time_index, data = gravesend_total_sales)

summary(sales_model)

# Predict sales for the next 8 quarters
future_time_index <- max(gravesend_total_sales$time_index) + 1:8
future_sales <- predict(sales_model, newdata = data.frame(time_index = future_time_index))

print(future_sales)

# Calculate average cost per square foot for 2023 from the original `data`
gc_2023 <- data %>%
  filter(NEIGHBORHOOD_ID == 110, sale_year == 2023, SALE_PRICE > 0,
         GROSS_SQUARE_FEET > 0, COMMERCIAL_UNITS > 0, RESIDENTIAL_UNITS == 0)

gc_2023$gc_sqft_cost <- gc_2023$SALE_PRICE / gc_2023$GROSS_SQUARE_FEET
gc_avg_cost_per_sqft <- mean(gc_2023$gc_sqft_cost, na.rm = TRUE)

# defining baseline values for revenue calculation
baseline_commission <- .05
baseline_market_penetration <- .055
baseline_office_size <- 250
employee_salary <- 65000 / 4

# functions to calculate revenue per quarter based on market penetration and commission
revenue_per_quarter <- function(market_penetration, commission, sales) {
  return(market_penetration * sales * commission)
}

# function to calculate rent based on office size
rent_per_quarter <- function(office_size, cost_per_sqft) {
  return(office_size * cost_per_sqft * .015 * 3) # rent per quarter
}

# initialize variables to track the best npv and configuration
best_npv <- -Inf
best_employee <- 0 
best_commission <- 0
best_office_size <- 0

# loop through different employee counts (0 to 3) and comission rates (4% to 5%)
for (employees in 0:3) {
  # calculate office size (250 sqft + 125 sqft per employee)
  office_size <- baseline_office_size + (employees * 125)
  
  # calculate rent cose for current office size
  rent_cost <- rent_per_quarter(office_size, gc_avg_cost_per_sqft)
  
  # calculate employee cost for current employee count
  employee_cost <- employee_salary * employees
  
  for (commission in seq(.04, .05, by = .001)) {
    market_penetration <- baseline_market_penetration
    + (.05 - commission) / .001 * .0015
    
    #initialize npv calculations
    npv <- 0
    interest_rate <- .015
    
    for (time in 1:8) {
      revenue <- revenue_per_quarter(market_penetration, commission, future_sales[time])
      
      total_operating_cost <- employee_cost + rent_cost
      
      if (total_operating_cost > 15000 * 3) {
        next
      }
      
      profit <- revenue - total_operating_cost
      npv <- npv + profit / ((1 + interest_rate) ^ time)
    }
    if (npv > best_npv) {
      best_npv <- npv
      best_employees <- employees
      best_commission <- commission 
      best_office_size <- office_size
    }
  }
 
}

print(paste('best npv:', best_npv))
print(paste('best number of employees:', best_employees))
print(paste('best commission rate:', best_commission))
print(paste('best office size', best_office_size, 'sqft'))


predicted_sales <- predict(sales_model, gravesend_total_sales)

# Calculate residuals (the difference between actual and predicted sales)
residuals <- gravesend_total_sales$total_sales - predicted_sales

# Calculate MSE
mse <- mean(residuals^2)
print(paste("Mean Squared Error (MSE):", mse))

# Calculate RMSE
rmse <- sqrt(mse)
print(paste("Root Mean Squared Error (RMSE):", rmse))

# Calculate MAE
mae <- mean(abs(residuals))
print(paste("Mean Absolute Error (MAE):", mae))