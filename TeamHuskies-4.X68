*--------------------------------------------------------------------
* Title      : CSS 422 68k Disassembler
* Written by : Regie Pineda, Jason Wungadi, Kellan Blake
* Date       : December 5, 2019
* Description: To Test, simply load a testing file and run. It will
*               then ask user input for start address and ending address
*               to print out addresses, instructions, and opcodes.
*------------------------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program


BEGINNING_ADDRESS           EQU    $100 * Store the inputted user starting address
FINISHING_ADDRESS           EQU    $150 * Store the inputted user ending address
DestReg                     EQU    $250 * This variable represents the address number of the destination
DestMode                    EQU    $300 * This variable represents the destination mode
SourceReg                   EQU    $400 * This variable represents the address number of the source
SourceMode                  EQU    $350 * This variable represents the source mode which are typically the [5-3]
TemporaryVar                EQU    $550 * This variable is used throughout the program as a temporary variable manipulated by various subroutines to store data. 
Opmode                      EQU    $450 * This variable represents the opmode in an instruction
A1_COPY_ONE                 EQU    $600 * This variable was specified as a copy of (A1) as to avoid overwriting the value in (A1) when obtaining the end address
A1_COPY_TWO                 EQU    $650 * This variable was specified as a copy of (A1) as to avoid overwriting the value in (A1) when obtaining the starting address
FourNibbles                 EQU    $200 * represent 4 nibbles



****
 * The GET_BEGIN_ADDR subroutine:
 * ------------------------------
 * Responsible for prompting the user for the starting address. 
 * Start the program by asking the user for the starting address
 * Accomplished largely by loading the message into A1
 * Printing out the message using the TRAP TASK #13
 ***
GET_BEGIN_ADDR
    LEA         GET_START_ADDR,A1       * This message will welcome the user to the program
    MOVE.B      #13,D0                  * Formatting with Carriage Return and Line Feed
    TRAP        #15                     * Execute the TRAP task
    MOVEA.L     #0,A1                   * Preemptively clear the values in A1 register for the starting address 
    LEA         A1_COPY_TWO,A1          * Load the A1_COPY_TWO into A1, so that override won't occur when we read a string.
    CLR         D0                      * Clear the D0 register to enable manipulation and use
    CLR         D1                      * Clear the D1 register to enable manipulation and use
    MOVE.B      #2,D0                   * Reads a string input to represent the starting address for the user. 
    TRAP        #15                     * Execute the TRAP task
    BRA         PrintHexAddress         * Convert to hex
 
 * The GET_FINISH_ADDR subroutine:
 * -------------------------------
 * Responsible for prompting ASCIIthe user for the ending address. 
 * Ask the user for the ending address that they want us to parse up to
 * Accomplished largely by loading the message into A1
 * Printing out the message using the TRAP TASK #13
GET_FINISH_ADDR
    LEA         GET_END_ADDR,A1         * Similar message prompting for the end address
    MOVE.B      #13,D0					* Formatting with Carriage Return and Line Feed 
    TRAP        #15						* Execute the TRAP task
    LEA         A1_COPY_ONE,A1          * Store the end address in the A1 address 
    MOVE.B      #2,D0					* Reads a string input to represent the starting address for the user.
    TRAP        #15						* Execute the TRAP task
    BRA         PrintHexAddress         * Convert to hex

****
 * GetNextOpcode subroutine:
 * -------------------------------
 * Responsible for going through the first 4 bits of the OpCode to
 * figure out where in the program to branch to for further processing.
 * Jumps to '_LOC ', ' D3_GET_NEXT_FOUR_NIB ',
 * and ' STORE_FIRST_NIBBLE_IN_D3 ' subroutine. 
 * These jumps in conjunction with the manipulation of D3 to get the index
 * of the first nibble will allow a proper jump to the right
 * ' FIRST_NIBBLE_IS_ ' subroutine in the jump table. 
 ***
GetNextOpcode
    JSR         CheckEnter
    JSR         OUTPUT_ADDR_LOC                  * Jumps to the Sub Routine ' OUTPUT_ADDR_LOC '
    JSR         GET_THE_ADDR_CONTENT_TO_D3            * Once returned back, jump to ' D3_GET_NEXT_FOUR_NIB '
    MOVE.W      FourNibbles,D3		                       * Reload the current four nibbles that      
												 * Copy the FourNibbles to 'D3' since that's used by most subroutines
    JSR         JumpToInstruction
    SIMHALT
    
LoadAddress
    MOVE.L      BEGINNING_ADDRESS,A2     *Place beginning address into A2 to keep track of address
    MOVE.L      FINISHING_ADDRESS,A3
    BRA         GetNextOpcode
    
   *****
 * The OUTPUT_ADDR_LOC subroutine:
 * ---------------------
 * This subroutine is responsible for outputting the 
 * current address that the disassembler is disassembling
 * 
 * Format is: 00XX YYYY as the current address location 
 ***
OUTPUT_ADDR_LOC
    MOVE.L      A2,D5 							* Store the current address that the disassembler is at	
    MOVE.L      D5,FourNibbles				
    JSR         HexToAscii			* Output the 8 bit data field
    MOVE.W      A2,D5							* Store the current address that the disassembler is at
    MOVE.W      D5,FourNibbles
    JSR         HexToAscii			* Output the 8 bit data field
    JSR         PrintSpace
    RTS

    
 * This subroutine is invoked during the first phase of the 
 * disassembler as a key component of I/O. It's used to 
 * turn the inputted start and end addresses to HEX format
 * from ASCII.
 * 
 * Converts 0-9 and A-F in ASCII to HEX Value
PrintHexAddress
    MOVE.B      (A1)+,D0					* Reads through each byte of the address
	
    CMP.B       #$30,D0                     * A comparison is made with #$30 because 
											* Valid ASCII numbers and Letters have:
											* $30 - $39 for [0-9] and $41 - $46 for [A-F]
											
    BLT         SWITCH_BAD_INPUT			* If it's less than #$30, then it can't be
											* a proper ASCII number or letter
											
    CMP.B       #$39,D0                     * A comparison is made with #$39 to see 
											* if the value is a ASCII number. 
											
    BGT         ASCII_TO_HEX_CHAR_CHANGER	* If it's greater then branch to 
											* the ASCII CHAR subroutine for further checks
											
    SUB.B       #$30,D0                     * If it's still here then it's a number
											* therefore it's a ASCII number between [0-9]
											* You subtract #$30 to convert it to HEX.
											
    ADD.L       D0,D3						* Add the value to D3 since it stores the 
											* HEX version of the address. 
											
    SUBI        #1,D1                       * By subtracting '1' from D1 this will 
											* serve to decrement the counter of the 
											* length of the examined address
											
    CMP.B       #0,D1						* Check if the counter is 0, if it is 
											* begin the process of validating the
											* address that was just converted.
											
    BEQ         VALIDATING_BEG_ADDRESS		* Appropriate branch for condition above.
	
    LSL.L       #4,D3                       * Performing a 4 bit shift to the left
										                * will leave room for the next nibble 
											* of the address. After all if we're here
											* then that means there's still some 
											* address to be read in. 
											
    BRA         PrintHexAddress     	* to convert for the address. 
									

 * This subroutine is invoked during the first phase of the 
 * disassembler as a key component of I/O. It's an extension
 * of the primary ASCII_TO_HEX_CHANGER that handles 
 * ASCII input that may possibly be a letter. 
 * 
 * Converts 0-9 and A-F in ASCII to HEX Value
ASCII_TO_HEX_CHAR_CHANGER
    CMP.B       #$41,D0                     * A comparison is made with #$41 
											
    BLT         SWITCH_BAD_INPUT            * If the value is less than #$41 then
											* it's not a letter. 
											
    CMP.B       #$46,D0						* Check to see if it's a letter 
											* greater than 'F'
											
    BGT         SWITCH_BAD_INPUT            * If it's greater than #$46, it is invalid
											
    SUB.B       #$37,D0                     * We subtract #$37 from the value to 
											* convert it from ASCII letter to 
											* the hexadecimal letter
											
    ADD.L       D0,D3                       * Now that we have it we're going 
											* to store it in register D3 which
											* in this stage of the disassembler 
											* will be used to store the 
											* converted addresses
											
    SUBI        #1,D1                       * By subtracting '1' from D1 this will 
											* serve to decrement the counter of the 
											* length of the examined address
											
    CMP.B       #0,D1						* Check if the counter is 0, if it is 
											* begin the process of validating the
											* address that was just converted.
    
	BEQ         VALIDATING_BEG_ADDRESS		* Appropriate branch for condition above.
	
    LSL.L       #4,D3                       * Performing a 4 bit shift to the left
										                * will leave room for the next nibble 
											* of the address. After all if we're here
											* then that means there's still some 
											* address to be read in. 
    
	BRA         PrintHexAddress     		* Branches back to the beginning of the 
											* subroutine this is done since the
											* counter hasn't reached 0 yet, so 
											* we still have some more characters
											* to convert for the address. 

 * This subroutine is responsible for checking to 
 * see if the starting address is valid or not.
 * It uses other subroutine to handle issue if it
 * is invalid
 ****
VALIDATING_BEG_ADDRESS
    *BTST        #0,D3						* By performing a BTST on the 0 bit of D3
											* the program is in effect testing the 
											* converted HEX version of the address 
											* which is stored in data register D3 
											* to see if it has an odd address. 
											* Remember BTST will check to see if 
											* the bit is 0. Therefore we use BNE
											* below to leave since it'll mean that
											* the address ends in an odd number. 
											
    *BNE         HANDLING_INVALID_BEG_ADDR	* If it's an odd number it's an invalid 
											* beginning address
											
    CMP         #1,D2                       * This design will always go through here
											* first for starting and ending addresses
    
	BEQ         VALIDATING_FINISH_ADDRESS	* If it is equal to 1, then the program 
											* already has a validated starting address
											* therefore we shift control to the 
											* ending address validation subroutine. 
											
    ADDI        #1,D2                       * If it's 1 then this subroutine 
											* will know to branch to the ending address
											* subroutine instead of overwriting the 
											* starting address with a new one. 
											
    MOVE.L      D3,BEGINNING_ADDRESS		* This will move the contents of the
											* now verified HEX version of the 
											* starting address to the BEGINNING_ADDRESS
											* variable for storage. 
    
	CLR         D3							* The program is now ready to clear the
											* D3 register, so that it can be used by
											* the disassembler to store the HEX
											* version of the ending address. 
											
    BRA         GET_FINISH_ADDR				* Now that beginning address is complete
											* it's time to get the ending address. 
											
											
 * This subroutine is responsible for checking to 
 * see if the ending address is valid or not.
 * It uses other subroutine to handle the issues
    
 * Once those checks are completed, it will 
 * clear the D2 register that was previously 
 * used as a toggle to indicate that the
 * STARTING address was already verified.
 *
 * Then load the address to ending address
VALIDATING_FINISH_ADDRESS
    *BTST        #0,D3                       * By performing a BTST on the 0 bit of D3
											* the program is in effect testing the 
											* converted HEX version of the address 
											* which is stored in data register D3 
											* to see if it has an odd address.  
    *BNE         HANDLING_INVALID_FINISH_ADDR * If it's an odd number it's an invalid 
											 * ending address 
											 
    CMP.L       BEGINNING_ADDRESS, D3       we are checking to see if the ending 
											* address which we have stored in D3 
											* is less than or equal to starting 
											* address provided by the user. 
											
    BLE         HANDLING_INVALID_FINISH_ADDR * If it's less than or equal to the 
											 * starting address then the ending 
											 * address is not valid 
											 
    CLR.W       D2                          * Once those checks are completed, it will 
											* clear the D2 register that was previously 
											* used as a toggle to indicate that the
											* STARTING address was already verified.
	
    MOVE.L      D3,FINISHING_ADDRESS		* This will move the contents to the FINISHING_ADDRESS
											* variable for storage. 
											
    CLR.W       D3							* Clear the D3 register, so that it can be used by
											* the disassembler.
											
    JSR         PrintSpace

    BRA         LoadAddress	
   
    SIMHALT

 * This subroutine is responsible for prompting 
 * the user that it is invalid
 ****
HANDLING_INVALID_BEG_ADDR
    MOVEA.L     #0,A1				* Clears the A1 address for future usage. 
    LEA         BAD_INPUT_MSG,A1	* Loads the message about bad input to A1
    MOVE.B      #13,D0				* Preps the TRAP TASK #13
    TRAP        #15					* Executes the TRAP task. 
    CLR         D3					* Clear the D3 register which is used
									* as a storage of the hex addresses. 
    BRA         GET_BEGIN_ADDR		* Branch to the subroutine that will
									* get the user input. 


 * This subroutine is responsible for prompting
 * the user 
 ****
HANDLING_INVALID_FINISH_ADDR
    MOVEA.L     #0,A1				* Clears the A1 address for future usage. 
    LEA         BAD_INPUT_MSG,A1	* Loads the message about bad input to A1
    MOVE.B      #13,D0				* Preps the TRAP TASK #13
    TRAP        #15					* Executes the TRAP task. 
    CLR         D3					* Clear the D3 register which is used
									* as a storage of the hex addresses.
    BRA         GET_FINISH_ADDR		* Branch to the subroutine that will
									* get the user input.
 * This subroutine is responsible for changing
 * the control of the program to the appropriate
 * subroutine for handling specific cases 
 * of bad address input. 
 * This subroutine will use the D2 data register 
 * to check since if it's value is 1 then the 
 * toggle has been set and the beginning
 * address has been verified, so then 
 * the ending address must be invalid. 
 ****
SWITCH_BAD_INPUT
    CMP         #1,D2				* Checks the D2 register 

    BEQ         HANDLING_INVALID_FINISH_ADDR * If it's equal to 1 then 
											 * starting address has 
											 * already been verified
											 
    BRA         HANDLING_INVALID_BEG_ADDR	* If it's 0 then beginning is invalid


******
 * The EnterCheck subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * checking if the user is able to 
 * press enter yet. 
 * This will be ran 30 or so times 
 * to represent the 30 statements 
 * that will be printed out before
 * an entire screen of output is complete.
 * If 30 hasn't been reached then it will 
 * just print a space and then return to
 * the subroutine that invoked it. 
 ****
EnterCheck    
    ADD         #1,D6					* D6 is used as the counter for number of 
										* statements printed out. 
    CMP         #30,D6 					* Since the screen is about 30 statements 
										* in height, then this counter needs 
										* to reach 30 before the user can press enter. 
    BEQ         EnterCheckHelper    	* If 30 has been reached let the user enter. 
    LEA         Space_String,A1			* If not then just print a string.
    MOVE        #13,D0					* Loads TRAP TASK #13
    TRAP        #15						* Execute TRAP TASK
    RTS									* Return to the subroutine

******
 * The EnterCheckHelper subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * allowing the user to press enter.
 * This will in turn allow the print out
 * of additional instructions to the screen.
 ****
EnterCheckHelper
    MOVE        #0,D6		* Reset the counter which is D6
    MOVE.B      #5,D0		* Load TRAP TASK #5	
    TRAP        #15			* Execute the TRAP TASK
    RTS						* Rerturn to the subroutine.



BadOpcode
    LEA     Data_String,A1      *Place the string with 'DATA' in A1
    JSR     PrintInstruction    *Print 'DATA'
    JSR     PrintSpace          *Print a space
    JSR     PrintSpace
    JSR     PrintHexSymbol      *Print $ for hex address
    JSR     HexToAscii          *Print hex value of invalid opcode
    BRA     GetNextOpcode       *Gets the next opcode in memory
    
    
    
  * GET_THE_ADDR_CONTENT_TO_D3 subroutine:
 * ---------------------
 * This subroutine is responsible for moving the 
 * current address of the assembler by 
 * one word or about 4 nibbles and copying 
 * it to the D3 register and FourNibbles 
 *
 * It will also check if we're past the ending address
 * and it will branch appropriately 
 ***
