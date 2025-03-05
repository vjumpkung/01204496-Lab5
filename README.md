# 01204496 ปฏิบัติการที่ 5 การเขียน smart contract

จัดทำโดย : 6410504047 ชาญฤทธิ์ พิศิษฐ์จริง

## ภาพรวมของ Repo ทั้งหมด

- `RPS.sol` คือ smart contract ที่ไว้ใช้เล่นเกมพนันเป่ายิ้งฉุบด้วย
- `TimeUnit.sol` คือ smart contract ที่ไว้ในการนับเวลา โดยใช้เมื่อมีผู้เล่นเข้ามาเล่น ก็จะเริ่มนับเวลาที่เริ่มฝากเงินเข้าสู่ RPS.sol smart contract
- `CommitReveal.sol` คือ smart contract ที่ไว้ใช้สำหรับ การทำ Commit Reveal Hash เพื่อใช้ในการซ่อนคำตอบเพื่อในการป้องกัน front-running
- `Convert.sol` คือ smart contract ที่ใช้แปลง bytes32 string จาก choice_hiding_v2.py ที่ใช้ในการ hash ช้อยเบื้องต้น
- `choice_hiding_v2.py` คือ python script ที่ใช้ในการสร้างช้อย

## สถานการณ์การเล่น Smart Contract RPS

### สถานการณ์ที่ 1 เล่นได้ปกติ 

1. ผู้เล่นที่ 1 กด addPlayer
2. ผู้เล่นที่ 2 กด addPlayer
3. ผู้เล่นที่ 1 ส่ง commit hash ผ่าน input
4. ผู้เล่นที่ 2 ส่ง commit hash ผ่าน input
5. ผู้เล่นที่ 1 ส่ง reveal hash ผ่าน revealChoice
6. ผู้เล่นที่ 2 ส่ง reveal hash ผ่าน revealChoice
7. เกมจะตัดสินว่า แพ้ ชนะ หรือ เสมอ

### สถานการณ์ที่ 2 ผู้เล่นไม่ครบ 

1. ผู้เล่นที่ 1 กด addPlayer

5 วินาทีต่อมา
   
2. ผู้เล่นที่ 1 ต้องการถอนเงิน โดยการกด withdrawMoney

### สถานการณ์ที่ 3 ผู้เล่นอีก 1 คนไม่ใส่ Commit Hash 

1. ผู้เล่นที่ 1 กด addPlayer
2. ผู้เล่นที่ 2 กด addPlayer
3. ผู้เล่นที่ 1 ส่ง commit hash ผ่าน input

5 วินาทีต่อมา

4. ผู้เล่นที่ 1 ต้องการถอนเงิน โดยการกด withdrawMoney ซึ่งสามารถถอนได้ 
5. ผู้เล่นที่ 2 (ที่ยังไม่ได้ใส่ commit hash) สามารถถอนเงินได้เช่นกัน แต่ผู้เล่นใหม่จะไม่สามารถเข้ามาเล่นได้จนกว่าผู้เล่นที่ยังไม่ได้ถอนเงินกด withdrawMoney

### สถานการณ์ที่ 4 ผู้เล่นอีก 1 คนไม่ใส่ Reveal Hash 

1. ผู้เล่นที่ 1 กด addPlayer
2. ผู้เล่นที่ 2 กด addPlayer
3. ผู้เล่นที่ 1 ส่ง commit hash ผ่าน input
4. ผู้เล่นที่ 2 ส่ง commit hash ผ่าน input
5. ผู้เล่นที่ 1 ส่ง reveal hash ผ่าน revealChoice

แต่ผู้เล่นที่ 2 ไม่ส่ง reveal hash + 5 วินาทีต่อมา

6. ผู้เล่นที่ 1 ต้องการถอนเงิน โดยการกด withdrawMoney ซึ่งสามารถถอนได้ เพราะว่าผู้เล่นที่ 1 ได้ reveal hash เกิน 5 วินาทีแล้ว
7. ผู้เล่นที่ 2 (ที่ยังไม่ได้ใส่ reveal hash) สามารถถอนเงินได้เช่นกัน แต่ผู้เล่นใหม่จะไม่สามารถเข้ามาเล่นได้จนกว่าผู้เล่นที่ยังไม่ได้ถอนเงินกด withdrawMoney

