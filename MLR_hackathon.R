# Load necessary libraries
library(AmesHousing)
library(ggplot2)
library(dplyr)
library(corrplot)
library(viridis)
library(cluster)
library(factoextra)
library(pheatmap)
library(reshape2)
library(car)
library(caret)
library(randomForest)
library(xgboost)

# Load and explore the Ames Housing dataset
data <- AmesHousing::make_ames()
str(data)
summary(data)

# Visualizations
# Histogram of Sale Price
ggplot(data, aes(x = Sale_Price)) +
  geom_histogram(binwidth = 15000, fill = 'skyblue', color = 'black') +
  labs(title = "Distribution of Ames' Real Estate Price (2006 - 2010)",
       x = 'Sale Price', y = 'Frequency')

# Boxplot of Sale Price by Neighborhood
ggplot(data, aes(x = Neighborhood, y = Sale_Price)) + 
  geom_boxplot() +
  labs(title = 'Sale Price by Neighborhood', x = 'Neighborhood', y = 'Sale Price') +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Average Sale Price by Neighborhood
data %>%
  group_by(Neighborhood) %>%
  summarise(Average_Sale_Price = mean(Sale_Price, na.rm = TRUE)) %>%
  ggplot(aes(x = reorder(Neighborhood, -Average_Sale_Price), y = Average_Sale_Price)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Average Sale Price by Neighborhood", x = "Neighborhood", y = "Average Sale Price") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# Prepare data for clustering
clustering_variables <- data %>%
  select(Gr_Liv_Area, House_Style, Overall_Qual, Year_Built, Sale_Price,
         Neighborhood, Lot_Area, Full_Bath, Garage_Area, MS_Zoning) %>%
  mutate_if(is.factor, as.numeric) %>%
  mutate_if(is.character, as.numeric)

# Standardize the clustering variables
scaled_data <- scale(clustering_variables)

# Elbow plot to determine the optimal number of clusters
set.seed(420)
fviz_nbclust(scaled_data, kmeans, method = "wss") +
  labs(title = "Elbow Method for Optimal Number of Clusters")

# K-Means clustering with 3 clusters
kmeans_model <- kmeans(scaled_data, centers = 3, nstart = 25)
clustering_variables$cluster <- kmeans_model$cluster

# PCA Visualization
pca <- prcomp(scaled_data, center = TRUE, scale. = TRUE)
fviz_pca_ind(pca, geom.ind = "point", col.ind = as.factor(clustering_variables$cluster),
             palette = "viridis", addEllipses = TRUE, ellipse.type = "norm",
             legend.title = "Cluster", title = "PCA Chart of K-Means Clustering")

pca_loadings <- as.data.frame(pca$rotation)
print("PCA Loadings:")
print(pca_loadings)


# Scatter plot of Ground Living Area vs Sale Price colored by cluster
ggplot(clustering_variables, aes(x = Gr_Liv_Area, y = Sale_Price, color = factor(cluster))) +
  geom_point(alpha = 0.7) +
  labs(title = "Clustering Based on Ground Living Area and Sale Price",
       x = "Ground Living Area (sq ft)", y = "Sale Price", color = "Cluster") +
  scale_color_viridis_d()

# Boxplot of Sale Price by Cluster
ggplot(clustering_variables, aes(x = factor(cluster), y = Sale_Price)) +
  geom_boxplot(fill = "skyblue", color = "black") +
  labs(title = "Sale Price Distribution by Cluster", x = "Cluster", y = "Sale Price")

# Summary statistics for clusters
cluster_summary <- clustering_variables %>%
  group_by(cluster) %>%
  summarise(
    Avg_Sale_Price = mean(Sale_Price, na.rm = TRUE),
    Avg_Gr_Liv_Area = mean(Gr_Liv_Area, na.rm = TRUE),
    Avg_Lot_Area = mean(Lot_Area, na.rm = TRUE)
  )
print(cluster_summary)

# Regression Models
# Split data into training and testing sets
set.seed(123)
train_index <- createDataPartition(clustering_variables$Sale_Price, p = 0.8, list = FALSE)
train_data <- clustering_variables[train_index, ]
test_data <- clustering_variables[-train_index, ]

# Initialize model comparison DataFrame
model_comparison <- data.frame(
  Model = character(),
  MAE = numeric(),
  RMSE = numeric(),
  R2 = numeric(),
  Adjusted_R2 = numeric(),
  stringsAsFactors = FALSE
)

# Model 1: With all variables including Full_Bath and Neighborhood
model_full <- lm(Sale_Price ~ Gr_Liv_Area + House_Style + Overall_Qual + Year_Built +
                   Lot_Area + Full_Bath + Garage_Area + MS_Zoning + Neighborhood + factor(cluster),
                 data = train_data)

# Model Evaluation
predictions_full <- predict(model_full, newdata = test_data)
mae_full <- mean(abs(predictions_full - test_data$Sale_Price))
rmse_full <- sqrt(mean((predictions_full - test_data$Sale_Price)^2))
r2_full <- summary(model_full)$r.squared
adjusted_r2_full <- summary(model_full)$adj.r.squared

# Append Full Model results to DataFrame
model_comparison <- rbind(model_comparison, data.frame(
  Model = "Full Model",
  MAE = round(mae_full, 2),
  RMSE = round(rmse_full, 2),
  R2 = round(r2_full, 4),
  Adjusted_R2 = round(adjusted_r2_full, 4)
))

# Model 2: Without Full_Bath and Neighborhood, setting cluster 2 as the reference level
train_data$cluster <- relevel(factor(train_data$cluster), ref = "2")
test_data$cluster <- relevel(factor(test_data$cluster), ref = "2")

model_reduced <- lm(Sale_Price ~ Gr_Liv_Area + House_Style + Overall_Qual +
                      Year_Built + Lot_Area + Garage_Area + MS_Zoning + factor(cluster),
                    data = train_data)

# Model Evaluation
predictions_reduced <- predict(model_reduced, newdata = test_data)
mae_reduced <- mean(abs(predictions_reduced - test_data$Sale_Price))
rmse_reduced <- sqrt(mean((predictions_reduced - test_data$Sale_Price)^2))
r2_reduced <- summary(model_reduced)$r.squared
adjusted_r2_reduced <- summary(model_reduced)$adj.r.squared

# Append Reduced Model results to DataFrame
model_comparison <- rbind(model_comparison, data.frame(
  Model = "Reduced Model",
  MAE = round(mae_reduced, 2),
  RMSE = round(rmse_reduced, 2),
  R2 = round(r2_reduced, 4),
  Adjusted_R2 = round(adjusted_r2_reduced, 4)
))

# Model 3: Random Forest Model
rf_model <- randomForest(Sale_Price ~ ., data = train_data, ntree = 100)
rf_predictions <- predict(rf_model, newdata = test_data)
rf_mae <- mean(abs(rf_predictions - test_data$Sale_Price))
rf_rmse <- sqrt(mean((rf_predictions - test_data$Sale_Price)^2))

print(rf_model)
# Calculate pseudo R² for Random Forest using correlation
rf_r2 <- cor(rf_predictions, test_data$Sale_Price)^2
rf_adjusted_r2 <- 1 - ((1 - rf_r2) * (nrow(test_data) - 1) / (nrow(test_data) - length(rf_model$predictors) - 1))

# Append Random Forest Model results to DataFrame
model_comparison <- rbind(model_comparison, data.frame(
  Model = "Random Forest Model",
  MAE = round(rf_mae, 2),
  RMSE = round(rf_rmse, 2),
  R2 = round(rf_r2, 4),
  Adjusted_R2 = round(rf_adjusted_r2, 4)
))

# Display the comparison DataFrame
print(model_comparison)

# Variable importance plot for Random Forest
varImpPlot(rf_model, main = "Variable Importance in Random Forest Model")

# Define Zillow property details, ensuring exact type matching with train_data
new_data <- data.frame(
  Gr_Liv_Area = as.integer(1154), #sqft
  House_Style = as.numeric(3), # one story
  Overall_Qual = as.numeric(10), # subjective
  Year_Built = as.integer(1953),
  Sale_Price = as.integer(NA),  
  Neighborhood = as.numeric(1), # north ames
  Lot_Area = as.integer(11761), #sqft
  Full_Bath = as.integer(1),
  Garage_Area = as.numeric(480), # imputed value (median)
  MS_Zoning = as.numeric(1),  # residential low density
  cluster = factor(3, levels = levels(train_data$cluster)) # determined through scatter plot 
)

# Predict using Random Forest model
zillow_prediction <- predict(rf_model, newdata = new_data)
print(paste("Predicted Sale Price for 1907 Clark Ave: $", round(zillow_prediction, 2)))


# Map Neighborhood encoding
neighborhood_mapping <- data %>%
  select(Neighborhood) %>%
  distinct() %>%
  mutate(Numeric_Encoding = as.numeric(factor(Neighborhood)))

# Display the neighborhood encoding
print(neighborhood_mapping)
# Create a mapping table for Neighborhood encoding
neighborhood_mapping <- data %>%
  select(Neighborhood) %>%
  distinct() %>%
  mutate(Numeric_Encoding = as.numeric(factor(Neighborhood)))

ggplot(clustering_variables, aes(x = Gr_Liv_Area, y = Sale_Price, color = factor(cluster))) +
  geom_point(alpha = 0.7) +
  geom_point(aes(x = 1154, y = 285000), color = "red", size = 3) +  # Adding Zillow property
  labs(title = "Clustering Based on Ground Living Area and Sale Price",
       x = "Ground Living Area (sq ft)", y = "Sale Price", color = "Cluster") +
  scale_color_viridis_d()


