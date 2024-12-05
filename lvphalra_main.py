"""
This script provides a menu-driven interface for interacting with the TradeLog class.
"""

from TradeLog import TradeLog


def interactive_edit_trade(trade_index, log):
    """
    Allows the user to interactively edit specific fields of a trade.
    """
    try:
        # Fetch the trade using its index
        trades_with_index = log.get_trades_with_index()
        trade = trades_with_index[trade_index]
    except IndexError:
        print("Invalid trade index.")
        return

    field_order = [
        "asset", "narrative", "model", "position", "day_of_week",
        "time_of_day", "duration_of_trade", "R_yield", "pnl"
    ]

    while True:
        print("\nEditing Trade:")
        for field in field_order:
            print(f"{field}: {trade[field]}")

        print("\nWhich field do you want to edit?")
        for i, field in enumerate(field_order, start=1):
            print(f"{i}. {field}")
        print(f"{len(field_order) + 1}. I'm done editing")

        choice = input("Enter your choice: ")

        try:
            choice = int(choice)
            if 1 <= choice <= len(field_order):  # Edit a specific field
                field_to_edit = field_order[choice - 1]
                current_value = trade[field_to_edit]
                new_value = input(
                    f"Enter new value for {field_to_edit} (current: {current_value}): "
                )

                # Convert numeric fields if needed
                if field_to_edit in ["duration_of_trade", "R_yield", "pnl"]:
                    if new_value != "TBD":  # Ensure "TBD" remains as a string
                        new_value = float(new_value)

                trade[field_to_edit] = new_value
                # Save the change immediately to self.__trades
                log.edit_trade(trade_index, trade)
                print(f"{field_to_edit} updated successfully.")

            elif choice == len(field_order) + 1:  # Done editing
                print("Done editing.")
                break
            else:
                print("Invalid choice. Please try again.")
        except ValueError:  # Handle invalid menu input
            print("Invalid input. Please enter a number corresponding to a menu option.")



if __name__ == "__main__":
    """
    This main script allows the user to interact with the TradeLog class
    via a console menu. Users can add, edit, save, load trades, and review
    them by index.
    """
    source = input("Enter a filename to load trades from (leave blank for empty log): ")
    source = source.strip() if source else None

    # Attempt to initialize the log
    log = None
    if source:
        try:
            log = TradeLog(source)
        except FileNotFoundError:
            print(f"Error: File '{source}' not found. Starting with an empty log.")
            log = TradeLog()
    else:
        log = TradeLog()

    while True:
        print("\nMenu:")
        if log.trade_count == 0:  # Use the public `trade_count` attribute
            print("1. Add Trade")
            print("2. Load CSV File")
            print("3. Exit")
        else:
            print("1. Add Trade")
            print("2. View Trade Summary")
            print("3. Save Trades to CSV")
            print("4. Edit Trade")
            print("5. Exit")

        choice = input("Enter your choice: ")

        if log.trade_count == 0:  # When the trade log is empty
            if choice == "1":
                # Add a new trade
                trade = {
                    "asset": input("Asset: "),
                    "narrative": input("Narrative: "),
                    "model": input("Model: "),
                    "position": input("Position (long/short): "),
                    "day_of_week": input("Day of Week: "),
                    "time_of_day": input("Time of Day (HH:MM): "),
                    "duration_of_trade": "TBD",
                    "R_yield": "TBD",
                    "pnl": "TBD"
                }
                try:
                    log.add_trade(trade)
                    print("Trade added successfully.")
                except ValueError as e:
                    print(f"Error: {e}")
            elif choice == "2":
                # Load trades from CSV
                filename = input("Enter filename to load trades (e.g., trades.csv): ")
                try:
                    log.load_from_csv(filename)
                    print(f"Trades loaded from {filename}.")
                except FileNotFoundError:
                    print(f"Error: File '{filename}' not found.")
            elif choice == "3":
                print("Exiting...")
                break
            else:
                print("Invalid choice. Please try again.")
        else:  # When the trade log has data
            if choice == "1":
                # Add a new trade
                trade = {
                    "asset": input("Asset: "),
                    "narrative": input("Narrative: "),
                    "model": input("Model: "),
                    "position": input("Position (long/short): "),
                    "day_of_week": input("Day of Week: "),
                    "time_of_day": input("Time of Day (HH:MM): "),
                    "duration_of_trade": "TBD",
                    "R_yield": "TBD",
                    "pnl": "TBD"
                }
                try:
                    log.add_trade(trade)
                    print("Trade added successfully.")
                except ValueError as e:
                    print(f"Error: {e}")
            elif choice == "2":
                # View trade summary
                trades_with_index = log.get_trades_with_index()
                print("\nTrade Summary:")
                for trade in trades_with_index:
                    print(trade)
            elif choice == "3":
                # Save trades to CSV
                filename = input("Enter filename to save trades (e.g., trades.csv): ")
                success = log.save_to_csv(filename)
                if success:
                    print(f"Trades saved to {filename}.")
                else:
                    print(f"Error: Could not save trades to {filename}.")
            elif choice == "4":
                # Edit a trade
                trades_with_index = log.get_trades_with_index()
                print("\nAvailable Trades:")
                for trade in trades_with_index:
                    print(trade)

                try:
                    trade_index = int(input("Enter the index of the trade to edit: "))
                    interactive_edit_trade(trade_index, log)
                except ValueError:
                    print("Invalid index. Please try again.")
            elif choice == "5":
                print("Exiting...")
                break
            else:
                print("Invalid choice. Please try again.")
