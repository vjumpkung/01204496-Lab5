import random
# generate 31 random bytes
rand_num = random.getrandbits(256 - 8)
rand_bytes = hex(rand_num)

# 01 - Rock, 02 - Paper , 03 - Scissors , 04 = Lizard , 05 = Spock
# concatenate choice to rand_bytes to make 32 bytes data_input
choice = '01'
data_input = rand_bytes + choice
print(data_input)
print(len(data_input))
print()

# need padding if data_input has less than 66 symbols (< 32 bytes)
if len(data_input) < 66:
    print("Need padding.")
    data_input = data_input[0:2] + '0' * (66 - len(data_input)) + data_input[2:]
    assert(len(data_input) == 66)
else:
    print("Need no padding.")
print("Choice is", choice)
print("Use the following bytes32 as an input to the getHash function:", data_input)
print(len(data_input))