## โค้ดที่ป้องกันการ lock เงินไว้ใน contract

- เมื่อมีการ add player เข้ามาแล้ว `timeUnit.setStartTime(msg.sender);` จะส่งจับเวลาว่า address นี้ฝากเงินเข้ามาแล้วกี่วินาที โดยผู้ใช้จะถอนเงินได้สามารถทำได้ผ่าน `withdrawMoney()` เมื่อเวลาผ่านไปแล้ว 5 วินาที (จุดนี้ hardcode เวลาไว้)

## โค้ดส่วนที่ทำการซ่อน choice และ commit

- การซ่อน choice สามารถทำได้ดังนี้

1. ให้ผู้ใช้เลือกว่าจะเอาเลขไหนในการสร้าง bytes32 hash ก่อนโดยใช้  string concat กับ randombytes ของ python ในการสร้าง choice ที่จะเอาไว้ใช้ในการ revealHash ทีหลัง

ตัวอย่าง python script จากไฟล์ `choice_hiding_v2.py`
```py
import random
import sys
# generate 31 random bytes
rand_num = random.getrandbits(256 - 8)
rand_bytes = hex(rand_num)

# 01 - Rock, 02 - Paper , 03 - Scissors , 04 = Lizard , 05 = Spock
# concatenate choice to rand_bytes to make 32 bytes data_input
while True:
    choice = input()

    if choice in ['01','02','03','04','05']:
        break

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
```

exmple output

```
05
0x4255a7b65c3740f1f30f8adfcd59995b8c0bdd07def8077935a1e270506ed805
66

Need no padding.
Choice is 05
Use the following bytes32 as an input to the getHash function: 0x4255a7b65c3740f1f30f8adfcd59995b8c0bdd07def8077935a1e270506ed805
66
```

2. ให้รันคำสั่ง getHash ใน smart contract Convert.sol โดยให้ input เป็น choice ที่ hash มาแล้ว จะได้ commit hash ออกมา

