# Universal-Test-PCB

This repository contains two Verilog-based digital design modules:

1. I2C Master Controller – A Verilog implementation of the I2C communication protocol for interfacing with peripheral devices.

2. Scan Chain Signal Generator – A Verilog module to generate Clock, DIN (Data In), and Reset signals for scan chain testing in digital circuits.

**I2C Code Explaination**

🟢 **STEP 0: Initialization**
SDA = High, SCL = High
FSM state = idle
rst = 1
sda_reg = 1, sda_link = 1 ⇒ SDA is driven high
scl = 1 (as initialized)
Clock counters count1, count2, data_count all reset

🟢 **STEP 1: Button Press Detection (Trigger Start)**
On key0 falling edge (key0 goes from 1 → 0):
rst toggles (~rst)
stop_reg is cleared

In the next clock cycles:
rst = 0 → Enables FSM and clock transitions

FSM begins operation

🟢 **STEP 2: Start Condition Generation**
FSM enters idle state:
Waits until count2 reaches 4999 (software debounce/start delay)

When count2 == 4999:
FSM transitions to start state

In start state:
Waits until count1 == 124 (SCL is high mid-period)

Then:
SDA is pulled LOW (sda_reg = 0)
sda_link = 1 ⇒ driving SDA low
FSM transitions to address state

✅ Start condition generated: SDA goes low while SCL is high

🟢 **STEP 3: Sending 7-bit Address + Read Bit**
FSM enters address state:
Address format: {4'b1001, i_address[2:0], 1'b1}
Example (if i_address = 000): 10010001 ⇒ 7-bit address + R/W=1

On each count1 == 374 (stable time within SCL low/high cycle):
FSM drives 1 bit of address_reg on SDA
data_count increments from 0 → 7

When 8 bits sent (data_count == 8):
FSM releases SDA: sda_link = 0, sda_reg = 1

Transitions to addack state

✅ Full 8-bit address (7-bit + read) sent, bit by bit on SDA during valid SCL phase

🟢 **STEP 4: ACK Bit from Slave**
FSM enters addack state:
SDA is released → high-impedance (Z), ready to receive ACK from slave
Waits for count1 == 374
No actual ACK logic is implemented (ack = 0 hardcoded)

After waiting:
FSM assumes ACK received
Takes back SDA control: sda_link = 1, sda_reg = 1
Transitions to stop state

✅ ACK phase completed (slave expected to pull SDA low during ACK)

🟢 **STEP 5: Stop Condition**
FSM enters stop state:
SDA driven high (sda_reg = 1)
SCL is also kept high (from clock generator)

At this point:
SDA and SCL are high again
I2C bus is idle
stop_reg becomes 1 when count1 == 498, indicating transaction complete

✅ Stop condition generated: SDA goes high while SCL is high


**SCAIN CHAIN Code Explaination**

🔧 System Setup
data = 8'b00011100 → The shift pattern to send.

clk_out is derived from the system clock clk by dividing it by 128 (since clk_out = clk_count[6]).

FSM states:

IDLE: Wait for key press.

START: Trigger reset.

RESET: Hold reset for 10 cycles.

SHIFT: Shift out 8 bits serially.

🔹 **1. Idle State – Wait Until Key is Pressed**
System remains in IDLE state.

Output conditions:
reset = 0 → Scan chain is inactive.
din = 1 → Data line held high (idle condition).
bit_index = 0, reset_counter = 0 → Internal counters reset.

Condition to exit IDLE:
If key == 0 (i.e., button pressed) AND flag == 0, then:
Move to START state.
Set flag = 1 in next clk cycle to avoid re-triggering while the key is still held.

🔹 **2. Reset Phase – SDA = 1, Reset = 1 for Fixed Cycles**
Enters START state:
reset = 1

Transitions to RESET state.

In RESET state:
Keeps reset = 1
Waits for 10 falling edges of clk_out using reset_counter.
Keeps din = 1 throughout (SDA remains high).

Once reset_counter == 10:
Clear reset = 0
Begin sending first bit: din = data[0]

Move to SHIFT state

🔹 **3. Shift Phase – Send 8-bit Data Serially**
In SHIFT state:
reset = 0

On each falling edge of clk_out, output:
din = data[bit_index]
Increment bit_index each cycle.

Once all 8 bits (bit_index == 8) are sent:
din = 1 (idle)
bit_index = 0, reset_counter = 0

Return to IDLE state


🔹** 4. Return to Idle – Wait for Next Trigger**
System returns to IDLE state:
Ready for next button press.
Only reacts again if key goes high and then low again.
Prevents re-triggering via flag logic.
