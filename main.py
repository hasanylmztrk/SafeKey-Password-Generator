import random
import string

length = int(input("How many characters should your password be? "))
letters = input("Include letters? (yes / no): ")
numbers = input("Include numbers? (yes / no): ")
symbols = input("Include symbols? (yes / no): ")

characters = ""
if letters == "yes":
    characters += string.ascii_letters
if numbers == "yes":
    characters += string.digits
if symbols == "yes":
    characters += string.punctuation

password = ""
for i in range(length):
    password += random.choice(characters)

print("Your new password:", password)
