#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Compute the MODBUS RTU CRC
unsigned short int ModRTU_CRC(char buf[], int len)
{
  unsigned short int crc = 0xFFFF;
  
  for (int pos = 0; pos < len; pos++) {
    crc ^= (unsigned short int)buf[pos];          // XOR byte into least sig. byte of crc
  
    for (int i = 8; i != 0; i--) {    // Loop over each bit
      if ((crc & 0x0001) != 0) {      // If the LSB is set
        crc >>= 1;                    // Shift right and XOR 0xA001
        crc ^= 0xA001;
      }
      else                            // Else LSB is not set
        crc >>= 1;                    // Just shift right
    }
  }
  // Note, this number has low and high bytes swapped, so use it accordingly (or swap bytes)
  return crc;  
}

int main(int argc, char *argv[]){
    unsigned char crc_low, crc_high;
    unsigned short int crc;
    
    crc=ModRTU_CRC(argv[1],strnlen(argv[1],32));
    crc_low=crc&0x00FF;
    crc_high=crc>>8;
    printf("%s%x%x\n",argv[1],crc_low,crc_high);
    return 0;
}
