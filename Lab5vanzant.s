@ Christian Vanzant
@ csv0004@uah.edu
@ CS 309-01

@  as -o Lab5vanzant.o Lab5vanzant.s
@  gcc -o Lab5vanzant Lab5vanzant.o
@  ./Lab5vanzant ;echo $?
@  gdb --args ./Lab5vanzant

.equ READERROR, 0

.text
.global main


main:
   @ Creating "Variables" to keep track of all facets of the ATM

   mov r10, #50    @ Total Num of 20's
   mov r9, #50	   @ Total Remaining 10's
   mov r8, #10	   @ Number of Total Withdrawals Remaining
   mov r7, #0	   @ 20's Dispensed (Keeping Track so I don't have to subtract from r10)
   mov r6, #0	   @ 10's Dispensed (50 - r9)
   mov r5, #0	   @ Total Number of Transactions (10 - r8)

@ This is on its own to reduce lines.

Prompt:

   cmp r6, #50
   bge endOfDay    @ If we have dispensed everything, the program ends

   cmp r5, #10     @ If we've reached 10 withdrawals, branch to endOfDay
   bge endOfDay
   
@ Ask the user to enter a number.
 
   ldr r0, =introPrompt    @ Put instructions/welcome in r0
   bl printf	           @ Print instructions for user to read

@ Set up r0 with number 

   ldr r0, =numInputPattern @ Setup to read in one number.
   ldr r1, =userInput       @ load r1 with the address of where the
                            @ input value will be stored. 
   bl  scanf                @ scan the keyboard.
   cmp r0, #READERROR       @ Check for a read error.
   beq readerror            @ If there was a read error, handle it. 
   ldr r1, =userInput       @ Reload r1 because it gets wiped out. 
   ldr r1, [r1]             @ Read the contents of intInput and store in r1 so that
                            @ it can be printed. 
   
   mov r4, r1               @ Store user input in r4
   
   cmp r4, #0               @ If input is negative, print all info
   blt dataDisplay

   cmp r4, #200             @ If userInp > 200, it isn't valid. They must retry
   bgt inputTooLarge  

   bl modulo

@ Implementation of modulo function using 10, as userInput must be a multiple of 10.
   
modulo:
   
   sub r1, r1, #10   @ This is our modulus calculation. Repetitively subtract 10 

   cmp r1, #0	  @ If, after modulo calculation, userInp = 0, the number is a 
   beq divisible  @ multiple of 10, and we can continue our program with no error

   cmp r1, #0        @ If, after modulo calculation, userInp = 0, the number is not
   blt notDivisible  @ a multiple of 10, meaning we need to send an error message

   bl modulo 


@ If the userInp is not divisible by 10, they must retry the withdrawal

notDivisible:

   ldr r0, =notDivisibleOut   @ Set up r0 with the error message. Tells user to try again
   bl printf
   b Prompt


@ If userInp is divisible by 10, we check for special cases and continue
   
divisible:
   mov r1, r4        @ Move user input back into r1 before subtracting 
                     @ for printing later on 

   mov r2, r9        @ Sets 10's remaining and dispersed
   mov r3, r6	     @ In case we run out of bills in the middle of calculation

   cmp r7, #50         @ Check if we have 20's
   blt dispenseTwenty  @ Must dispense 20's first if possible

   bl dispenseTen     @ Otherwise, dispense 10's



@ Dispense twenty's until out or userInp < 10
dispenseTwenty:

   cmp r7, #50          @ Check if we have 20's left to dispense
   bge dispenseTen 

   cmp r4, #20          @ Compare userInp and 20. If less than, we must use 10s
   blt dispenseTen
  
   sub r4, r4, #20      @ Subtract 20 dollars from the userInput to make loop work
   sub r10, r10, #1     @ Subtract 1 from the number of 20's we have
   add r7, r7, #1       @ Add 1 to the number of 20's we've dispensed total

   bl dispenseTwenty    @ Loops until we need to dispense 10s or we reach 0


dispenseTen:

   cmp r4, #0			 @ If userInp has reached 0, we have a successful 
   beq successfulTransaction     @ transaction, so we branch to tell the user. This must come first
                                 @ In case userInp is a multiple of 20

   cmp r6, #50 		@ Check if we have any 10's to dispense
   bgt noBills
  
   sub r4, r4, #10      @ Subtract 10 dollars from userInput to make loop work
   sub r9, r9, #1       @ Subtract 1 from the number of 10's we have
   add r6, r6, #1       @ Add 1 to the total number of 10's we've dispensed

   bl dispenseTen


