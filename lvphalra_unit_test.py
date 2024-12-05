"""
Langvid Phalra
CS 521 - Fall 2024
Term Project
This script contains unit tests to validate the functionality of the TradeLog class.
"""

from TradeLog import TradeLog


def test_trade_log():
    """
    Function to test the functionality of the TradeLog class.
    Includes tests for adding, editing, saving, loading, and indexing trades.
    """
    log = TradeLog()

    # Test adding a valid trade
    valid_trade = {
        "asset": "BTC",
        "narrative": "Expecting a weekly bullish candle",
        "model": "PDL turtle soup",
        "position": "long",
        "day_of_week": "Monday",
        "time_of_day": "10:00",
        "duration_of_trade": "TBD",
        "R_yield": "TBD",
        "pnl": "TBD"
    }
    log.add_trade(valid_trade)
    assert len(log._TradeLog__trades) == 1, "Trade was not added correctly."

    # Test editing a trade
    updated_trade = {
        "asset": "BTC",
        "narrative": "Expecting a strong rally",
        "model": "PDL turtle soup",
        "position": "long",
        "day_of_week": "Tuesday",
        "time_of_day": "12:00",
        "duration_of_trade": 5.0,
        "R_yield": 2.5,
        "pnl": 1000.0
    }
    log.edit_trade(0, updated_trade)
    assert log._TradeLog__trades[0]["narrative"] == "Expecting a strong rally", \
        "Trade edit failed for narrative field."
    assert log._TradeLog__trades[0]["pnl"] == 1000.0, \
        "Trade edit failed for numeric fields."

    # Test saving trades to CSV
    filename = "test_trades.csv"
    log.save_to_csv(filename)
    print(f"Trades saved to {filename} successfully.")

    # Test loading trades from CSV
    log.load_from_csv(filename)
    assert len(log._TradeLog__trades) == 1, \
        "Trades were not loaded correctly from the CSV."
    assert log._TradeLog__trades[0]["pnl"] == "1000.0", \
        "Numeric field not correctly loaded from CSV."

    # Test getting trades with index
    trades_with_index = log.get_trades_with_index()
    assert trades_with_index[0]["index"] == 0, \
        "Indexing is incorrect in get_trades_with_index."
    assert trades_with_index[0]["narrative"] == "Expecting a strong rally", \
        "Trade data mismatch in get_trades_with_index."

    print("All tests passed successfully.")


# Run the test
if __name__ == "__main__":
    test_trade_log()