GET_THE_ADDR_CONTENT_TO_D3
    MOVE.W      (A2)+,D3							* Move to the next word in the address
    MOVE.W      D3, $200                            * Move the value into the CURRENT_FOUR_NIBBLES_VAR
    CMPA.L      A2,A3                               * Check to see if we're past the ending address
    BLT         REPEAT_OR_DONE					* Branch to REPEAT OR DONE if we are. 
    RTS
******
 *	This subroutine is used to see
 *	if the user wants to finish or restart
 * 	the disassembler 
 ****
REPEAT_OR_DONE	
    LEA         ENDING_P1, A1
    MOVE.B      #14,D0
    TRAP        #15
    MOVE.B      #4, D0
    TRAP        #15  
    CMP.B       #1, D1
    BEQ         CLEANING
    CMP.B       #0, D1
    BNE         INVALID_END
    SIMHALT
******
 *	This subroutine is used in the 
 *	case of an invalid ending input. 
 ****
INVALID_END
    LEA         INVALID_ENDING, A1
    MOVE.B      #14,D0
    TRAP        #15
    BRA         REPEAT_OR_DONE
    
****
* This is the JumpToInstruction  subroutine
*****
JumpToInstruction
    MOVE.W  D3,D5
    LSR.W   #8,D5
    LSR.W   #4,D5
    
    CMP.B   #%0001,D5
    BEQ     Move
    CMP.B   #%0010,D5
    BEQ     Move
    CMP.B   #%0011,D5
    BEQ     Move
    CMP.B   #%0111,D5
    BEQ     MoveQ
    CMP.B   #%0100,D5
    BEQ     MoveMOrNotOrJSROrRTSOrLEAOrNOP
    CMP.B   #%1101,D5
    BEQ     Add
    CMP.B   #%0101,D5
    BEQ     AddQ
    CMP.B   #%1001,D5
    BEQ     Sub
    CMP.B   #%1100,D5
    BEQ     AndOrMuls
    CMP.B   #%1000,D5
    BEQ     OrOrDivu
    CMP.B   #%1110,D5
    BEQ     Logical_Shift
    CMP.B   #%0110,D5
    BEQ     BccOrBra
    
****
* This is the AndOrMuls subroutine
*****
AndOrMuls
    MOVE.W  D3,D5
    LSL.W   #7,D5
    LSR.W   #8,D5
    LSR.W   #5,D5
    CMP.B   #%111,D5
    BEQ     Muls
    
    BRA     PrintAND
    
****
* This is the OrOrDivu subroutine
*****
OrOrDivu
    MOVE.W  D3,D5
    LSL.W   #7,D5
    LSR.W   #8,D5
    LSR.W   #5,D5
    CMP.B   #%011,D5
    BEQ     Divu
    
    BRA     PrintOr
    
    ****
* This is the MoveMOrNotOrJSROrRTSOrLEAOrNOP subroutine
*****
MoveMOrNotOrJSROrRTSOrLEAOrNOP
    MOVE.W  D3,D5
    
    CMP.W   #%0100111001110101,D5
    BEQ     PrintRTS
    CMP.W   #%0100111001110001,D5
    BEQ     PrintNOP
    LSR.W   #8,D5
    CMP.B   #%01000110,D5
    BEQ     OUTPUT_NOT
    MOVE.W  D3,D5
    LSR.W   #4,D5

    LSR.W   #2,D5
    CMP.W   #%0100111010,D5
    BEQ     Jsr
    MOVE.W  D3,D5
    
    LSL.W   #7,D5
    LSR.W   #8,D5
    LSR.W   #5,D5
    CMP.B   #%111,D5
    BEQ     PrintLEA
    
    
    BRA     MoveM
****
* This is the LogShiftOrAriShiftOrRotate Subroutine
******
LogShiftOrAriShift
    MOVE.W  D3,D5
    BRA     Logical_Shift
    
*****
* This is the BccOrBra subroutine
*******
    
BccOrBra
    MOVE.W  D3,D5
    LSR.W   #8,D5
    CMP.B   #%01100000,D5
    BEQ     Bra
    
    BRA     Bcc
    
Bcc
    MOVE.W  D3,D5
    LSL.W   #4,D5
    LSR.W   #8,D5
    LSR.W   #4,D5
    CMP.B   #7,D5
    BEQ     BEQ_OUTPUT
    CMP.B   #15,D5
    BEQ     BLE_OUTPUT
    CMP.B   #14,D5
    BEQ     BGT_OUTPUT
    
    BRA     BadOpcode
    

Move
        *Get the data of the current address into a data register.
    JSR     GetDestAndSource
    MOVE.W  DestMode,A5
    CMP.W   #1,A5         *If destination mode is 001 then it is an address
                                    *register so it is MOVEA instead of MOVE
    BEQ     MoveA
    LEA     Move_String,A1          *Load MOVE into A1
    MOVE.B  #14,D0
    TRAP    #15                     *Print MOVE
    BRA     RestOfMove
   
MoveA
    LEA     MoveA_String,A1         *Move string for MOVEA into A1
    MOVE.B  #14,D0                  
    TRAP    #15                     *Print 'MOVEA'
    BRA     RestOfMove              *Branch to decode the rest of MOVE operation

RestOfMove
    JSR     FindSize                *Finds and prints the size of the operation.
    JSR     PrintSpace              *Print a space
    JSR     FindSourceMode          *Find and print source type
    JSR     PrintComma              *Print comma
    JSR     FindDestMode           *Find and print destination mode
    BRA     GetNextOpcode           *Gets the next word in memory for the next opcode
    
    RTS
    
MoveQ
    LEA     MoveQ_String,A1
    JSR     PrintInstruction
    JSR     PrintSpace
    JSR     PrintImmediate
    JSR     PrintHexSymbol
    JSR     GetData
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindDestReg
    
    BRA     GetNextOpcode
    
    RTS
    
GetData
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSR.W   #8,D5
    LEA     JumpHex,A4
    MOVE.W      FourNibbles,D3	 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation.
											 
    JSR         STORE_THIRD_NIBBLE_IN_D3     * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the second nibble which for our
											 * purposes in the HexToAscii											 * is the second right most HEX character 
											 * or value that must be converted
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											 
    JSR         0(A4,D3)					 * Performs the jump to subroutine to
											 * the JumpHex with the D3 
											 * as an offset to determine the 
											 * appropriate print out. 
											 
    MOVE.W      FourNibbles,D3	 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation.
											 
    JSR         STORE_FOURTH_NIBBLE_IN_D3	 * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the second nibble which for our
											 * purposes in the HexToAscii											 * is the second right most HEX character 
											 * or value that must be converted
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											 
    JSR         0(A4,D3)					 * Performs the jump to subroutine to
											 * the JumoHex with the D3 
											 * as an offset to determine the 
											 * appropriate print out.
    RTS
******
 * The HexToAscii subroutine: 
 * --------------------------------------
 * This subroutine is responsible for changing
 * the HEX based stored values that will need
 * to be printed out at this current moment 
 * to ASCII. 
 * 
 * Typically this subroutine is invoked
 * to print out elements such as Address location, 
 * the Absolute short and long, immediate data, 
 * among other elements. 
 *
 * This subroutine will print one nibble (4-bits)
 * at a time while printing out 4 nibbles in total 
 * or about (16 bits). 
 ****
HexToAscii
    LEA         JumpHex,A4     	 * This instruction will load the address 
											 * of the JumpHex to the A4 
											 * register to enable the output of 
											 * ASCII characters. This will be
											 * used with displacement to determine 
											 * appropriate jump with offset
											 
    MOVE.W      FourNibbles,D3	 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation. 
											 
    JSR         STORE_FIRST_NIBBLE_IN_D3     * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the first nibble 
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											 
    JSR         0(A4,D3)					 * Performs the jump to subroutine 
																						 
    MOVE.W      FourNibbles,D3	 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation.
											 
    JSR         STORE_SECOND_NIBBLE_IN_D3    * This instruction is a jump to a subroutine designed specifically for getting the second nibble     * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the second nibble which for our
											 * purposes in the HexToAScii											 * is the second left most HEX character 
											 * or value that must be converted
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											
    JSR         0(A4,D3)					 * Performs the jump to subroutine to
											 * the JumpHex with the D3 
											 * as an offset to determine the 
											 * appropriate print out. 
											 
    MOVE.W      FourNibbles,D3	 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation.
											 
    JSR         STORE_THIRD_NIBBLE_IN_D3     * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the second nibble which for our
											 * purposes in the HexToAscii											 * is the second right most HEX character 
											 * or value that must be converted
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											 
    JSR         0(A4,D3)					 * Performs the jump to subroutine to
											 * the JumpHex with the D3 
											 * as an offset to determine the 
											 * appropriate print out. 
											 
    MOVE.W      FourNibbles,D3	 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation.
											 
    JSR         STORE_FOURTH_NIBBLE_IN_D3	 * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the second nibble which for our
											 * purposes in the HexToAscii											 * is the second right most HEX character 
											 * or value that must be converted
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											 
    JSR         0(A4,D3)					 * Performs the jump to subroutine to
											 * the JumoHex with the D3 
											 * as an offset to determine the 
											 * appropriate print out.
											 
    CLR.W       D3							 * This instruction will clear the D3 
											 * so that it can be used in other spots
											 
    RTS										 * Return to the subroutine that called this function. 

*****
 * The STORE_FIRST_NIBBLE_IN_D3 subroutine:
 * ---------------------
 * This subroutine is responsible for leaving
 * only the first nibble. 
 * 
 * This function should only be invoked 
 * when the full word of data has already 
 * been copied to D3 
 ***
STORE_FIRST_NIBBLE_IN_D3
    LSR         #8,D3   * Shift 2 nibbles to the rights
    LSR         #4,D3   * Shift 1 nibbles to the right. Now left most nibble is now the right-most nibble
    RTS

STORE_FIRST_NIBBLE_IN_D2
    MOVE.W      FourNibbles,D2
    LSR         #8,D2   * Shift 2 nibbles to the rights
    LSR         #4,D2   * Shift 1 nibbles to the right. Now left most nibble is now the right-most nibble
    RTS

STORE_THIRD_NIBBLE_IN_D2
	MOVE.W      FourNibbles,D2
    LSL         #8,D2   * Shift 2 nibbles to the left
    LSR         #8,D2   * Shift 2 nibbles to the right return to original position 
	LSR			#4,D2	* Shift 1 nibbles to the left leave only 
    RTS
	
STORE_FOURTH_NIBBLE_IN_D2
    MOVE.W      FourNibbles,D2
    LSL         #8,D2   * Shift 2 nibbles to the rights
    LSL         #4,D2   * Shift 1 nibbles to the right. Now left most nibble is now the right-most nibble
	LSR			#8,D2
	LSR 		#4,D2
    RTS

*****
 * The STORE_SECOND_NIBBLE_IN_D3 subroutine:
 * ---------------------
 * This subroutine is responsible for leaving
 * only the second nibble. 
 * 
 * This function should only be invoked 
 * when the full word of data has already 
 * been copied to D3 
 ***
STORE_SECOND_NIBBLE_IN_D3
    LSL         #4,D3    * Shift the left most nibble to go away
    LSR         #4,D3    * Return the original place
    LSR         #8,D3    * Push the 2 right-most nibbles out of the way
    RTS

*****
 * The STORE_THIRD_NIBBLE_IN_D3 subroutine:
 * ---------------------
 * This subroutine is responsible for leaving
 * only the third nibble. 
 * 
 * This function should only be invoked 
 * when the full word of data has already 
 * been copied to D3 
 ***
STORE_THIRD_NIBBLE_IN_D3
    LSL         #8,D3     * Shift out the 2 left-most nibbles
    LSR         #8,D3     * Shift bits back to original position 
    LSR         #4,D3     * Shift out the least Significant Nibble 
    RTS

*****
 * The STORE_FOURTH_NIBBLE_IN_D3 subroutine:
 * ---------------------
 * This subroutine is responsible for leaving
 * only the fourth nibble. 
 * 
 * This function should only be invoked 
 * when the full word of data has already 
 * been copied to D3 
 ***
STORE_FOURTH_NIBBLE_IN_D3
    LSL         #8,D3	* Shift out two most sig nibbles
    LSL         #4,D3	* Shift out third most sig nibble
    LSR         #8,D3	* Return to original position 
    LSR         #4,D3
    RTS
    
OUTPUT_WORD_SIZE_USUAL
    LEA         Word_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    JSR         PrintSpace			* Invokes subroutine to print a space
    RTS

*****
 * The D3_GET_NEXT_FOUR_NIB subroutine:
 * ---------------------
 * This subroutine is responsible for moving the 
 * current address of the assembler by 
 * one word or about 4 nibbles and copying 
 * it to the D3 register and FourNibbles
 *
 * It will also check if we're past the ending address
 * and it will branch appropriately 
 ***
D3_GET_NEXT_FOUR_NIB
    MOVE.W      (A2)+,D3							* Move to the next word in the address
    MOVE.W      D3, FourNibbles       * Move the value into the FourNibbles
    CMPA.L      A2,A3                               * Check to see if we're past the ending address
    BLT         REPEAT_OR_DONE				* Branch to REPEAT OR DONE if we are. 
    RTS


MoveM
    JSR     GetDestAndSource
    MOVE.W  SourceMode,A5
    CMP.W   #0,A5
    BEQ     BadOpcode
    CMP.W   #1,A5
    BEQ     BadOpcode
    BRA     FindDr
*    LEA     MoveM_String,A1
*    JSR     PrintInstruction
*    JSR     GetDestAndSource
*    JSR     FindMoveMSize
*    JSR     PrintSpace

    BRA     GetNextOpcode           *Gets the next word in memory for the next opcode

    RTS
    
FindMoveMSize
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #1,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%0,D5
    BEQ     PrintWord
    CMP.B   #%1,D5
    BEQ     PrintLong     

FindDr
    MOVE.W  D3,D5
    LSL.W   #5,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%0,D5
    BEQ     MoveMRegFirst
    CMP.B   #%1,D5
    BEQ     MoveMMemFirst
    
MoveMRegFirst
    *MOVEM.L A7-A0,-(SP)
    MOVE.W  SourceMode,A5
    CMP.W   #3,A5
    BEQ     BadOpcode
    CMP.W   #5,A5
    BEQ     BadOpcode
    CMP.W   #6,A5
    BEQ     BadOpcode
    JSR     CheckForBadReg
    LEA     MoveM_String,A1
    JSR     PrintInstruction
    JSR     GetDestAndSource
    JSR     FindMoveMSize
    JSR     PrintSpace

    JSR     MoveMRegFirstEaMode
    
    BRA     GetNextOpcode
    
    RTS
    
CheckForBadReg
    CMP.W   #7,A5
    BEQ     CheckAbsoluteForBadReg
    
    RTS
    
CheckAbsoluteForBadReg
    MOVE.W  SourceReg,A5
    CMP.W   #0,A5
    BEQ     GoodReg
    CMP.W   #1,A5
    BEQ     GoodReg
    
    BRA     BadOpcode
    
    RTS

GoodReg
    RTS  
    
MoveMRegFirstEaMode
    MOVE.W  SourceMode,A5
    CMP.W   #7,A5
    BEQ     MoveM_Mode_Abs_Reg   *Source mode is either absolute address or immediate addressing.   
    JSR     FindRegFirstMask
    JSR     PrintComma
    CMP.W   #2,A5
    BEQ     MoveM_Mode_Indirect_Reg
    CMP.W   #4,A5
    BEQ     MoveM_Mode_IndirectMinus_Reg
    CMP.W   #5,A5
    BEQ     BadOpcode
    CMP.W   #6,A5
    BEQ     BadOpcode

    
    BRA     BadOpcode

MoveM_Mode_Indirect_Reg
    LEA     Left_Par_String,A1
    JSR     PrintInstruction
    JSR     PrintAddressRegister
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    
    RTS


MoveM_Mode_IndirectMinus_Reg
    LEA     Minus_String,A1
    JSR     PrintInstruction
    LEA     Left_Par_String,A1
    JSR     PrintInstruction
    JSR     PrintAddressRegister
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    
    RTS