@ Keeps withdrawal registers in check, prints success message to user.
successfulTransaction:

   add r5, r5, #1       @ Add 1 to the total successful transactions we've made
   sub r8, r8, #1       @ Subtract 1 from the number of withdrawals remaining

   ldr r0, =transactionEnd  @ Print successful transaction message
   bl printf

   b Prompt     @ Branch to Prompt to restart process


@ If we have no more bills to dispense, we need to let the user know
noBills:

   mov r9, r2	@ Move number of 10's dispensed and amt of 10's left
   mov r6, r3   @ Back to original registers to restore what we lost

   ldr r0, =noBillsLeft  @ Print no bills message to let the user retry
   bl printf

   b Prompt  @ Branch back to Prompt which restarts the withdrawal process


@ If userInput is too large, let the user know
inputTooLarge:

   ldr r0, =tooLargeOutput  @ Print a message notifying the user that their input is too big
   bl printf
   
   b Prompt


@ If user input is negative, we display a list of stuff about our ATM
dataDisplay:

   ldr r0, =billInventory   @ Prints our inventory of 20's and 10's
   mov r1, r10
   mov r2, r9
   bl printf

   ldr r0, =remainingBalance  @ Uses multiplication/addition to print 
   mov r1, #20
   mul r1, r10, r1            @ how much money the ATM has left
   mov r2, #10
   mul r2, r9, r2
   add r1, r1, r2
   mov r4, r1         @ We need to store r1 in r4 before r1 is cleared
   bl printf

   ldr r0, =transactionAmt
   mov r1, r5
   bl printf

   ldr r0, =totalDistributions
   mov r2, #15
   mov r3, #100
   mul r2, r3, r2
   sub r1, r2, r4     @ This is why we stored r1 in r4
   bl printf

   b Prompt       @ Branch Back to prompt


@ When our program needs to end, data must be displayed.
endOfDay:

   ldr r0, =endOfDayOut
   bl printf
  
   ldr r0, =billInventory   @ Prints our inventory of 20's and 10's
   mov r1, r10
   mov r2, r9
   bl printf

   ldr r0, =remainingBalance  @ Uses multiplication/addition to print 
   mov r1, #20
   mul r1, r10, r1            @ how much money the ATM has left
   mov r2, #10
   mul r2, r9, r2
   add r1, r1, r2
   mov r4, r1         @ We need to store r1 in r4 before r1 is cleared
   bl printf

   ldr r0, =transactionAmt
   mov r1, r5
   bl printf

   ldr r0, =totalDistributions
   mov r2, #15
   mov r3, #100
   mul r2, r3, r2
   sub r1, r2, r4     @ This is why we stored r1 in r4
   bl printf

   b myexit       @ Branch to exit the program

readerror:

   ldr r0, =strInputPattern
   ldr r1, =inputError  		@ Put address into r1 for read
   bl scanf           			@ scan keyboard
   b Prompt

myexit:

@ Force the exit and return control to OS

   mov r7, #0x01 @ SVC call to exit
   svc 0         @ Make the system call. 
   

.data


@Data and strings

.balign 4
introPrompt: .asciz "Thank you for choosing Redundant Acronym ATM Machines!\nPlease input a dollar amount between 10 and 200 (Must be a multiple of 10): \n"

.balign 4
numInputPattern: .asciz "%d"

.balign 4
tooLargeOutput: .asciz "Requested withdrawal amount is above 200, please try again. \n \n"

.balign 4
notDivisibleOut: .asciz "Your withdrawal is not a multiple of 10 (Or was 0). Try again. \n\n"

.balign 4
transactionEnd: .asciz "Transaction successful, %d dollars have been dispensed. \n \n\n"

.balign 4
noBillsLeft: .asciz "Sorry! we don't have enough money to meet your request. Please enter a smaller amount. \n \n"

endOfDayOut: .asciz "Maximum transactions reached/no bills left. Here's some Info:\n"

@ Printed Info Data

.balign 4
transactionAmt: .asciz "Total Successful Transactions: %d \n"

.balign 4
remainingBalance: .asciz "There is a total of %d dollars left in this ATM\n"

.balign 4
totalDistributions: .asciz "%d dollars have been distributed\n "

.balign 4
billInventory: .asciz "20's Left: %d \n10's Left: %d\n"


@ Misc Data

.balign 4
userInput: .word 0

.balign 4
strInputPattern: .asciz "%[^\n]"

.balign 4
inputError: .skip 100*4
