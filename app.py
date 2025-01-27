from flask import Flask, request, render_template, redirect, url_for
from joblib import load
import pandas as pd

app = Flask(__name__)

# Load regression model
model = load('xgb_model.joblib')

# Updated variable list for prediction
FEATURES = [
    'Year Built', 'Bedroom AbvGr', 'Kitchen AbvGr', 'TotalSQFT', 'TotalBaths',
    'TotRms AbvGrd', 'Fireplaces', 'Garage Yr Blt', 'Garage Cars', 'Screen Porch',
    'Year Remod/Add', 'Mas Vnr Area', 'Lot Area', 'Overall Qual'
]

@app.route('/')  # Home page
def index():
    return render_template('index.html')

@app.route('/gitHub')
def gitHub():
    return redirect('https://github.com/vphalra')

@app.route('/ePortfolio')
def ePortfolio():
    return render_template('ePortfolio.html')

@app.route('/realEstatePriceModel')
def amesEstimator():
    return render_template('realEstatePriceModel.html')

@app.route('/aboutMe')
def aboutMe():
    return render_template('aboutMe.html')

@app.route('/predict')  # Estimator form page
def predictFunction():
    # Render the prediction form with an optional message
    prediction = request.args.get('prediction', None)
    return render_template('priceEstimator.html', prediction=prediction)

@app.route('/predicted-price')  # Result page
def predictedPrice():
    prediction = request.args.get('prediction', None)
    return render_template('predicted-price.html', prediction=prediction)

@app.route('/api/prediction', methods=['POST'])
def predict():
    try:
        # Collect data from form submission
        data = {feature: float(request.form[feature]) for feature in FEATURES}

        # Prepare the input data for prediction
        input_data = pd.DataFrame([data])
        input_data = input_data.reindex(columns=FEATURES, fill_value=0)

        # Make prediction
        prediction = model.predict(input_data)[0]

        # Redirect to the result page with the prediction
        return redirect(url_for('predictedPrice', prediction=f"${prediction:,.2f}"))

    except Exception as e:
        # Redirect back to the form page with an error message
        return redirect(url_for('predictFunction', prediction=f"Error: {str(e)}"))

if __name__ == '__main__':
    app.run(debug=True)
