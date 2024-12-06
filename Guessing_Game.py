"""
This script develops an easy number guessing game.
"""

import random
number = random.randint(0, 100) # get a random number between 0 and 100 inclusive

print('Hi-Lo Number Guessing Game: between 0 and 100 inclusive')
print()

guess_str = input('Guess a number: ')
guess = int(guess_str)

# while guess is in range, keep asking
while 0 <= guess <= 100:
    if guess > number:
        print('Guessed too high.')
    elif guess < number:
        print('Guessed too low.')
    else:
        print('You guessed it. The number was:', number)
        break
    guess_str = input('guess a number: ')
    guess = int(guess_str)
else:
    print('you quit early, the number was:', number)