MoveM_Mode_Abs_Reg
    JSR     FindRegMask
    JSR     PrintComma
    JSR     PrintHexSymbol
    MOVE.W  SourceReg,A5
    CMP.W   #%000,A5
    BEQ     MoveMAbsWordReg
    CMP.W   #%001,A5
    BEQ     MoveMAbsLongReg
    
    BRA     BadOpcode 

MoveMAbsWordReg
    JSR     GET_THE_ADDR_CONTENT_TO_D3
    *MOVE.W  (A2)
    JSR     HexToAscii
    RTS


MoveMAbsLongReg
    MOVE.L  (A2)+,D4
    JSR     HEX_TO_ASCII_CHANGER_FULLSIZE
    RTS

MoveMMemFirst
    *MOVEM.L (SP)+,A7-A0
    MOVE.W  SourceMode,A5
    CMP.W   #4,A5
    BEQ     BadOpcode
    CMP.W   #5,A5
    BEQ     BadOpcode
    CMP.W   #6,A5
    BEQ     BadOpcode
    JSR     CheckForBadReg
    LEA     MoveM_String,A1
    JSR     PrintInstruction
    JSR     GetDestAndSource
    JSR     FindMoveMSize
    JSR     PrintSpace

    JSR     MoveMMemFirstEaMode
    
    BRA     GetNextOpcode
    
    RTS
    *JSR     FindSourceReg
    
MoveMMemFirstEaMode
    MOVE.W  SourceMode,A5
    CMP.W   #2,A5
    BEQ     MoveM_Mode_Indirect_Ea
    CMP.W   #3,A5
    BEQ     MoveM_Mode_IndirectPlus_Ea
    CMP.W   #5,A5
    BEQ     BadOpcode
    CMP.W   #6,A5
    BEQ     BadOpcode
    CMP.W   #7,A5
    BEQ     MoveM_Mode_Abs_Ea    *Source mode is either absolute address or immediate addressing.
    
    BRA     BadOpcode
    
MoveM_Mode_Indirect_Ea
    LEA     Left_Par_String,A1
    JSR     PrintInstruction
    JSR     PrintAddressRegister
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    JSR     PrintComma
    JSR     FindRegMask
    RTS
    
MoveM_Mode_IndirectPlus_Ea
    LEA     Left_Par_String,A1
    JSR     PrintInstruction
    JSR     PrintAddressRegister
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    LEA     Plus_String,A1
    JSR     PrintInstruction
    JSR     PrintComma
    JSR     FindRegMask
    RTS

MoveM_Mode_Abs_Ea
    JSR     PrintHexSymbol
    MOVE.W  SourceReg,A5
    CMP.W   #%000,A5
    BEQ     MoveMAbsWord
    CMP.W   #%001,A5
    BEQ     MoveMAbsLong
    
    BRA     BadOpcode   
    
MoveMAbsWord
    JSR     GET_THE_ADDR_CONTENT_TO_D3
    JSR     GET_THE_ADDR_CONTENT_TO_D3
    JSR     HexToAscii
    JSR     PrintComma
    MOVE.W  -(A2),D3
    MOVE.W  -(A2),D3
    JSR     FindRegMask
    MOVE.W  (A2)+,D3
    RTS


MoveMAbsLong
    MOVE.W  (A2)+,D3  
    MOVE.L  (A2)+,D4
    JSR     HEX_TO_ASCII_CHANGER_FULLSIZE
    JSR     PrintComma
    MOVE.L  -(A2),D3
    MOVE.W  -(A2),D3
    JSR     FindRegMask
    MOVE.L  (A2)+,D3
    RTS
    
FindRegMask
    MOVE.W  (A2)+,D3
    JSR     CheckFifteen
    RTS
    
FindRegFirstMask
    MOVE.W  (A2)+,D3
    JSR     CheckRegFifteen
    RTS   

CheckFifteen
    MOVE.W  D3,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA7
    
    BRA     CheckFourteen
    
PrintA7
    JSR     PrintAddressRegister
    JSR     PrintHexSeven
    JSR     PrintSlash
    BRA     CheckFourteen
    
CheckFourteen
    MOVE.W  D3,D5
    LSL.W   #1,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA6
    
    BRA     CheckThirteen
    
PrintA6
    JSR     PrintAddressRegister
    JSR     PrintHexSix
    JSR     PrintSlash
    BRA     CheckThirteen
    
CheckThirteen
    MOVE.W  D3,D5
    LSL.W   #2,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA5
    
    BRA     CheckTwelve
    
PrintA5
    JSR     PrintAddressRegister
    JSR     PrintHexFive
    JSR     PrintSlash
    BRA     CheckTwelve
    
CheckTwelve
    MOVE.W  D3,D5
    LSL.W   #3,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA4
    
    BRA     CheckEleven
    
PrintA4
    JSR     PrintAddressRegister
    JSR     PrintHexFour
    JSR     PrintSlash
    BRA     CheckEleven
    
CheckEleven
    MOVE.W  D3,D5
    LSL.W   #4,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA3
    
    BRA     CheckTen
    
PrintA3
    JSR     PrintAddressRegister
    JSR     PrintHexThree
    JSR     PrintSlash
    BRA     CheckTen
    
CheckTen
    MOVE.W  D3,D5
    LSL.W   #5,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA2
    
    BRA     CheckNine
    
PrintA2
    JSR     PrintAddressRegister
    JSR     PrintHexTwo
    JSR     PrintSlash
    BRA     CheckNine
    
CheckNine
    MOVE.W  D3,D5
    LSL.W   #6,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA1
    
    BRA     CheckEight
    
PrintA1
    JSR     PrintAddressRegister
    JSR     PrintHexOne
    JSR     PrintSlash
    BRA     CheckEight
    
CheckEight
    MOVE.W  D3,D5
    LSL.W   #7,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintA0
    
    BRA     CheckSeven
    
PrintA0
    JSR     PrintAddressRegister
    JSR     PrintHexZero
    JSR     PrintSlash
    BRA     CheckSeven
    
CheckSeven
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD7
    
    BRA     CheckSix
    
PrintD7
    JSR     PrintDataRegister
    JSR     PrintHexSeven
    JSR     PrintSlash
    BRA     CheckSix
    
CheckSix
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #1,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD6
    
    BRA     CheckFive
    
PrintD6
    JSR     PrintDataRegister
    JSR     PrintHexSix
    JSR     PrintSlash
    BRA     CheckFive
    
CheckFive
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #2,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD5
    
    BRA     CheckFour
    
PrintD5
    JSR     PrintDataRegister
    JSR     PrintHexFive
    JSR     PrintSlash
    BRA     CheckFour
    
CheckFour
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #3,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD4
    
    BRA     CheckThree
    
PrintD4
    JSR     PrintDataRegister
    JSR     PrintHexFour
    JSR     PrintSlash
    BRA     CheckThree
    
CheckThree
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #4,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD3
    
    BRA     CheckTwo
    
PrintD3
    JSR     PrintDataRegister
    JSR     PrintHexThree
    JSR     PrintSlash
    BRA     CheckTwo
    
CheckTwo
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #5,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD2
    
    BRA     CheckOne
    
PrintD2
    JSR     PrintDataRegister
    JSR     PrintHexTwo
    JSR     PrintSlash
    BRA     CheckOne
    
CheckOne
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #6,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD1
    
    BRA     CheckZero
    
PrintD1
    JSR     PrintDataRegister
    JSR     PrintHexOne
    JSR     PrintSlash
    BRA     CheckZero
    
CheckZero
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #7,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintD0
    
    RTS
    
PrintD0
    JSR     PrintDataRegister
    JSR     PrintHexZero
    RTS

CheckRegFifteen
    MOVE.W  D3,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD0
    
    BRA     CheckRegFourteen
    
PrintRegA7
    JSR     PrintAddressRegister
    JSR     PrintHexSeven
    RTS
    
CheckRegFourteen
    MOVE.W  D3,D5
    LSL.W   #1,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD1
    
    BRA     CheckRegThirteen
    
PrintRegA6
    JSR     PrintAddressRegister
    JSR     PrintHexSix
    JSR     PrintSlash
    BRA     CheckRegZero
    
CheckRegThirteen
    MOVE.W  D3,D5
    LSL.W   #2,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD2
    
    BRA     CheckRegTwelve
    
PrintRegA5
    JSR     PrintAddressRegister
    JSR     PrintHexFive
    JSR     PrintSlash
    BRA     CheckRegOne
    
CheckRegTwelve
    MOVE.W  D3,D5
    LSL.W   #3,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD3
    
    BRA     CheckRegEleven
    
PrintRegA4
    JSR     PrintAddressRegister
    JSR     PrintHexFour
    JSR     PrintSlash
    BRA     CheckRegTwo
    
CheckRegEleven
    MOVE.W  D3,D5
    LSL.W   #4,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD4
    
    BRA     CheckRegTen
    
PrintRegA3
    JSR     PrintAddressRegister
    JSR     PrintHexThree
    JSR     PrintSlash
    BRA     CheckRegThree
    
CheckRegTen
    MOVE.W  D3,D5
    LSL.W   #5,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD5
    
    BRA     CheckRegNine
    
PrintRegA2
    JSR     PrintAddressRegister
    JSR     PrintHexTwo
    JSR     PrintSlash
    BRA     CheckRegFour
    
CheckRegNine
    MOVE.W  D3,D5
    LSL.W   #6,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD6
    
    BRA     CheckRegEight
    
PrintRegA1
    JSR     PrintAddressRegister
    JSR     PrintHexOne
    JSR     PrintSlash
    BRA     CheckRegFive
    
CheckRegEight
    MOVE.W  D3,D5
    LSL.W   #7,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegD7
    
    BRA     CheckRegSeven
    
PrintRegA0
    JSR     PrintAddressRegister
    JSR     PrintHexZero
    JSR     PrintSlash
    BRA     CheckRegSix
    
CheckRegSeven
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA0
    
    BRA     CheckRegSix
    
PrintRegD7
    JSR     PrintDataRegister
    JSR     PrintHexSeven
    JSR     PrintSlash
    BRA     CheckRegSeven
    
CheckRegSix
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #1,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA1
    
    BRA     CheckRegFive
    
PrintRegD6
    JSR     PrintDataRegister
    JSR     PrintHexSix
    JSR     PrintSlash
    BRA     CheckRegEight
    
CheckRegFive
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #2,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA2
    
    BRA     CheckRegFour
    
PrintRegD5
    JSR     PrintDataRegister
    JSR     PrintHexFive
    JSR     PrintSlash
    BRA     CheckRegNine
    
CheckRegFour
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #3,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA3
    
    BRA     CheckRegThree
    
PrintRegD4
    JSR     PrintDataRegister
    JSR     PrintHexFour
    JSR     PrintSlash
    BRA     CheckRegTen
    
CheckRegThree
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #4,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA4
    
    BRA     CheckRegTwo
    
PrintRegD3
    JSR     PrintDataRegister
    JSR     PrintHexThree
    JSR     PrintSlash
    BRA     CheckRegEleven
    
CheckRegTwo
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #5,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA5
    
    BRA     CheckRegOne
    
PrintRegD2
    JSR     PrintDataRegister
    JSR     PrintHexTwo
    JSR     PrintSlash
    BRA     CheckRegTwelve
    
CheckRegOne
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #6,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA6
    
    BRA     CheckRegZero
    
PrintRegD1
    JSR     PrintDataRegister
    JSR     PrintHexOne
    JSR     PrintSlash
    BRA     CheckRegThirteen
    
CheckRegZero
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #7,D5
    LSR.W   #8,D5
    LSR.W   #7,D5
    CMP.B   #%1,D5
    BEQ     PrintRegA7
    
    RTS
    
PrintRegD0
    JSR     PrintDataRegister
    JSR     PrintHexZero
    JSR     PrintSlash
    BRA     CheckRegFourteen
    
    
Jsr
    JSR     GetDestAndSource
    MOVE.W  SourceMode,A5
    CMP.W   #2,A5
    BEQ     JsrSourceIndirectAn
    CMP.W   #7,A5
    BEQ     JsrSourceAbsolute
    
    BRA     BadOpcode
    
JsrSourceIndirectAn
    LEA     Jsr_String,A1
    JSR     PrintInstruction
    JSR     PrintSpace
    JSR     PrintSpace
    LEA     Left_Par_String,A1
    JSR     PrintInstruction
    JSR     PrintAddressRegister
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    
    BRA     GetNextOpcode
    
    RTS
    
JsrSourceAbsolute
    MOVE.W  SourceReg,A5
    CMP.W   #0,A5
    BEQ     JsrWord
    CMP.W   #1,A5
    BEQ     JsrLong
    
    BRA     BadOpcode
    
JsrWord
    LEA     Jsr_String,A1
    JSR     PrintInstruction
    JSR     PrintSpace
    JSR     PrintSpace
    JSR     PrintHexSymbol
    JSR     D3_GET_NEXT_FOUR_NIB
    JSR     HexToAscii
    
    BRA     GetNextOpcode
    
    RTS

JsrLong
    LEA     Jsr_String,A1
    JSR     PrintInstruction
    JSR     PrintSpace
    JSR     PrintSpace
    JSR     PrintHexSymbol
    MOVE.L  (A2)+,D4
    JSR     HEX_TO_ASCII_CHANGER_FULLSIZE
    
    BRA     GetNextOpcode
    
    RTS


Bra
    LEA     Bra_String,A1
    JSR     PrintInstruction
    JSR     PrintSpace
    JSR     PrintHexSymbol
    JSR     GetDisplacement
    
GetDisplacement
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSR.W   #8,D5
    CMP.B   #$00,D5
    BEQ     Displacement16
    CMP.B   #$FF,D5
    BEQ     Displacement32
    
    BRA     Displacement8
    
Displacement8
    MOVE.W  A2,A6
    SUB.W   D5,A6
    MOVE.W  A6,D5
    JSR     HexToAscii
    
    RTS
    
Displacement16
    MOVE.W  A2,A6
    MOVE.W  (A6)+,D5
    MOVE.W  A2,A6
    SUB.W   D5,A6
    MOVE.W  A6,D5
    JSR     HexToAscii
    ADD.W   #16,A2
    
    RTS

Displacement32
    JSR     Displacement16
    JSR     Displacement16
    
    RTS
    

    

FindSize
    
    MOVE.W  D3,D5
    *Assume D5 has the word in current address.
    LSL.W     #2,D5             *Shift bits 2 left 14 right to get the two size bits.
    LSR.W     #8,D5
    LSR.W     #6,D5
    
    CMP.B     #%00,D5           *If size is 0 go to bad opcode
    BEQ       BadOpcode
    CMP.B     #%01,D5           *If size is 1 print .B
    BEQ       PrintByte
    CMP.B     #%10,D5           *If size is 2 print .L
    BEQ       PrintLong
    CMP.B     #%11,D5           *If size is 3 print .W
    BEQ       PrintWord
    
GetDestAndSource

    MOVE.W  FourNibbles,D5
    *Assume D5 has the word in current address.
    LSL.W   #4,D5               *Get 3 bits for destination register using shifts
    LSR.W   #8,D5
    LSR.W   #5,D5
    MOVE.W  D5,DestReg          *Move D5 into destination register variable
    
    *Put word in current address back into D5
    MOVE.W  D3,D5
    LSL.W   #7,D5               *Get 3 bits for destination mode using shifts
    LSR.W   #8,D5
    LSR.W   #5,D5
    MOVE.W  D5,DestMode         *Move D5 into destination mode variable
    
    *Put word in current address back into D5
    MOVE.W  D3,D5
    LSL.W   #8,D5               *Get 3 bits for source mode using shifts
    LSL.W   #2,D5
    LSR.W   #8,D5
    LSR.W   #5,D5
    MOVE.W  D5,SourceMode        *Move D5 into source mode variable
    
    *Put word in current address back into D5
    MOVE.W  D3,D5
    LSL.W   #8,D5               *Get 3 bits for source register using shifts
    LSL.W   #5,D5
    LSR.W   #8,D5
    LSR.W   #5,D5
    MOVE.W  D5,SourceReg        *Move D5 into source mode variable
    
    RTS
    
    
