"""
Langvid Phalra
CS 521 - Fall 2024
Term Project
This is a class to handle trade logging functionality with specified fields.
"""

class TradeLog:
    """
    This class manages trade logging, including adding, editing, saving,
    and loading trades with detailed validation. Each trade includes an
    index to reference for editing or reviewing.
    """

    def __init__(self, source=None):
        """
        Initialize the trade log with an optional source.
        If a filename (str) is provided, load trades from the file.
        """
        self.__trades = []  # Private attribute
        self.source = source  # Public attribute
        self.trade_count = 0  # Public attribute to track number of trades

        if isinstance(source, str):  # Check if a filename is provided
            try:
                self.load_from_csv(source)
                self.trade_count = len(self.__trades)  # Update trade count
                print(f"Trades loaded from {source}.")
            except FileNotFoundError:
                print(f"Error: File '{source}' not found. Starting with an empty trade log.")

    def __repr__(self):
        """Return a string representation of the TradeLog object."""
        return f"TradeLog with {len(self.__trades)} trades"

    def add_trade(self, trade):
        """
        Add a trade to the log after validation.
        Ensures all required fields are present with default values.
        """
        required_fields = [
            "asset", "narrative", "model", "position", "day_of_week",
            "time_of_day", "duration_of_trade", "R_yield", "pnl"
        ]
        for field in required_fields:
            if field not in trade:
                trade[field] = "TBD"  # Assign default value if missing

        if self.__validate_trade(trade):
            self.__trades.append(trade)
            self.trade_count += 1  # Update trade count
        else:
            raise ValueError("Invalid trade data.")

    def edit_trade(self, trade_index, updated_trade):
        """
        Edit an existing trade in the log by its index.
        """
        if 0 <= trade_index < len(self.__trades):
            if self.__validate_trade(updated_trade):
                self.__trades[trade_index] = updated_trade
                print("Trade updated successfully.")
            else:
                raise ValueError("Invalid trade data for update.")
        else:
            raise IndexError("Trade index out of range.")

    def __validate_trade(self, trade):
        """
        Validate trade data.
        Ensures required fields exist and values are of correct types.
        """
        required_fields = [
            "asset", "narrative", "model", "position", "day_of_week",
            "time_of_day", "duration_of_trade", "R_yield", "pnl"
        ]
        valid_positions = ["long", "short"]

        for field in required_fields:
            if field not in trade:
                return False

        if trade["position"] not in valid_positions:
            return False
        if trade["duration_of_trade"] != "TBD" and not isinstance(trade["duration_of_trade"], (int, float)):
            return False
        if trade["R_yield"] != "TBD" and not isinstance(trade["R_yield"], (int, float)):
            return False
        if trade["pnl"] != "TBD" and not isinstance(trade["pnl"], (int, float)):
            return False
        if not isinstance(trade["asset"], str):
            return False

        return True

    def save_to_csv(self, filename):
        """
        Save all trades to a CSV file with an index column.
        """
        required_fields = [
            "asset", "narrative", "model", "position", "day_of_week",
            "time_of_day", "duration_of_trade", "R_yield", "pnl"
        ]

        try:
            with open(filename, 'w') as file:
                file.write("index," + ",".join(required_fields) + "\n")

                for i, trade in enumerate(self.__trades):
                    row = [str(i)] + [str(trade.get(field, "TBD")) for field in required_fields]
                    file.write(",".join(map(str, row)) + "\n")  # Convert all values to strings
        except IOError as e:
            print(f"Error saving file: {e}")
            return False  # Indicate failure
        return True  # Indicate success

    def load_from_csv(self, filename):
        """
        Load trades from a CSV file into the log.
        """
        required_fields = [
            "asset", "narrative", "model", "position", "day_of_week",
            "time_of_day", "duration_of_trade", "R_yield", "pnl"
        ]

        try:
            with open(filename, 'r') as file:
                lines = file.readlines()
                self.__trades = []

                for line in lines[1:]:
                    values = line.strip().split(",")

                    trade = dict(zip(required_fields, values[1:]))

                    for field in required_fields:
                        if field not in trade or not trade[field]:
                            trade[field] = "TBD"

                    self.__trades.append(trade)
                self.trade_count = len(self.__trades)  # Update trade count after loading
        except FileNotFoundError:
            raise FileNotFoundError(f"Error: File '{filename}' not found.")  # Re-raise the error to the caller
        except IOError as e:
            print(f"Error reading file: {e}")

    def get_trades_with_index(self):
        """
        Return all trades with their index for easy reference.
        """
        return [{"index": i, **trade} for i, trade in enumerate(self.__trades)]