![image](https://github.com/user-attachments/assets/6ed19159-c3c0-409b-9558-50c7b307469e)

```
reveal hash - 0x4255a7b65c3740f1f30f8adfcd59995b8c0bdd07def8077935a1e270506ed805
commit hash - 0xb6a578c305cf2ed3566259d58ee9fb3b08d42535f30928c4115da57cbc35e690
```

3. ให้นำ commit hash ไปใส่ที่ input ซึ่งอยู่ที่ smart contract RPS.sol
4. การที่ผู้เล่นจะ reveal choice ได้ก็ต่อเมื่อผู้เล่น 2 คนได้ input commit hash แล้วทั้งคู่
5. เมื่อมีคนในคนหนึ่ง reveal choice แล้ว ผู้เล่นอีกคนไม่สามารถแก้ commit hash ได้เนื่องจากได้ถูกบันทึกแล้วว่า ได้ทำการเล่นแล้ว

## โค้ดส่วนที่จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนเสียที

ใน function withdrawMoney

Timer จะเริ่มเมื่อ addPlayer ตั้งไว้ที่ 5

- Timer จะถูกตั้งไว้ 5 วินาทีถ้าเลยจะให้ถอนเงินได้ โดย Timer จะ reset ก็ต่อเมื่อ
1. ผู้เล่นใส่ Commit hash ผ่าน input 
2. ผู้เล่นใส่ Reveal hash ผ่าน revealChoice

```solidity
function withdrawMoney() public {
    /*
        This function is allow player to withdraw money from smart contract when elapsed time more than 30 seconds by 2 cases
        1. no 2nd player
        2. both player is not input their commit hash
    */

    require(address_list[msg.sender]);
    require(msg.sender == playersAddress[player[msg.sender].idx]);
    require(timeUnit.elapsedSeconds(msg.sender) > 5 seconds);
    require(revealCount < 2 || numInput < 2); // 1 player in not reveal or not input commit hash yet
    address payable to = payable(msg.sender);
    to.transfer(1 ether);
    reward--;
    numPlayer--;
    current_idx = (current_idx + 1) % 2;
    if (numInput > 0 && !player[msg.sender].player_not_played) {
        numInput--;
    }
    if (revealCount > 0 && !player[msg.sender].player_not_revealed) {
        revealCount--;
    }
    delete playersAddress[player[msg.sender].idx];
    delete player[msg.sender];
    emit gameState(
        numInput,
        revealCount,
        numPlayer,
        current_idx,
        playersAddress
    );
}
```

พบว่าถ้าผู้เล่นเข้ามาแล้วถึงแม้ว่าจะครบแต่ว่าไม่มีการส่ง input สักทีผู้เล่นสามารถถอนตัวได้ ซึ่ง function นี้ครอบคลุมไปถึงเมื่อผู้เล่นไม่ครบก็สามารถถอนเงินออกมาได้

## โค้ดส่วนทำการ reveal และนำ choice มาตัดสินผู้ชนะ 

ใน struct Player มีองค์ประกอบดังนี้

```solidity
struct Player {
    uint8 idx;
    bytes32 player_choice; // 01 - Rock, 02 - Paper , 03 - Scissors , 04 = Lizard , 05 = Spock
    bytes32 player_reveal_hash;
    bool player_not_played;
    bool player_not_revealed;
}
```

- เมื่อผู้เล่นได้ส่ง reveal hash แล้ว จะถูกเก็บไว้ใน `bytes32 player_reveal_hash;`

เมื่อได้ reveal hash ทั้ง 2 คนแล้วจะทำการตัดสินดังนี้

1. ดึง reveal hash แต่ละคนออกมา
```solidity
bytes32 p0Choice = player[playersAddress[0]].player_reveal_hash;
bytes32 p1Choice = player[playersAddress[1]].player_reveal_hash;
```

2. แปลง bytes32 -> uint256 และ bitwise and กับ `0xFF` แล้วค่อย -1 ออกเพื่อให้ง่ายต่อการตัดสินผลลัพธ์
```solidity
uint256 finalPlayer0Choice = (uint256(p0Choice) & 0xFF) - 1;
uint256 finalPlayer1Choice = (uint256(p1Choice) & 0xFF) - 1;
```

3. เนื่องจากให้ input เรียงตามนี้
   
```
0 - Rock, 1 - Paper , 2 - Scissors , 3 = Lizard , 4 = Spock
```
ต้องเรียงใหม่ให้ตรงกับกติกาดังนี้

```
Scissors cuts Paper
Paper covers Rock
Rock crushes Lizard
Lizard poisons Spock
Spock smashes Scissors
Scissors decapitates Lizard
Lizard eats Paper
Paper disproves Spock
Spock vaporizes Rock
Rock crushes Scissors
```

จึง map เลขใหม่ได้เป็น ผ่าน function mapChoice

```solidity
function mapChoice(uint256 choice) internal pure returns (uint8) {
    if (choice == 0) return 0; // Rock -> Rock
    if (choice == 1) return 2; // Paper -> Paper becomes position 2
    if (choice == 2) return 4; // Scissors -> Scissors becomes position 4
    if (choice == 3) return 3; // Lizard stays at position 3
    if (choice == 4) return 1; // Spock -> Spock becomes position 1
    revert("Invalid choice");
}
```

4. สามารถตัดสินผลการแพ้ชนะได้ดังนี้ โดยใช้วิธี modulo

```solidity
emit playerChoice(playersAddress[0], finalPlayer0Choice);
emit playerChoice(playersAddress[1], finalPlayer1Choice);

uint8 mappedPlayer0 = mapChoice(finalPlayer0Choice);
uint8 mappedPlayer1 = mapChoice(finalPlayer1Choice);
uint8 diff = (5 + mappedPlayer0 - mappedPlayer1) % 5;

if (diff == 0) {
    // Tie: split the reward between both accounts
    account0.transfer(reward / 2);
    account1.transfer(reward / 2);
} else if (diff == 1 || diff == 2) {
    // Player0 wins
    account0.transfer(reward);
} else {
    // diff == 3 || diff == 4
    // Player1 wins
    account1.transfer(reward);
}
```