FindSourceMode
    MOVE.W  SourceMode,A5
    CMP.W   #0,A5                *Check the source mode bits, and branch to
    BEQ     Source_Mode_Dn                  *corresponding function for the mode relating
    CMP.W   #1,A5                *to those bits
    BEQ     Source_Mode_An
    CMP.W   #2,A5
    BEQ     Source_Mode_IndirectAn
    CMP.W   #3,A5
    BEQ     Source_Mode_IndirectWithPlus
    CMP.W   #4,A5
    BEQ     Source_Mode_IndirectWithMinus
    CMP.W   #5,A5
    BEQ     BadOpcode
    CMP.W   #6,A5
    BEQ     BadOpcode
    CMP.W   #7,A5
    BEQ     Source_Mode_Abs_Or_Immediate    *Source mode is either absolute address or immediate addressing.

Source_Mode_Dn
    LEA     D_String,A1     *Print 'D' for Dn
    MOVE.B  #14,D0
    TRAP    #15
    JSR     FindSourceReg
    RTS
    
Source_Mode_An
    LEA     A_String,A1     *Print 'A' for An
    MOVE.B  #14,D0
    TRAP    #15   
    JSR     FindSourceReg 
    RTS

Source_Mode_IndirectAn
    LEA     Left_Par_String,A1      *Print ( then A for (An)
    MOVE.B  #14,D0
    TRAP    #15
    LEA     A_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
    
Source_Mode_IndirectWithPlus
    LEA     Left_Par_String,A1      *Print ( then A for (An)+
    MOVE.B  #14,D0
    TRAP    #15
    LEA     A_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     Plus_String,A1
    JSR     PrintInstruction
    RTS
    
Source_Mode_IndirectWithMinus 
    LEA     Minus_String,A1         *Print - then ( then A for -(An)
    MOVE.B  #14,D0
    TRAP    #15   
    LEA     Left_Par_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    LEA     A_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    JSR     FindSourceReg
    LEA     Right_Par_String,A1
    MOVE.B  #14,D0
    TRAP    #15

    RTS
    
Source_Mode_Abs_Or_Immediate
    MOVE.W  SourceReg,A5
    CMP.W   #0,A5         *Check if mode is absolute word
    BEQ     AbsoluteWord
    CMP.W   #1,A5         *Check if mode is absolute long
    BEQ     AbsoluteLong
    CMP.W   #4,A5         *Check if mode is immediate data
    BEQ     ImmediateData
    
AbsoluteWord
    LEA     Dollar_String,A1        *Print $ for absolute word address
    MOVE.B  #14,D0
    TRAP    #15
    *Get the next word of memory and print it
    JSR     GET_THE_ADDR_CONTENT_TO_D3
    JSR     HexToAscii
    RTS

AbsoluteLong
    LEA     Dollar_String,A1        *Print $ for absolute long address
    MOVE.B  #14,D0
    TRAP    #15
    *Get the next long of memory and print it
    MOVE.L  (A2)+,D4
    JSR     HEX_TO_ASCII_CHANGER_FULLSIZE
    RTS

ImmediateData
    LEA     Immediate_String,A1     *Print # for immediate data
    MOVE.B  #14,D0
    TRAP    #15
    JSR     PrintHexSymbol
    MOVE.W  D3,D5
    LSR.W   #8,D5
    LSR.W   #4,D5
    CMP.B   #%1101,D5
    BEQ     AddImmediateData
    CMP.B   #%1100,D5
    BEQ     MulsOrAndImmediateData
    CMP.B   #%1000,D5
    BEQ     DivuOrOrImmediateData
    MOVE.L  (A2)+,D4
    JSR     HEX_TO_ASCII_CHANGER_FULLSIZE

    RTS  
    
DivuOrOrImmediateData
    MOVE.W  DestMode,A5
    CMP.W   #3,A5
    BEQ     ImmediateWord
    
    BRA     OrImmediateData

OrImmediateData
    MOVE.W  Opmode,A5
    CMP.W   #0,A5
    BEQ     ImmediateByte
    CMP.W   #1,A5
    BEQ     ImmediateWord
    CMP.W   #2,A5
    BEQ     ImmediateLong
    CMP.W   #3,A5
    BEQ     ImmediateWord
    CMP.W   #4,A5
    BEQ     ImmediateByte
    CMP.W   #5,A5
    BEQ     ImmediateWord
    CMP.W   #6,A5
    BEQ     ImmediateLong
    
    BRA     ImmediateLong


MulsOrAndImmediateData
    MOVE.W  DestMode,A5
    CMP.W   #7,A5
    BEQ     ImmediateWord
    
    BRA     AndImmediateData
    
AndImmediateData
    MOVE.W  Opmode,A5
    CMP.W   #0,A5
    BEQ     ImmediateByte
    CMP.W   #1,A5
    BEQ     ImmediateWord
    CMP.W   #2,A5
    BEQ     ImmediateLong
    CMP.W   #3,A5
    BEQ     ImmediateWord
    CMP.W   #4,A5
    BEQ     ImmediateByte
    CMP.W   #5,A5
    BEQ     ImmediateWord
    CMP.W   #6,A5
    BEQ     ImmediateLong
    
    BRA     ImmediateLong
    
AddImmediateData
    MOVE.W  Opmode,A5
    CMP.W   #0,A5
    BEQ     ImmediateByte
    CMP.W   #1,A5
    BEQ     ImmediateWord
    CMP.W   #2,A5
    BEQ     ImmediateLong
    CMP.W   #3,A5
    BEQ     ImmediateWord
    CMP.W   #4,A5
    BEQ     ImmediateByte
    CMP.W   #5,A5
    BEQ     ImmediateWord
    CMP.W   #6,A5
    BEQ     ImmediateLong
    
    BRA     ImmediateLong
    
ImmediateByte
    MOVE.W      (A2)+,D5
    LEA         JumpHex,A4     	 * This instruction will load the address 
											 * of the JumpHex to the A4 
											 * register to enable the output of 
											 * ASCII characters. This will be
											 * used with displacement to determine 
											 * appropriate jump with offset
											 
    MOVE.B      D5,D3	                 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation. 
											 
    JSR         STORE_THIRD_NIBBLE_IN_D3     * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the first nibble 
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											 
    JSR         0(A4,D3)					 * Performs the jump to subroutine 
																						 
    MOVE.B      D5,D3	 * Reload the current four nibbles that 
											 * the disassembler is looking at to D3
											 * NOTE: At this stage D3 serves as a copy 
											 * that will be used for manipulations 
											 * to leave only specific bits that
											 * other subroutines will need for validation.
											 
    JSR         STORE_FOURTH_NIBBLE_IN_D3    * This instruction is a jump to a subroutine designed specifically for getting the second nibble     * This instruction is a jump to a
											 * subroutine designed specifically for 
											 * getting the second nibble which for our
											 * purposes in the HexToAScii											 * is the second left most HEX character 
											 * or value that must be converted
											 
    MULU        #6,D3						 * This instruction performs an unsigned
											 * multiplication on the left most HEX 
											 * character or value which we know from
											 * the previous comment is currently 
											 * stored in D3. This is done to prep it
											 * as a displacement offset for the 
											 * JSR command below. 
											
    JSR         0(A4,D3)					 * Performs the jump to subroutine to
											 * the JumpHex with the D3 
											 * as an offset to determine the 
											 * appropriate print out. 

    RTS
    
ImmediateWord
    JSR     GET_THE_ADDR_CONTENT_TO_D3
    JSR     HexToAscii
    RTS
    
ImmediateLong
    MOVE.L  (A2)+,D4
    JSR     HEX_TO_ASCII_CHANGER_FULLSIZE
    RTS

FindSourceReg
    MOVE.W  SourceReg,A5
    CMP.W   #0,A5         *Check for which function corresponds to the 3
    BEQ     Source_Reg_Zero         *source register bits and branch to it
    CMP.W   #1,A5
    BEQ     Source_Reg_One
    CMP.W   #2,A5
    BEQ     Source_Reg_Two
    CMP.W   #3,A5
    BEQ     Source_Reg_Three
    CMP.W   #4,A5
    BEQ     Source_Reg_Four
    CMP.W   #5,A5
    BEQ     Source_Reg_Five
    CMP.W   #6,A5
    BEQ     Source_Reg_Six
    CMP.W   #7,A5
    BEQ     Source_Reg_Seven
    
    
Source_Reg_Zero
    LEA     Zero_String,A1          *Print 0
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Source_Reg_One
    LEA     One_String,A1           *Print 1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS

Source_Reg_Two
    LEA     Two_String,A1           *Print 2
    MOVE.B  #14,D0
    TRAP    #15    
    RTS

Source_Reg_Three    
    LEA     Three_String,A1         *etc.
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Source_Reg_Four
    LEA     Four_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Source_Reg_Five
    LEA     Five_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS

Source_Reg_Six
    LEA     Six_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Source_Reg_Seven
    LEA     Seven_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS


FindDestMode
    MOVE.W  DestMode,A5
    CMP.W   #0,A5              *Check the 3 destination mode bits for which
    BEQ     Dest_Mode_Dn                *function and mode they correspond to
    CMP.W   #1,A5
    BEQ     Dest_Mode_An
    CMP.W   #2,A5
    BEQ     Dest_Mode_Indirect
    CMP.W   #3,A5
    BEQ     Dest_Mode_Indirect_Plus
    CMP.W   #4,A5
    BEQ     Dest_Mode_Indirect_Minus
    CMP.W   #5,A5
    BEQ     BadOpcode
    CMP.W   #6,A5
    BEQ     BadOpcode
    CMP.W   #7,A5
    BEQ     Dest_Mode_Absolute
    

Dest_Mode_Dn
    JSR     PrintDataRegister           *Print 'D' for Dn
    JSR     FindDestReg
    RTS

Dest_Mode_An
    JSR     PrintAddressRegister        *Print 'A' for An
    JSR     FindDestReg
    RTS

Dest_Mode_Indirect
    LEA     Left_Par_String,A1          *Print ( then A for (An)
    MOVE.B  #14,D0
    TRAP    #15
    JSR     PrintAddressRegister
    JSR     FindDestReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    RTS


Dest_Mode_Indirect_Plus
    LEA     Left_Par_String,A1          *Print ( then A for (An)+
    MOVE.B  #14,D0
    TRAP    #15
    JSR     PrintAddressRegister
    JSR     FindDestReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    LEA     Plus_String,A1
    JSR     PrintInstruction
    RTS


Dest_Mode_Indirect_Minus    
    LEA     Minus_String,A1             *Print - then ( then A for -(An)
    MOVE.B  #14,D0
    TRAP    #15
    LEA     Left_Par_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    JSR     PrintAddressRegister
    JSR     FindDestReg
    LEA     Right_Par_String,A1
    JSR     PrintInstruction
    RTS
    

Dest_Mode_Absolute
    LEA     Dollar_String,A1            *Print $ since it is absolute address
    MOVE.B  #14,D0
    TRAP    #15
    CMP.B   #%000,DestReg               *Check the register bits to see if it is
    BEQ     AbsoluteWord                *absolute word or absolute long and branch
    CMP.B   #%001,DestReg               *to the appropriate function
    BEQ     AbsoluteLong
    
    BRA     BadOpcode                   *Else branch to BadOpcode
    



FindDestReg
    MOVE.W  DestReg,A5
    CMP.W   #0,A5               *Check the 3 destination register bits to
    BEQ     Dest_Reg_Zero               *find which function and register they
    CMP.W   #1,A5               *correspond to and branch there
    BEQ     Dest_Reg_One
    CMP.W   #2,A5
    BEQ     Dest_Reg_Two
    CMP.W   #3,A5
    BEQ     Dest_Reg_Three
    CMP.W   #4,A5
    BEQ     Dest_Reg_Four
    CMP.W   #5,A5
    BEQ     Dest_Reg_Five
    CMP.W   #6,A5
    BEQ     Dest_Reg_Six
    CMP.W   #7,A5
    BEQ     Dest_Reg_Seven


Dest_Reg_Zero
    LEA     Zero_String,A1              *Print 0
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Dest_Reg_One
    LEA     One_String,A1               *Print 1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS

Dest_Reg_Two
    LEA     Two_String,A1               *Print 2
    MOVE.B  #14,D0
    TRAP    #15    
    RTS


Dest_Reg_Three
    LEA     Three_String,A1             *etc.
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Dest_Reg_Four
    LEA     Four_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Dest_Reg_Five
    LEA     Five_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS

Dest_Reg_Six
    LEA     Six_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
Dest_Reg_Seven
    LEA     Seven_String,A1
    MOVE.B  #14,D0
    TRAP    #15    
    RTS
    
   
* The OUTPUT_NOT subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the NOT instruction when 
 * there is only one subsequent operand. 
 ****
OUTPUT_NOT
    MOVE.W      FourNibbles,D3	
											 
    JSR         D3_STORE_NORM_SIZE			 * Jumps to the subroutine that will 
											 * manipulate the nibble to only store
											 * the bits for 4th and 5th bits 
											 * which typically indicate the size 
											 
    CMP         #%11,D3						 * Checks to see if a strange size suffix
											 * was indicated. 
											 
    BEQ         BadOpcode               * If there is one, then it's an invalid opcode
											 * as NOT may only use normal sizes of: 01,00,10
											 
    LEA         Not_String,A1                   * Loads the string for NOT for output
    JSR         PrintInstruction		* Prints the string loaded in A1		 * Prints the string loaded in A1 
    JSR         SUFFIX_OUTPUT_JMP			
											 
    MOVE.W      FourNibbles,D3	 
											 
    JSR         GetDestAndSource		* This subroutine will update the Destination Source Variable.           
											 * Destination Source Variable
											 
    JSR         FindSourceMode		* This subroutine will output the data mode source.		
											 * data mode source. 
											 
    BRA         GetNextOpCode			* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode.              * Branch to the subroutine for 
										     * checking the next word and parsing
											 * it to see if it's an OpCode.										 
    RTS			
   
   
 * The PrintNOP subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the NOP instruction when 
 * there are no subsequent operand(s). 
 ****
PrintNOP
    LEA         Nop_String,A1                   * Loads the string for NOP for output
    JSR         PrintInstruction	 * Prints the string loaded in A1 			 
    BRA         GetNextOpCode			* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode.              * Branch to the subroutine for 
										     * checking the next word and parsing
											 * it to see if it's an OpCode.
											 
    RTS										 * Return to the subroutine

 * The PrintAND subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the ADD instruction. 
 ****
PrintAND
    JSR         GetDestAndSource
    MOVE.W      SourceMode,A5
    CMP.W       #1,A5
    BEQ         BadOpcode
    MOVE.W      DestMode,A5
    CMP.W       #3,A5
    BEQ         BadOpcode
    CMP.W       #7,A5
    BEQ         BadOpcode
    LEA         And_String,A1						* Loads the string for AND for output
    JSR         PrintInstruction
    JSR         GetOpmode
    JSR         DecodeOpmode
    BRA         GetNextOpcode
    RTS
    *BRA         UTILITY_ADD_SUB_HANDLER  		
UTILITY_ADD_SUB_HANDLER
    JSR         PrintInstruction		* Prints the string loaded in A1
    JSR         SUFFIX_OUTPUT_JMP
    JSR         PrintSpace			* Invokes subroutine to print a space
    MOVE.W      FourNibbles,D3	* Reload the current four nibbles that 
											* the disassembler is looking at to D3
											* NOTE: At this stage D3 serves as a copy 
											* that will be used for manipulations 
											* to leave only specific bits that
											* other subroutines will need for validation.
    JSR         GetDestAndSource		* This subroutine will update the Destination Source Variable. 
    CMP         #0, SourceMode			* Checks to see if SOurMode is %000
    BNE         UTILITY_SUB_HANDLER         * If it's not then branch to the subroutine for unusual source modes
    JSR         FindSourceMode		* This subroutine will output the data mode source.
    JSR         PrintComma				* This invokes a subroutine that will output a comma
    JSR         PrintSpace		* Invokes subroutine to print a space
    JSR         PrintDataRegister				* Output the data registers 
    MOVE.W      DestReg, TemporaryVar	* Move the DEST_HOLDER to the temp var for manipulation 
    JSR         PrintRegNum
			
    BSR         CheckEnter			
    BRA         GetNextOpcode			
    RTS



******
 * The PrintRTS subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the RTS instruction when 
 * there are no subsequent operand(s). 
 ****
PrintRTS
    LEA         Rts_String ,A1                  * Loads the string for RTS for output
    JSR         PrintInstruction		* Prints the string loaded in A1
											 
    BRA         GetNextOpcode			* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode. 											 
    RTS										* Return to the subroutine
******
 * The CheckEnter subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * checking if the user is able to 
 * press enter yet. 
 ****
CheckEnter
    ADD         #1,D6					* D6 is used as the counter for number of 
										* statements printed out. 
    CMP         #30,D6 					* Since the screen is about 30 statements 
										* in height, then this counter needs 
										* to reach 30 before the user can press enter. 
    BEQ         PressEnter          	* If 30 has been reached let the user enter. 
    LEA         Space_String,A1			* If not then just print a string.
    MOVE        #13,D0					* Loads TRAP TASK #13
    TRAP        #15						* Execute TRAP TASK
    RTS									* Return to the subroutine


******
 * The PressEnter subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * allowing the user to press enter.
 * This will in turn allow the print out
 * of additional instructions to the screen.
 ****
PressEnter
    MOVE        #0,D6		* Reset the counter which is D6
    MOVE.B      #5,D0		* Load TRAP TASK #5	
    TRAP        #15			* Execute the TRAP TASK
    RTS						* Rerturn to the subroutine.


******
******
 * The PrintOr subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the ORI instruction when 
 * there are two subsequent opearnds 
 * This hasn't been implemented completely.
 ****
PrintOr    
    JSR         GetDestAndSource
    MOVE.W      SourceMode,A5
    CMP.W       #1,A5
    BEQ         BadOpcode
    MOVE.W      DestMode,A5
    CMP.W       #3,A5
    BEQ         BadOpcode
    CMP.W       #7,A5
    BEQ         BadOpcode
    LEA         Or_String,A1						* Loads the string for OR for output
    JSR         PrintInstruction
    JSR         GetOpmode
    JSR         DecodeOpmode
    BRA         GetNextOpcode
    RTS
    *BRA         UTILITY_ADD_SUB_HANDLER     * Since OR has a similar structure use the ADD_SUB helper	


UTILITY_SUB_HANDLER
    CLR         D7
    JSR         STORE_FOURTH_NIBBLE_IN_D3
    MOVE.W      D3,D7
    MOVE.W      FourNibbles,D3	
    JSR         GetDestAndSource		
    MOVE.W      DestReg,D3				
    MOVE.W      SourceReg,DestReg		* Move the source holder to destination holder
    MOVE.W      D3,SourceReg				* Move the old destination holder to the source holder. 
    MOVE.W      DestMode,D3			 
    MOVE.W      SourceMode,DestMode	
    MOVE.W      D3,SourceMode			
    MOVE.W      SourceMode, D3				
    MOVE.W      SourceReg, TemporaryVar        
    LSR         #2,D3							* Get rid of 2 Least Sig bits 
    CMP         #0,D3                           * All that should be left is the direction bits that show which order to output
    BEQ         REG_TO_MEM_SUB_UTILITY		* Invokes method that outputs info from registers to the memory 
    JSR         FindSourceReg              
    JSR         PrintComma				* This invokes a subroutine that will output a comma
    JSR         PrintSpace			* Invokes subroutine to print a space
    JSR         FindDestMode		* This method will output the data stored in the 12-7 bits
    BSR         EnterCheck		
    BRA         GetNextOpcode			
    RTS														* Return to the subroutine


 * The REG_TO_MEM_SUB_UTILITY subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * assisting in the assisting in the
 * output of information from the 
 * register to the memory. 
 ****
REG_TO_MEM_SUB_UTILITY
    MOVE.W      DestReg, TemporaryVar
    JSR         FindSourceMode		* This method will output the data stored in the 12-7 bits
    JSR         PrintComma				* This invokes a subroutine that will output a comma
    JSR         PrintSpace		* Invokes subroutine to print a space
    CMP         #$C,D7
    BNE         REG_TO_MEM_SUB_NON_IMM
    CLR         D7
    MOVE.W      DestReg, TemporaryVar
    BRA         REG_TO_MEM_SUB_NEXT

REG_TO_MEM_SUB_NON_IMM
    CLR         D7
    MOVE.W      SourceReg, TemporaryVar	* Save the variable to print out from register

REG_TO_MEM_SUB_NEXT    
    JSR         PrintDataRegister
    JSR         PrintRegNum				
    BSR         CheckEnter		
    BRA         GetNextOpcode			
    RTS  
  
  
  ******
 * The PrintRegNum subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the register number (An) or (Dn)
 * This subroutine has a precondition that
 * the register number was stored in the
 * UTILITY_VAR before executing this subroutine.
 * The Data Source or Data Destination may
 * invoke this subroutine. 
 ****
PrintRegNum
    LEA         JumpHex,A4    * This instruction will load the address 
										* of the JumpToHexto the A4 
										* register to enable the output of 
										* ASCII characters. This will be
										* used with displacement to determine 
										* appropriate jump with offset
										
    MOVE.W      TemporaryVar,D3			* Assuming that the register number
										* has been loaded into the temp var
										* move it to D3 for manipulation.
										
    MULU        #6,D3					* This instruction performs an unsigned
										* multiplication on the left most HEX 
										* character or value which we know from
										* the previous comment is currently 
										* stored in D3. This is done to prep it
										* as a displacement offset for the 
										* JSR command below. 
										
    JSR         0(A4,D3)				* Performs the jump to subroutine to
										* the JMPTABLE_HEX_CHAR with the D3 
										* as an offset to determine the 
										* appropriate print out. 
	
    CLR.W       TemporaryVar				* Clear the temp var for future use
    CLR.W       D3						* Clear the D3 register which is used
										* as a storage of the hex addresses.
    RTS									* Return to the subroutine

 
 * The PrintLEA subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the LEA instruction. 
 ****
PrintLEA
											
    JSR         GetDestAndSource		* This subroutine will update the Destination Source Variable. 			
											* Destination Source Variable. In this case now the
											* byte and word sizes will be printing out 4 spaces 
											* whereas a long size will print out 5 spaces.
    MOVE.W      DestMode,A5
    CMP.W       #7,A5
    BNE         BadOpcode
    MOVE.W      SourceMode,A5
    CMP.W       #0,A5
    BEQ         BadOpcode
    CMP.W       #1,A5
    BEQ         BadOpcode
    CMP.W       #3,A5
    BEQ         BadOpcode
    CMP.W       #4,A5
    BEQ         BadOpcode
    CMP.W       #5,A5
    BEQ         BadOpcode
    CMP.W       #6,A5
    BEQ         BadOpcode
    
    LEA         Lea_String,A1			* Loads the string for LEA for output
    JSR         PrintInstruction        * Prints the string loaded in A1		
    JSR         PrintSpace			                        * Invokes subroutine to print a space
    JSR         PrintSpace	

											
    JSR         FindSourceMode	                              *This subroutine will output the data mode source.
    JSR         PrintComma				* This invokes a subroutine that will output a comma		
    JSR         PrintSpace			* Invokes subroutine to print a space			
    JSR         PrintAddressRegister
    JSR         FindDestReg	
    
    BRA         GetNextOpcode			* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode
										    * checking the next word and parsing
											* it to see if it's an OpCode.
    RTS										* Return to the subroutine

  
Add
    JSR     GetDestAndSource
    JSR     GetOpmode
    MOVE.W  Opmode,A5
    CMP.W   #3,A5
    BEQ     AddAWord
    CMP.W   #7,A5
    BEQ     AddALong
    
    LEA     Add_String,A1
    JSR     PrintInstruction
    
    JSR     DecodeOpmode        *Find the correct opmode and find correct size.
                                *Also finds and prints the rest of the instruction
    
    BRA     GetNextOpcode
    
    RTS
    
AddAWord
    LEA     AddA_String,A1
    JSR     PrintInstruction
    JSR     PrintWord
    JSR     PrintSpace
    JSR     RestOfAddA
    
AddALong
    LEA     AddA_String,A1
    JSR     PrintInstruction
    JSR     PrintLong
    JSR     PrintSpace
    JSR     RestOfAddA
    
RestOfAddA
    JSR     FindSourceMode
    JSR     PrintComma
    JSR     PrintAddressRegister
    JSR     FindDestReg
    
    BRA     GetNextOpcode
    
    RTS
    

Sub    
    JSR     GetDestAndSource
    JSR     GetOpmode
    MOVE.W  Opmode,A5
    CMP.W   #3,A5
    BEQ     SubAWord
    CMP.W   #7,A5
    BEQ     SubALong

    LEA     Sub_String,A1
    JSR     PrintInstruction
    JSR     DecodeSubOpmode
    
    BRA     GetNextOpcode
    
    RTS
    
SubAWord
    LEA     SubA_String,A1
    JSR     PrintInstruction
    JSR     PrintWord
    JSR     PrintSpace
    JSR     RestOfSubA


SubALong
    LEA     SubA_String,A1
    JSR     PrintInstruction
    JSR     PrintLong
    JSR     PrintSpace
    JSR     RestOfSubA  
    
RestOfSubA
    JSR     FindSourceMode
    JSR     PrintComma
    JSR     PrintAddressRegister
    JSR     FindDestReg
    
    BRA     GetNextOpcode
    
    RTS
    
 
DecodeSubOpmode
    MOVE.W  Opmode,A5
    CMP.W   #0,A5
    BEQ     ByteEaFirst
    CMP.W   #1,A5
    BEQ     WordEaFirst
    CMP.W   #2,A5
    BEQ     LongEaFirst
    CMP.W   #4,A5
    BEQ     ByteDnFirst
    CMP.W   #5,A5
    BEQ     WordDnFirst
    CMP.W   #6,A5
    BEQ     LongDnFirst
    
    
    
GetOpmode
    *Get the word in data from D3 into D5
    MOVE.W  D3,D5
    LSL.W   #7,D5       *Shift 7 bits left then 13 bits right to get opmode
    LSR.W   #8,D5
    LSR.W   #5,D5     
    
    MOVE.W  D5,Opmode   *Put D5 into Opmode variable
    
    RTS

DecodeOpmode
    MOVE.W  Opmode,A5
    CMP.W   #0,A5
    BEQ     ByteEaFirst
    CMP.W   #1,A5
    BEQ     WordEaFirst
    CMP.W   #2,A5
    BEQ     LongEaFirst
    CMP.W   #4,A5
    BEQ     ByteDnFirst
    CMP.W   #5,A5
    BEQ     WordDnFirst
    CMP.W   #6,A5
    BEQ     LongDnFirst
    
ByteEaFirst
    JSR     PrintByte
    JSR     PrintSpace
    JSR     FindSourceMode
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindDestReg
    RTS

WordEaFirst
    JSR     PrintWord
    JSR     PrintSpace
    JSR     FindSourceMode
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindDestReg
    RTS

LongEaFirst
    JSR     PrintLong
    JSR     PrintSpace
    JSR     FindSourceMode
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindDestReg
    RTS

ByteDnFirst
    JSR     PrintByte
    JSR     PrintSpace
    JSR     PrintDataRegister
    JSR     FindDestReg
    JSR     PrintComma
    JSR     FindSourceMode
    RTS

WordDnFirst
    JSR     PrintWord
    JSR     PrintSpace
    JSR     PrintDataRegister
    JSR     FindDestReg
    JSR     PrintComma
    JSR     FindSourceMode
    RTS

LongDnFirst
    JSR     PrintLong
    JSR     PrintSpace
    JSR     PrintDataRegister
    JSR     FindDestReg
    JSR     PrintComma
    JSR     FindSourceMode
    RTS


AddQ
    LEA     AddQ_String,A1
    JSR     PrintInstruction
    JSR     GetDestAndSource
    JSR     FindAddQSize
    JSR     PrintSpace
    JSR     PrintImmediate
    JSR     FindImmediateData
    JSR     PrintComma
    JSR     FindSourceMode
    JSR     FindSourceReg
    
FindAddQSize
    MOVE.W  D3,D5
    LSL.W   #8,D5
    LSL.W   #6,D5
    CMP.B   #%00,D5
    BEQ     PrintByte
    CMP.B   #%01,D5
    BEQ     PrintWord
    CMP.B   #%10,D5
    BEQ     PrintLong

FindImmediateData
    CMP.B   #%000,DestReg
    BEQ     PrintHexEight
    CMP.B   #%001,DestReg
    BEQ     PrintHexOne
    CMP.B   #%010,DestReg
    BEQ     PrintHexTwo
    CMP.B   #%011,DestReg
    BEQ     PrintHexThree
    CMP.B   #%100,DestReg
    BEQ     PrintHexFour
    CMP.B   #%101,DestReg
    BEQ     PrintHexFive
    CMP.B   #%110,DestReg
    BEQ     PrintHexSix
    CMP.B   #%111,DestReg
    BEQ     PrintHexSeven
    

Muls
    JSR     GetDestAndSource
    MOVE.W  SourceMode,A5
    CMP.W   #1,A5
    BEQ     BadOpcode
    MOVE.W  DestMode,A5
    CMP.W   #7,A5
    BEQ     RestOfMuls
    
    BRA     BadOpcode
    
    RTS
    
RestOfMuls
    LEA     Muls_String,A1
    JSR     PrintInstruction
    JSR     PrintWord
    JSR     PrintSpace
    JSR     FindSourceMode
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindDestReg
    
    BRA     GetNextOpcode
    
    RTS
    
Divu
    JSR     GetDestAndSource
    MOVE.W  SourceMode,A5
    CMP.W   #1,A5
    BEQ     BadOpcode
    MOVE.W  DestMode,A5
    CMP.W   #3,A5
    BEQ     RestOfDivu
    
    BRA     BadOpcode
    
    RTS

RestOfDivu
    LEA     Divu_String,A1
    JSR     PrintInstruction
    JSR     PrintWord
    JSR     PrintSpace
    JSR     FindSourceMode
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindDestReg
    
    BRA     GetNextOpcode
    
    RTS

    

*******
 * The BEQ_OUTPUT subroutine: 
 * --------------------------------------
 * This function is responsible for 
 * outputting the BEQ instruction 
 * then shifting control depending 
 * on the size of the BEQ. 
 ****
BEQ_OUTPUT
    LEA         Beq_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    JSR         BranchSize

*******
 * The BGT_OUTPUT subroutine: 
 * --------------------------------------
 * This function is responsible for 
 * outputting the BGT instruction 
 * then shifting control depending 
 * on the size of the BGT. 
 ****
BGT_OUTPUT
    LEA         Bgt_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    JSR         BranchSize

*******
 * The BLE_OUTPUT subroutine: 
 * --------------------------------------
 * This function is responsible for 
 * outputting the BLE instruction 
 * then shifting control depending 
 * on the size of the BLE. 
 ****
BLE_OUTPUT
    LEA         Ble_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    JSR         BranchSize


*******
 * The BranchSize subroutine: 
 * --------------------------------------
 * Control flow depending on size
 * of the BRA or B(cc) it will
 * check the last 8-bits of the
 * first word to see what kinda 
 * branch it is.  
 ****
BranchSize
	MOVE.W      FourNibbles,D3	* Reload the current four nibbles that 
											* the disassembler is looking at to D3
											* NOTE: At this stage D3 serves as a copy 
											* that will be used for manipulations 
											* to leave only specific bits that
											* other subroutines will need for validation.    
											* Have to bring back full word before using D3_KEEP_THIRD_FOURTH_NIB
	JSR         D3_KEEP_THIRD_FOURTH_NIB      * Alter D3 to only have last 8-bits this will be used for finding the size
	CMP         #%00000000,D3                 * This is .W size since it will have last two nibbles be '00' to signal '.W'
	BEQ         BRANCH_WORD_SIZE_BRANCHCODE   * If it is .W size then branch to the subroutine that handles word size.
	CMP         #%11111111,D3                 * This is .L size since it will have last two nibbles be 'FF' to signal '.L'
	BEQ         BRANCH_LONG_SIZE_BRANCHCODE   * If it is .L size then branch to the subroutine that handles long size.
	BRA         BRANCH_BYTE_SIZE_BRANCHCODE   * If it isn't .L or .W then it's .B size, so we'll branch to that


******
 * The BRANCH_WORD_SIZE_BRANCHCODE subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the when BRA, B(cc) size is ' .W '
 ****
BRANCH_WORD_SIZE_BRANCHCODE
    JSR         PrintWord             * If it's not any of the above then it's '.B' size. Reusing OUTPUT_WORD_SUFFIX to print the '.W'  
    JSR         PrintSpace                      
    JSR         PrintHexSymbol				* Invokes subroutine to print '$'              * Print out the '$' symbol for the address 
    MOVE.L      A2,D4                          * Save the current address we are at
    JSR         D3_GET_NEXT_FOUR_NIB           * Get the displacement we are suppose to branch to
    ADD         D3,D4                          * Current address + displacement => address we are suppose to jump to
    MOVE.L      D4, FourNibbles  * Prepare the address to print out in hex
    JSR         HEX_TO_ASCII_CHANGER_FULLSIZE  * Output the 8 bit data field
    BRA         GetNextOpcode				* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode.

        ******
 * The HEX_TO_ASCII_CHANGER_FULLSIZE subroutine: 
 * --------------------------------------
 * This subroutine is responsible for changing
 * the HEX based stored values that will need
 * to be printed out at this current moment 
 * to ASCII. 
 * 
 * Typically this subroutine is invoked
 * to print out elements such as Address location, 
 * the Absolute short and long, immediate data, 
 * among other elements. 
 *
 * This subroutine will print one nibble (4-bits)
 * at a time while printing out 4 nibbles in total 
 * or about (16 bits). 
 ****
HEX_TO_ASCII_CHANGER_FULLSIZE					
    MOVE.L      D4,FourNibbles     * Copy the long address in its entirety 
    JSR         HexToAscii			* Output the 8 bit data field
    MOVE.W      D4,FourNibbles	* Copy the long address in its entirety 
    JSR         HexToAscii	* Output the 8 bit data field
    JSR         PrintSpace			* Invokes subroutine to print a space
    RTS

******
 * The BRANCH_LONG_SIZE_BRANCHCODE subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the when BRA, B(cc) size is ' .L '
 ****
BRANCH_LONG_SIZE_BRANCHCODE
    JSR         PrintWord       * If it's not any of the above then it's '.B' size. Reusing OUTPUT_WORD_SUFFIX to print the '.W'
    JSR         PrintSpace                        
    JSR         PrintHexSymbol			* Invokes subroutine to print '$'        * Print out the '$' symbol for the address 
    MOVE.L      A2,D4                    * Save the current address we are at
    JSR         D3_GET_NEXT_FOUR_NIB     * Get the first word displacement we are suppose to branch to
    ADD         D3,D4                    * Current address + displacement => address we are suppose to jump to
    JSR         D3_GET_NEXT_FOUR_NIB     * Get the second word displacement we are suppose to branch to
    ADD         D3,D4                    * Current address + displacement => address we are suppose to jump to
    MOVE.L      D4,FourNibbles  * Prepare the address to print out in hex
    JSR         HEX_TO_ASCII_CHANGER_FULLSIZE * Output the 8 bit data field
    BRA         GetNextOpcode				* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode.

******
 * The BRANCH_BYTE_SIZE_BRANCHCODE subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the when BRA, B(cc) size is ' .B '
 ****
BRANCH_BYTE_SIZE_BRANCHCODE        
    JSR         PrintByte       * If it's not any of the above then it's '.B' size. Reusing OUTPUT_WORD_SUFFIX to print the '.W'
    JSR         PrintSpace                        
    JSR         PrintHexSymbol	 * Print out the '$' symbol for the address 
    MOVE.L      A2,D4                    * Save the current address we are at
    BRA         NEGATIVE_DISPLACEMENT_CHECK   * Check if the displacement on last two nibbles is negative 

******
 * The NEGATIVE_DISPLACEMENT_CHECK subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * checking if THIRD_AND_FOURTH_NIBBLE are negative
 ****
NEGATIVE_DISPLACEMENT_CHECK
    CMP.W       #$FF,D3                    * If it's greater than #$FF then it's invalid
    BGT         BadOpcode
    CMP.W       #$80,D3                    * Check if it's less than #$80 if it is then it's not negative
    BLT         ADD_THE_BRANCH_DISPLACEMENT
    CMP.W       #$80,D3                    * Check if it's greater than #$80 if it is then it's NEGATIVE 
    BGE         HANDLING_NEGATIVE_DISPLACEMENT
        
******
 * The NEGATIVE_DISPLACEMENT_CHECK subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * handling when 8-bit displacement is negative
 * or 80 to FF
 ****
HANDLING_NEGATIVE_DISPLACEMENT
    NOT.B       D3       * Ones complement
    ADDQ.W      #1,D3    * Make it a twos complement
    SUB         D3,D4    * Current address + displacement => address we are suppose to jump to
    MOVE.L      D4, FourNibbles  * Prepare the address to print out in hex
    JSR         HEX_TO_ASCII_CHANGER_FULLSIZE	* Output the 8 bit data field
    BRA         GetNextOpcode				* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode. 

******
 * The ADD_THE_BRANCH_DISPLACEMENT subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * printing the address for normal .B 
 * displacement for the BRA and B(cc)
 ****
ADD_THE_BRANCH_DISPLACEMENT
    ADD         D3,D4                          * Current address + displacement => address we are suppose to jump to
    MOVE.L      D4, FourNibbles   * Prepare the address to print out in hex
    JSR         HEX_TO_ASCII_CHANGER_FULLSIZE  * Output the 8 bit data field
    BRA         GetNextOpcode			* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode.

*******
 * Get the third and fourth nibbles from the left
 * Used to get the size of the Bcc and BRA opcodes.
 ******
D3_KEEP_THIRD_FOURTH_NIB
        LSL                        #8,D3
        LSR                        #8,D3
        RTS

*****
 * The JumpHex subroutine:
 * ---------------------
 * This subroutine will output 
 * the valid hexadecimal characters 
 ***
JumpHex
    JMP         PrintHexZero
    JMP         PrintHexOne
    JMP         PrintHexTwo
    JMP         PrintHexThree
    JMP         PrintHexFour
    JMP         PrintHexFive
    JMP         PrintHexSix
    JMP         PrintHexSeven
    JMP         PrintHexEight
    JMP         PrintHexNine
    JMP         PrintHexA
    JMP         PrintHexB
    JMP         PrintHexC
    JMP         PrintHexD
    JMP         PrintHexE
    JMP         PrintHexF

PrintHexZero
    LEA         Zero_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexOne    
    LEA         One_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexTwo
    LEA         Two_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexThree    
    LEA         Three_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexFour    
    LEA         Four_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexFive    
    LEA         Five_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexSix
    LEA         Six_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexSeven
    LEA         Seven_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexEight
    LEA         Eight_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexNine    
    LEA         Nine_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexA
    LEA         A_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexB    
    LEA         B_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexC    
    LEA         C_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexD    
    LEA         D_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexE    
    LEA         E_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS

PrintHexF
    LEA         F_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS
*******
 * The PrintSourceMode subroutine: 
 * --------------------------------------
 * This function is responsible for 
 * outputting the data stored in the 
 * last six bits of the OpCode word. 
 *
PrintSourceMode        
    LEA         FindSourceMode,A6	
    MOVE.W      SourceReg, TemporaryVar	    * Stores the SourceReg in the temp var for arithmetic 
    MOVE        SourceMode,D3			
    MULU        #6,D3							* Multiply unsigned by D3 to use it as an offset for JSR		
    JSR         0(A6,D3)       					* Go to the jump table with appropraite offset to find the source mode
    RTS


PrintSpace
    LEA     Space_String,A1         *Print a space ' '
    MOVE.B  #14,D0
    TRAP    #15
    RTS
    
PrintComma
    LEA     Comma,A1                *Print a comma ','
    MOVE.B  #14,D0
    TRAP    #15
    RTS
    
PrintSlash
    LEA     Slash_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS
    
PrintInstruction
    MOVE.B  #14,D0                  *Print the string currently in A1
    TRAP    #15
    RTS
    
PrintHexSymbol
    LEA     Dollar_String,A1        *Print $ for hexadecimal values
    MOVE.B  #14,D0
    TRAP    #15
    RTS
    
PrintDataRegister
    LEA     D_String,A1             *Print D for Dn
    MOVE.B  #14,D0
    TRAP    #15
    RTS

PrintAddressRegister
    LEA     A_String,A1             *Print A for An
    MOVE.B  #14,D0
    TRAP    #15
    RTS

PrintByte
    LEA     Byte_String,A1          *Print .B for byte size operations
    MOVE.B  #14,D0
    TRAP    #15
    RTS
    
PrintWord
    LEA     Word_String,A1          *Print .W for word size operations
    MOVE.B  #14,D0
    TRAP    #15
    RTS    

PrintLong
    LEA     Long_String,A1          *Print .L for long size operations
    MOVE.B  #14,D0
    TRAP    #15
    RTS
    
PrintImmediate
    LEA     Immediate_String,A1
    MOVE.B  #14,D0
    TRAP    #15
    RTS

*******
 * The Logical_Shift subroutine: 
 * --------------------------------------
 * This function is responsible for 
 * outputting for the logical shift
 * when there is only one operand 
 * for memory <ea> 
 ****
Logical_Shift
    JSR         GetDestAndSource
    MOVE.W      DestMode,A5
    MOVE.W      A5,D5
    LSL.W       #8,D5
    LSL.W       #6,D5
    LSR.W       #8,D5
    LSR.W       #6,D5
    CMP.B       #3,D5
    BEQ         CheckShiftMem
    
    BRA         CheckShiftReg
    
CheckShiftMem
    MOVE.W      DestReg,A5
    MOVE.W      A5,D5
    LSL.W       #8,D5
    LSL.W       #7,D5
    LSR.W       #8,D5
    LSR.W       #7,D5
    CMP.B       #0,D5
    BEQ         ArithShift
    
    BRA         LogShift
    
CheckShiftReg
    MOVE.W      SourceMode,A5
    MOVE.W      A5,D5
    LSL.W       #8,D5
    LSL.W       #7,D5
    LSR.W       #8,D5
    LSR.W       #7,D5
    CMP.B       #0,D5
    BEQ         ArithShift
    
    BRA         LogShift

    
LogShift
    LEA         Log_Shift,A1					* Loads the string for 'LS'
    JSR         GetDestAndSource
    MOVE.W      DestMode,A5
    MOVE.W      A5,D5
    LSR.W       #2,D5
    CMP.W       #0,D5
    BEQ         ShiftRight
    CMP.W       #1,D5
    BEQ         ShiftLeft
    *JSR         Shift_Check	                    * Invokes the utility function for ASD LSD and ROD shifts	
    RTS

ArithShift
    LEA         As_String,A1					* Loads the string for 'LS'
    JSR         GetDestAndSource
    MOVE.W      DestMode,A5
    MOVE.W      A5,D5
    LSR.W       #2,D5
    CMP.W       #0,D5
    BEQ         ShiftRight
    CMP.W       #1,D5
    BEQ         ShiftLeft
    *JSR         Shift_Check	                    * Invokes the utility function for ASD LSD and ROD shifts	
    RTS


ShiftRight
    JSR     PrintInstruction
    LEA     Right_String,A1
    JSR     PrintInstruction
    JSR     FindShiftSize
    CMP.B   #3,D5
    BEQ     MemoryShift
    
    BRA     RestOfLogShift

ShiftLeft    
    JSR     PrintInstruction
    LEA     Left_String,A1
    JSR     PrintInstruction
    JSR     FindShiftSize
    CMP.B   #3,D5
    BEQ     MemoryShift
    
    BRA     RestOfLogShift
    
FindShiftSize
    MOVE.W  DestMode,A5
    MOVE.W  A5,D5
    LSL.W   #8,D5
    LSL.W   #6,D5
    LSR.W   #8,D5
    LSR.W   #6,D5
    CMP.B   #0,D5
    BEQ     PrintByte
    CMP.B   #1,D5
    BEQ     PrintWord
    CMP.B   #2,D5
    BEQ     PrintLong

    RTS 
    
RestOfLogShift
    MOVE.W  SourceMode,A5
    MOVE.W  A5,D5
    LSR.W   #2,D5
    CMP.B   #0,D5
    BEQ     Immediate_Shift
    CMP.B   #1,D5
    BEQ     Register_Shift
    
Immediate_Shift
    JSR     PrintSpace
    JSR     PrintImmediate
    JSR     PrintHexSymbol
    MOVE.W  DestReg,A5
    CMP.W   #0,A5
    BEQ     EightShift
    
    JSR     FindDestReg
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindSourceReg
    
    BRA     GetNextOpcode
    
    RTS
    
EightShift
    JSR     PrintHexEight
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindSourceReg
    
    BRA     GetNextOpcode
    
    RTS
    
Register_Shift
    JSR     PrintSpace
    JSR     PrintDataRegister
    JSR     FindDestReg
    JSR     PrintComma
    JSR     PrintDataRegister
    JSR     FindSourceReg
    
    BRA     GetNextOpcode
    
    RTS
    
MemoryShift
    JSR     PrintWord
    JSR     PrintSpace
    JSR     FindSourceMode
    
    BRA     GetNextOpcode
    
    RTS    
    
    
Arithmetic_Shift
    LEA         As_String,A1					* Loads the string for 'AS'
    JSR         Shift_Check                 	* Invokes the utility function for ASD LSD and ROD shifts
    RTS   
    
Shift_Check
    JSR         PrintInstruction		    * Prints the string loaded in A1
    LEA         Right_Or_Left,A6          * Print the direction, left or right
	MOVE.W      FourNibbles,D3	* Reload the current four nibbles that 
											* the disassembler is looking at to D3
											* NOTE: At this stage D3 serves as a copy 
											* that will be used for manipulations 
											* to leave only specific bits that
											* other subroutines will need for validation.
    JSR         GetDestAndSource		* This subroutine will update the Destination Source Variable. 
    JSR         STORE_SECOND_NIBBLE_IN_D3   * This instruction is a jump to a subroutine designed specifically for getting the second nibble 
    LSL         #8,D3
    LSL         #7,D3
    LSR         #7,D3
    LSR         #8,D3
    MULU        #6,D3
    JSR         0(A6,D3)                    * Jumps to the subroutine with appropriate offset to determine output left or right
    JSR         OUTPUT_WORD_SIZE_USUAL		* Jumps to the subroutine for handling word size in general instances. 
    MOVE.W      SourceReg, TemporaryVar     * Save the variable of register number to print out from register
    JSR         FindSourceMode		* This subroutine will output the data mode source.
    BSR         CheckEnter			        * Branch to the Check_Enter subroutine to see if a new screen of more output is ready.
    BRA         GetNextOpcode				* Branch to the subroutine for checking the next word and parsing it to see if it's an OpCode.
    RTS

Right_Or_Left
    JMP         Print_Right
    JMP         Print_Left
    
Print_Right
    LEA         Right_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS     

Print_Left
    LEA         Left_String,A1
    JSR         PrintInstruction		* Prints the string loaded in A1
    RTS
    
    
    ******
 * The SUFFIX_OUTPUT_JMP subroutine: 
 * --------------------------------------
 * This subroutine is responsible for 
 * outputting the suffix that reflects
 * the size stored in the OpCode. 
 * It uses the typical format that stores
 * the size in the typical area which is 
 * the first 2 bits of the third nibble
 * or bits 4-5 of the word. 
 *
 * NOTE: Byte (00), Word (01), Long (10)
 ****
SUFFIX_OUTPUT_JMP
    MOVE.W      FourNibbles,D3	    * Reload the current four nibbles that 
												* the disassembler is looking at to D3
												* NOTE: At this stage D3 serves as a copy 
												* that will be used for manipulations 
												* to leave only specific bits that
												* other subroutines will need for validation.
												
    JSR         D3_STORE_NORM_SIZE				* Jumps to the subroutine that will 
												* manipulate the nibble to only store
												* the bits for 4th and 5th bits 
												* which typically indicate the size 
												* In this case we're trying to find 
												* the size of the operation in order
												* to find out how how many bytes
												* the disassembler should advance by.
												
    LEA         JMPTABLE_USUAL_CASE_SIZE,A4     * This instruction will load the address 
											    * of the JMPTABLE_USUAL_CASE_SIZE to the A4 
											    * register to enable the output of 
											    * the right size. This will be
											    * used with displacement to determine 
											    * appropriate jump with offset
												
    CMP         #%11,D3                         * Checks to see if a strange size suffix
												* was indicated. In this typical instance #%11 isn't used. 
												
    BEQ         BadOpcode					* If there is one, then it's an invalid opcode
											    * as NOT may only use normal sizes of: 01,00,10
												
    MULU        #6,D3							* This instruction performs an unsigned
												* multiplication on the left most HEX 
												* character or value which we know from
												* the previous comment is currently 
												* stored in D3. This is done to prep it
												* as a displacement offset for the 
												* JSR command below. 
												
    JSR         0(A4,D3)                        * Performs the jump to subroutine to
												* the JMPTABLE_USUAL_CASE_SIZE with the D3 
												* as an offset to determine the 
												* appropriate print out. 
    RTS	

JMPTABLE_USUAL_CASE_SIZE
    JMP         PrintByte
    JMP         PrintWord
    JMP         PrintLong
    JMP         BadOpcode

				
****
 * The D3_STORE_NORM_SIZE subroutine:
 * ---------------------
 * This subroutine is responsible for 
 * finding the size of the OpCode and 
 * done for most cases where this info
 * is stored in the first 2 bits of the
 * third nibble of the opcode. 
 ***
D3_STORE_NORM_SIZE
    JSR         GetDestAndSource			* This subroutine will update the Destination Source Variable. 
    MOVE.W      DestMode,D3			* Stores the DEST_MODE_VAR in D3 for arithmetic 	
    LSL         #8,D3
    LSL         #6,D3
    LSR         #8,D3
    LSR         #6,D3
    RTS



******
 *	This subroutine is used to 
 * 	clear all variabels and registers
 *	so that a restart can occur cleanly.
 ****
CLEANING
    CLR.L       D0
    CLR.L       D1
    CLR.L       D2
    CLR.L       D3
    CLR.L       D4
    CLR.L       D5
    CLR.L       D6
    CLR.L       D7
    MOVEA.L     #0,A0
    MOVEA.L     #0,A1
    MOVEA.L     #0,A2
    MOVEA.L     #0,A3
    MOVEA.L     #0,A4
    MOVEA.L     #0,A5
    MOVEA.L     #0,A6
    MOVEA.L     #0,A7
    CLR.L       BEGINNING_ADDRESS
    CLR.L       FINISHING_ADDRESS
    CLR.L       $200
    CLR.L       DestReg
    CLR.L       DestMode
    CLR.L       SourceMode
    CLR.L       SourceReg
    CLR.L       A1_COPY_ONE
    CLR.L       A1_COPY_TWO
    BRA         GET_BEGIN_ADDR


    SIMHALT             ; halt simulator
    

* Put variables and constants here
*------------------------------------

CR EQU $0D
LF EQU $0A

Space_String            DC.W        ' ',0		* Used for formatting
Comma                   DC.W        ',',0       *String for comma
Slash_String            DC.W        '/',0       *String for slash


Byte_String             DC.W        '.B',0      *String for instructions operating on byte.
Word_String             DC.W        '.W',0      *String for instructions operating on word
Long_String             DC.W        '.L',0      *String for instructions operating on long

Move_String             DC.W        'MOVE',0    *String for Move instruction
MoveQ_String            DC.W        'MOVEQ',0   *String for MoveQ instruction
MoveM_String            DC.W        'MOVEM',0   *String for MoveM instruction
MoveA_String            DC.W        'MOVEA',0   *String for MoveA instruction

Add_String              DC.W        'ADD',0     *String for Add instruction
AddA_String             DC.W        'ADDA',0    *String for AddA instruction
AddQ_String             DC.W        'ADDQ',0    *String for AddQ instruction

Sub_String              DC.W        'SUB',0     *String for Sub instruction
SubA_String             DC.W        'SUBA',0    *String for SubA instruction

Muls_String             DC.W        'MULS',0    *String for MULS instruction
Divu_String             DC.W        'DIVU',0    *String for DIVU instruction

Lea_String              DC.W        'LEA',0     *String for LEA instruction

And_String              DC.W        'AND',0     *String for And instruction
Or_String               DC.W        'OR',0      *String for Or instruction
Not_String              DC.W        'NOT',0     *String for Not instruction

Log_Shift               DC.W        'LS',0      *String for LSL,LSR 
Left_String             DC.W        'L',0     *String for LSL instruction
Right_String            DC.W        'R',0     *String for LSR instruction
As_String               DC.W        'AS',0      *String for ASL, ASR

Rol_String              DC.W        'ROL',0     *String for ROL instruction
Ror_String              DC.W        'ROR',0     *String for ROR instruction

Bgt_String              DC.W        'BGT',0     *String for BGT instruction
Ble_String              DC.W        'BLE',0     *String for BLE instruction
Beq_String              DC.W        'BEQ',0     *String for BEQ instruction

Jsr_String              DC.W        'JSR',0     *String for JSR instruction
Rts_String              DC.W        'RTS',0     *String for RTS instruction

Bra_String              DC.W        'BRA',0     *String for BRA instruction

Nop_String              DC.W        'NOP',0     *String for NOP instruction

Dollar_String           DC.W        '$',0       *String for dollar sign (hex symbol)
Immediate_String        DC.W        '#',0       *String for immediate data (pound sign)

Zero_String             DC.W        '0',0       *String for the number 0
One_String              DC.W        '1',0       *String for the number 1
Two_String              DC.W        '2',0       *String for the number 2
Three_String            DC.W        '3',0       *String for the number 3
Four_String             DC.W        '4',0       *String for the number 4
Five_String             DC.W        '5',0       *String for the number 5
Six_String              DC.W        '6',0       *String for the number 6
Seven_String            DC.W        '7',0       *String for the number 7
Eight_String            DC.W        '8',0       *String for the number 8
Nine_String             DC.W        '9',0       *String for the number 9

A_String                DC.W        'A',0       *String for letter A
B_String                DC.W        'B',0       *String for letter B
C_String                DC.W        'C',0       *String for letter C
D_String                DC.W        'D',0       *String for letter D
E_String                DC.W        'E',0       *String for letter E
F_String                DC.W        'F',0       *String for letter F

Plus_String             DC.W        '+',0       *String for plus sign
Minus_String            DC.W        '-',0       *String for minus sign
Left_Par_String         DC.W        '(',0       *String for left parantheses
Right_Par_String        DC.W        ')',0       *String for right parantheses

Data_String             DC.W        'DATA',0    *String for when opcode is invalid


GET_START_ADDR          DC.W        'Please enter starting address:',0
GET_END_ADDR            DC.W        'Please enter ending address:', 0
BAD_INPUT_MSG           DC.W        'INVALID_OPCODE ADDRESS ENTERED',0
ENDING_P1       		DC.B        'The given range has been parsed.',CR, LF
                        DC.W        'Please enter 0 to end the program or 1 to restart the program.',CR, LF,0

INVALID_ENDING          DC.W        'The given value is not 0 or 1. Please try again.',0

    END    START        ; last line of source
    
    start		EQU	$00009000	* ORG and END address

* ORG the program so that it straddles the address boundary $00007FFF to $00008000

		ORG	start

    NOP
    RTS
    NOP
    RTS
    LEA     (A0),A0
    LEA     (A5),A0
    LEA     (A7),A0
    LEA     (A0),A7
    LEA     (A5),A7
    LEA     (A7),A7
    MOVE.B    D0,D1
    MOVE.B    D0,(A0)
    MOVE.B    D0,(A0)+
    MOVE.B    D0,-(A0)
    MOVE.B    (A0),D0
    MOVE.B    (A0),(A1)
    MOVE.B    (A0),(A1)+
    MOVE.B    (A0),-(A1)
    MOVE.B    (A0)+,D0
    MOVE.B    (A0)+,(A1)
    MOVE.B    (A0)+,(A1)+
    MOVE.B    (A0)+,-(A1)
    MOVE.B    -(A0),D0
    MOVE.B    -(A0),(A1)
    MOVE.B    -(A0),(A1)+
    MOVE.B    -(A0),-(A1)
    MOVE.W    D0,D1
    MOVE.W    D0,(A0)
    MOVE.W    D0,(A0)+
    MOVE.W    D0,-(A0)
    MOVE.W    A0,D0
    MOVE.W    A0,(A1)
    MOVE.W    A0,(A1)+
    MOVE.W    A0,-(A1)
    MOVE.W    (A0),D0
    MOVE.W    (A0),(A1)
    MOVE.W    (A0),(A1)+
    MOVE.W    (A0),-(A1)
    MOVE.W    (A0)+,D0
    MOVE.W    (A0)+,(A1)
    MOVE.W    (A0)+,(A1)+
    MOVE.W    (A0)+,-(A1)
    MOVE.W    -(A0),D0
    MOVE.W    -(A0),(A1)
    MOVE.W    -(A0),(A1)+
    MOVE.W    -(A0),-(A1)
    MOVE.L    D0,D1
    MOVE.L    D0,(A0)
    MOVE.L    D0,(A0)+
    MOVE.L    D0,-(A0)
    MOVE.L    A0,D0
    MOVE.L    A0,(A1)
    MOVE.L    A0,(A1)+
    MOVE.L    A0,-(A1)
    MOVE.L    (A0),D0
    MOVE.L    (A0),(A1)
    MOVE.L    (A0),(A1)+
    MOVE.L    (A0),-(A1)
    MOVE.L    (A0)+,D0
    MOVE.L    (A0)+,(A1)
    MOVE.L    (A0)+,(A1)+
    MOVE.L    (A0)+,-(A1)
    MOVE.L    -(A0),D0
    MOVE.L    -(A0),(A1)
    MOVE.L    -(A0),(A1)+
    MOVE.L    -(A0),-(A1)
    MOVEM.W   A1-A7,-(A1)
    MOVEM.L   D1-D7,-(A1)
    MOVEM.W   A1/D7,-(A1)
    MOVEM.L   A1/D7,-(A1)
    MOVEM.W   A1-A7,(A1)
    MOVEM.L   D1-D7,(A1)
    MOVEM.W   A1/D7,(A1)
    MOVEM.L   A1/D7,(A1)
    MOVEM.W   (A1)+,A1-A7
    MOVEM.L   (A1)+,D1-D7
    MOVEM.W   (A1)+,A1/D7
    MOVEM.L   (A1)+,A1/D7
    MOVEM.W   (A1),A1-A7
    MOVEM.L   (A1),D1-D7
    MOVEM.W   (A1),A1/D7
    MOVEM.L   (A1),A1/D7
    MOVEA.W    D0,A0
    MOVEA.W    A0,A0
    MOVEA.W    (A0),A0
    MOVEA.W    (A0)+,A0
    MOVEA.W    -(A0),A0
    MOVEA.L    D0,A0
    MOVEA.L    A0,A0
    MOVEA.L    (A0),A0
    MOVEA.L    (A0)+,A0
    MOVEA.L    -(A0),A0  
    ADD.B     D1,D2
    ADD.B     D1,(A1)
    ADD.B     D1,(A1)+
    ADD.B     D1,-(A1)
    ADD.B     (A1),D1
    ADD.B     (A1)+,D1
    ADD.B     -(A1),D1
    ADD.W     D1,D2
    ADD.W     D1,(A1)
    ADD.W     D1,(A1)+
    ADD.W     D1,-(A1)
    ADD.W     (A1),D1
    ADD.W     (A1)+,D1
    ADD.W     -(A1),D1
    ADD.L     D1,D2
    ADD.L     D1,(A1)
    ADD.L     D1,(A1)+
    ADD.L     D1,-(A1)
    ADD.L     (A1),D1
    ADD.L     (A1)+,D1
    ADD.L     -(A1),D1
    ADDA.W        D1,A2
    ADDA.W        (A1),A2
    ADDA.W        (A1)+,A2
    ADDA.W        -(A1),A2
    ADDA.L        D1,A2
    ADDA.L        (A1),A2
    ADDA.L        (A1)+,A2
    ADDA.L        -(A1),A2
    SUB.B     D1,D2
    SUB.B     D1,(A1)
    SUB.B     D1,(A1)+
    SUB.B     D1,-(A1)
    SUB.B     (A1),D1
    SUB.B     (A1)+,D1
    SUB.B     -(A1),D1
    SUB.W     D1,D2
    SUB.W     D1,A1
    SUB.W     D1,(A1)
    SUB.W     D1,(A1)+
    SUB.W     D1,-(A1)
    SUB.W     A1,D1
    SUB.W     (A1),D1
    SUB.W     (A1)+,D1
    SUB.W     -(A1),D1
    SUB.L     D1,D2
    SUB.L     D1,A1
    SUB.L     D1,(A1)
    SUB.L     D1,(A1)+
    SUB.L     D1,-(A1)
    SUB.L     A1,D1
    SUB.L     (A1),D1
    SUB.L     (A1)+,D1
    SUB.L     -(A1),D1    
    MULS.W    D0,D1
    MULS.W    (A0),D1
    MULS.W    -(A0),D1
    MULS.W    (A0)+,D1
    DIVU.W    D0,D1
    DIVU.W    (A0),D1
    DIVU.W    -(A0),D1
    DIVU.W    (A0)+,D1
    AND.B     D1,D2
    AND.B     D1,(A1)
    AND.B     D1,(A1)+
    AND.B     D1,-(A1)
    AND.B     (A1),D1
    AND.B     (A1)+,D1
    AND.B     -(A1),D1
    AND.W     D1,D2
    AND.W     D1,(A1)
    AND.W     D1,(A1)+
    AND.W     D1,-(A1)
    AND.W     (A1),D1
    AND.W     (A1)+,D1
    AND.W     -(A1),D1
    AND.L     D1,D2
    AND.L     D1,(A1)
    AND.L     D1,(A1)+
    AND.L     D1,-(A1)
    AND.L     (A1),D1
    AND.L     (A1)+,D1
    AND.L     -(A1),D1
    OR.B     D1,D2
    OR.B     D1,(A1)
    OR.B     D1,(A1)+
    OR.B     D1,-(A1)
    OR.B     (A1),D1
    OR.B     (A1)+,D1
    OR.B     -(A1),D1
    OR.W     D1,D2
    OR.W     D1,(A1)
    OR.W     D1,(A1)+
    OR.W     D1,-(A1)
    OR.W     (A1),D1
    OR.W     (A1)+,D1
    OR.W     -(A1),D1
    OR.L     D1,D2
    OR.L     D1,(A1)
    OR.L     D1,(A1)+
    OR.L     D1,-(A1)
    OR.L     (A1),D1
    OR.L     (A1)+,D1
    OR.L     -(A1),D1
    LSL.B     D1,D2
    LSL.W     D1,D2
    LSL.W     (A1)
    LSL.W     (A1)+
    LSL.W     -(A1)
    LSL.L     D1,D2
    LSR.B     D1,D2
    LSR.W     D1,D2
    LSR.W     (A1)
    LSR.W     (A1)+
    LSR.W     -(A1)
    LSR.L     D1,D2    
    ASR.B     D1,D2
    ASR.W     D1,D2
    ASR.W     (A1)
    ASR.W     (A1)+
    ASR.W     -(A1)
    ASR.L     D1,D2
    ASL.B     D1,D2
    ASL.W     D1,D2
    ASL.W     (A1)
    ASL.W     (A1)+
    ASL.W     -(A1)
    ASL.L     D1,D2  
    BGT.B     label1
    BGT.B     label2
    BLE.B     label1
    BLE.B     label2
    BGE.B     label1
    BEQ.B     label2
    BEQ.W     label1
    JSR       (A0)
    JSR       $1234
    JSR       $12345678
    JSR       label1
    JSR       label2
    JSR       label3
    NOP
    RTS
label1
    NOP
    RTS
    LEA       $12,A0
    LEA       $1234,A0
    LEA       $12345678,A0
label2
    MOVEQ     #$0,D0
    MOVEQ     #$12,D0
    MOVEQ     #$FF,D0
label3
    MOVEM.W   A1-A7,$12
    MOVEM.L   D1-D7,$12
    MOVEM.W   A1/D7,$12
    MOVEM.L   A1/D7,$12
    MOVEM.W   A1-A7,$1234
    MOVEM.L   D1-D7,$1234
    MOVEM.W   A1/D7,$1234
    MOVEM.L   A1/D7,$1234
    MOVEM.W   A1-A7,$12345678
    MOVEM.L   D1-D7,$12345678
    MOVEM.W   A1/D7,$12345678
    MOVEM.L   A1/D7,$12345678
    MOVEM.W   $12,A1-A7
    MOVEM.L   $12,D1-D7
    MOVEM.W   $12,A1/D7
    MOVEM.L   $12,A1/D7
    MOVEM.W   $1234,A1-A7
    MOVEM.L   $1234,D1-D7
    MOVEM.W   $1234,A1/D7
    MOVEM.L   $1234,A1/D7
    MOVEM.W   $12345678,A1-A7
    MOVEM.L   $12345678,D1-D7
    MOVEM.W   $12345678,A1/D7
    MOVEM.L   $12345678,A1/D7
    ADDA.W    $12,A2
    ADDA.W    $1234,A2
    ADDA.W    $12345678,A2
    ADDA.W    #$1234,A2
    ADDA.L    $12,A2
    ADDA.L    $1234,A2
    ADDA.L    $12345678,A2
    ADDA.L    #$12345678,A2
    MULS.W    $12,D1
    MULS.W    $1234,D1
    MULS.W    $12345678,D1
    MULS.W    #$1234,D1
    DIVU.W    $12,D1
    DIVU.W    $1234,D1
    DIVU.W    $12345678,D1
    DIVU.W    #$1234,D1
    AND.B     D1,$12
    AND.B     D1,$1234
    AND.B     D1,$12345678
    AND.B     $12,D1
    AND.B     $1234,D1
    AND.B     $12345678,D1
    AND.B     #$12,D1
    AND.W     D1,$12
    AND.W     D1,$1234
    AND.W     D1,$12345678
    AND.W     $12,D1
    AND.W     $1234,D1
    AND.W     $12345678,D1
    AND.W     #$1234,D1
    AND.L     D1,$12
    AND.L     D1,$1234
    AND.L     D1,$12345678
    AND.L     $12,D1
    AND.L     $1234,D1
    AND.L     $12345678,D1
    AND.L     #$12345678,D1
    LSL.B     #$1,D2
    LSL.W     #$2,D2
    LSL.L     #$3,D2
    LSL.W     $12
    LSL.W     $1234
    LSL.W     $12345678
    ASR.B     #$1,D2
    ASR.W     #$2,D2
    ASR.L     #$3,D2
    ASR.W     $12
    ASR.W     $1234
    ASR.W     $12345678
label4
    BGT.B     label4
    BGT.B     label4
    BGT.B     label4
    BLE.W     label1
    BLE.W     label2
    BLE.W     label3
    BEQ.W     label1
    BEQ.W     label2
    BEQ.W     label3
    JSR       label1
    JSR       label2
    JSR       label3

* Put program code here

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*
*****************************

start		EQU	$00009000	* ORG and END address

* ORG the program so that it straddles the address boundary $00007FFF to $00008000

		ORG	start

NOP
    RTS
    NOP
    RTS
    LEA     (A0),A0
    LEA     (A5),A0
    LEA     (A7),A0
    LEA     (A0),A7
    LEA     (A5),A7
    LEA     (A7),A7
    MOVE.B    D0,D1
    MOVE.B    D0,(A0)
    MOVE.B    D0,(A0)+
    MOVE.B    D0,-(A0)
    MOVE.B    (A0),D0
    MOVE.B    (A0),(A1)
    MOVE.B    (A0),(A1)+
    MOVE.B    (A0),-(A1)
    MOVE.B    (A0)+,D0
    MOVE.B    (A0)+,(A1)
    MOVE.B    (A0)+,(A1)+
    MOVE.B    (A0)+,-(A1)
    MOVE.B    -(A0),D0
    MOVE.B    -(A0),(A1)
    MOVE.B    -(A0),(A1)+
    MOVE.B    -(A0),-(A1)
    MOVE.W    D0,D1
    MOVE.W    D0,(A0)
    MOVE.W    D0,(A0)+
    MOVE.W    D0,-(A0)
    MOVE.W    A0,D0
    MOVE.W    A0,(A1)
    MOVE.W    A0,(A1)+
    MOVE.W    A0,-(A1)
    MOVE.W    (A0),D0
    MOVE.W    (A0),(A1)
    MOVE.W    (A0),(A1)+
    MOVE.W    (A0),-(A1)
    MOVE.W    (A0)+,D0
    MOVE.W    (A0)+,(A1)
    MOVE.W    (A0)+,(A1)+
    MOVE.W    (A0)+,-(A1)
    MOVE.W    -(A0),D0
    MOVE.W    -(A0),(A1)
    MOVE.W    -(A0),(A1)+
    MOVE.W    -(A0),-(A1)
    MOVE.L    D0,D1
    MOVE.L    D0,(A0)
    MOVE.L    D0,(A0)+
    MOVE.L    D0,-(A0)
    MOVE.L    A0,D0
    MOVE.L    A0,(A1)
    MOVE.L    A0,(A1)+
    MOVE.L    A0,-(A1)
    MOVE.L    (A0),D0
    MOVE.L    (A0),(A1)
    MOVE.L    (A0),(A1)+
    MOVE.L    (A0),-(A1)
    MOVE.L    (A0)+,D0
    MOVE.L    (A0)+,(A1)
    MOVE.L    (A0)+,(A1)+
    MOVE.L    (A0)+,-(A1)
    MOVE.L    -(A0),D0
    MOVE.L    -(A0),(A1)
    MOVE.L    -(A0),(A1)+
    MOVE.L    -(A0),-(A1)
    MOVEM.W   A1-A7,-(A1)
    MOVEM.L   D1-D7,-(A1)
    MOVEM.W   A1/D7,-(A1)
    MOVEM.L   A1/D7,-(A1)
    MOVEM.W   A1-A7,(A1)
    MOVEM.L   D1-D7,(A1)
    MOVEM.W   A1/D7,(A1)
    MOVEM.L   A1/D7,(A1)
    MOVEM.W   (A1)+,A1-A7
    MOVEM.L   (A1)+,D1-D7
    MOVEM.W   (A1)+,A1/D7
    MOVEM.L   (A1)+,A1/D7
    MOVEM.W   (A1),A1-A7
    MOVEM.L   (A1),D1-D7
    MOVEM.W   (A1),A1/D7
    MOVEM.L   (A1),A1/D7
    MOVEA.W    D0,A0
    MOVEA.W    A0,A0
    MOVEA.W    (A0),A0
    MOVEA.W    (A0)+,A0
    MOVEA.W    -(A0),A0
    MOVEA.L    D0,A0
    MOVEA.L    A0,A0
    MOVEA.L    (A0),A0
    MOVEA.L    (A0)+,A0
    MOVEA.L    -(A0),A0  
    ADD.B     D1,D2
    ADD.B     D1,(A1)
    ADD.B     D1,(A1)+
    ADD.B     D1,-(A1)
    ADD.B     (A1),D1
    ADD.B     (A1)+,D1
    ADD.B     -(A1),D1
    ADD.W     D1,D2
    ADD.W     D1,(A1)
    ADD.W     D1,(A1)+
    ADD.W     D1,-(A1)
    ADD.W     (A1),D1
    ADD.W     (A1)+,D1
    ADD.W     -(A1),D1
    ADD.L     D1,D2
    ADD.L     D1,(A1)
    ADD.L     D1,(A1)+
    ADD.L     D1,-(A1)
    ADD.L     (A1),D1
    ADD.L     (A1)+,D1
    ADD.L     -(A1),D1
    ADDA.W        D1,A2
    ADDA.W        (A1),A2
    ADDA.W        (A1)+,A2
    ADDA.W        -(A1),A2
    ADDA.L        D1,A2
    ADDA.L        (A1),A2
    ADDA.L        (A1)+,A2
    ADDA.L        -(A1),A2
    SUB.B     D1,D2
    SUB.B     D1,(A1)
    SUB.B     D1,(A1)+
    SUB.B     D1,-(A1)
    SUB.B     (A1),D1
    SUB.B     (A1)+,D1
    SUB.B     -(A1),D1
    SUB.W     D1,D2
    SUB.W     D1,A1
    SUB.W     D1,(A1)
    SUB.W     D1,(A1)+
    SUB.W     D1,-(A1)
    SUB.W     A1,D1
    SUB.W     (A1),D1
    SUB.W     (A1)+,D1
    SUB.W     -(A1),D1
    SUB.L     D1,D2
    SUB.L     D1,A1
    SUB.L     D1,(A1)
    SUB.L     D1,(A1)+
    SUB.L     D1,-(A1)
    SUB.L     A1,D1
    SUB.L     (A1),D1
    SUB.L     (A1)+,D1
    SUB.L     -(A1),D1    
    MULS.W    D0,D1
    MULS.W    (A0),D1
    MULS.W    -(A0),D1
    MULS.W    (A0)+,D1
    DIVU.W    D0,D1
    DIVU.W    (A0),D1
    DIVU.W    -(A0),D1
    DIVU.W    (A0)+,D1
    AND.B     D1,D2
    AND.B     D1,(A1)
    AND.B     D1,(A1)+
    AND.B     D1,-(A1)
    AND.B     (A1),D1
    AND.B     (A1)+,D1
    AND.B     -(A1),D1
    AND.W     D1,D2
    AND.W     D1,(A1)
    AND.W     D1,(A1)+
    AND.W     D1,-(A1)
    AND.W     (A1),D1
    AND.W     (A1)+,D1
    AND.W     -(A1),D1
    AND.L     D1,D2
    AND.L     D1,(A1)
    AND.L     D1,(A1)+
    AND.L     D1,-(A1)
    AND.L     (A1),D1
    AND.L     (A1)+,D1
    AND.L     -(A1),D1
    OR.B     D1,D2
    OR.B     D1,(A1)
    OR.B     D1,(A1)+
    OR.B     D1,-(A1)
    OR.B     (A1),D1
    OR.B     (A1)+,D1
    OR.B     -(A1),D1
    OR.W     D1,D2
    OR.W     D1,(A1)
    OR.W     D1,(A1)+
    OR.W     D1,-(A1)
    OR.W     (A1),D1
    OR.W     (A1)+,D1
    OR.W     -(A1),D1
    OR.L     D1,D2
    OR.L     D1,(A1)
    OR.L     D1,(A1)+
    OR.L     D1,-(A1)
    OR.L     (A1),D1
    OR.L     (A1)+,D1
    OR.L     -(A1),D1
    LSL.B     D1,D2
    LSL.W     D1,D2
    LSL.W     (A1)
    LSL.W     (A1)+
    LSL.W     -(A1)
    LSL.L     D1,D2
    LSR.B     D1,D2
    LSR.W     D1,D2
    LSR.W     (A1)
    LSR.W     (A1)+
    LSR.W     -(A1)
    LSR.L     D1,D2    
    ASR.B     D1,D2
    ASR.W     D1,D2
    ASR.W     (A1)
    ASR.W     (A1)+
    ASR.W     -(A1)
    ASR.L     D1,D2
    ASL.B     D1,D2
    ASL.W     D1,D2
    ASL.W     (A1)
    ASL.W     (A1)+
    ASL.W     -(A1)
    ASL.L     D1,D2  
    BGT.B     label1
    BGT.B     label2
    BLE.B     label1
    BLE.B     label2
    BGE.B     label1
    BEQ.B     label2
    BEQ.W     label1
    JSR       (A0)
    JSR       $1234
    JSR       $12345678
    JSR       label1
    JSR       label2
    JSR       label3
    NOP
    RTS
label1
    NOP
    RTS
    LEA       $12,A0
    LEA       $1234,A0
    LEA       $12345678,A0
label2
    MOVEQ     #$0,D0
    MOVEQ     #$12,D0
    MOVEQ     #$FF,D0
label3
    MOVEM.W   A1-A7,$12
    MOVEM.L   D1-D7,$12
    MOVEM.W   A1/D7,$12
    MOVEM.L   A1/D7,$12
    MOVEM.W   A1-A7,$1234
    MOVEM.L   D1-D7,$1234
    MOVEM.W   A1/D7,$1234
    MOVEM.L   A1/D7,$1234
    MOVEM.W   A1-A7,$12345678
    MOVEM.L   D1-D7,$12345678
    MOVEM.W   A1/D7,$12345678
    MOVEM.L   A1/D7,$12345678
    MOVEM.W   $12,A1-A7
    MOVEM.L   $12,D1-D7
    MOVEM.W   $12,A1/D7
    MOVEM.L   $12,A1/D7
    MOVEM.W   $1234,A1-A7
    MOVEM.L   $1234,D1-D7
    MOVEM.W   $1234,A1/D7
    MOVEM.L   $1234,A1/D7
    MOVEM.W   $12345678,A1-A7
    MOVEM.L   $12345678,D1-D7
    MOVEM.W   $12345678,A1/D7
    MOVEM.L   $12345678,A1/D7
    ADDA.W    $12,A2
    ADDA.W    $1234,A2
    ADDA.W    $12345678,A2
    ADDA.W    #$1234,A2
    ADDA.L    $12,A2
    ADDA.L    $1234,A2
    ADDA.L    $12345678,A2
    ADDA.L    #$12345678,A2
    MULS.W    $12,D1
    MULS.W    $1234,D1
    MULS.W    $12345678,D1
    MULS.W    #$1234,D1
    DIVU.W    $12,D1
    DIVU.W    $1234,D1
    DIVU.W    $12345678,D1
    DIVU.W    #$1234,D1
    AND.B     D1,$12
    AND.B     D1,$1234
    AND.B     D1,$12345678
    AND.B     $12,D1
    AND.B     $1234,D1
    AND.B     $12345678,D1
    AND.B     #$12,D1
    AND.W     D1,$12
    AND.W     D1,$1234
    AND.W     D1,$12345678
    AND.W     $12,D1
    AND.W     $1234,D1
    AND.W     $12345678,D1
    AND.W     #$1234,D1
    AND.L     D1,$12
    AND.L     D1,$1234
    AND.L     D1,$12345678
    AND.L     $12,D1
    AND.L     $1234,D1
    AND.L     $12345678,D1
    AND.L     #$12345678,D1
    LSL.B     #$1,D2
    LSL.W     #$2,D2
    LSL.L     #$3,D2
    LSL.W     $12
    LSL.W     $1234
    LSL.W     $12345678
    ASR.B     #$1,D2
    ASR.W     #$2,D2
    ASR.L     #$3,D2
    ASR.W     $12
    ASR.W     $1234
    ASR.W     $12345678
label4
    BGT.B     label4
    BGT.B     label4
    BGT.B     label4
    BLE.W     label1
    BLE.W     label2
    BLE.W     label3
    BEQ.W     label1
    BEQ.W     label2
    BEQ.W     label3
    JSR       label1
    JSR       label2
    JSR       label3

* Put program code here

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source





















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
