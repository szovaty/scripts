
#include <sys/types.h>
#include <sys/stat.h> 
#include <fcntl.h>    
                      
#include <unistd.h>   
#include <stdio.h>    
                      
/* Returns 1 if processor found, 0 otherwise */
                                               
int setupCpu(int cpuid)                        
{                                              
 int addr = 0x3a; // VTX enable                
                                               
 char devfile[255];                            
 sprintf(devfile, "/dev/cpu/%d/msr", cpuid);   
                                               
 int fd = open(devfile, O_RDONLY);             
 if (fd==-1)                                   
 {                                             
   printf("Device %s does not exist. Either we have run out of processors, or the msr kernel module is not loaded\n", devfile);                                                                                  
   return 0;
}
                                                                                                        
 char buf[8];
                                                                                                        
//  printf("Setting up cpu %d - %s\n",cpuid, devfile);
                                                                                                        
 lseek(fd, addr, SEEK_SET);
 read(fd, buf, 8);                                                             
                                                                                                        
 char bLo = buf[0]; // Low byte
 if (bLo & 1) // locked
 { 
   if (bLo & 4)
     printf("cpud %d is locked ON :)\n", cpuid);
   else
     printf("cpud %d is locked OFF :(\n", cpuid);
 }
 else                                                                                                   
 {  // Unlocked - we can try and turn vtx on
   fd = open(devfile, O_WRONLY);
   if (fd == -1)
   {
     printf("Failed to open device %s for writing\n", devfile);
   }
   else
   {
     buf[0] = buf[0] | 5; // On + lock
     lseek(fd, addr, SEEK_SET);
     if (write(fd, buf, 8) < 0)
     {
       printf("Failed to write to device %s\n", devfile);
     }
     else
     {
       printf("cpu %d - Switched VT-X on :)\n", cpuid);
     }
   }
 }

 return 1;
}

int main(int argc, char *argv[])
{
 printf("MSR Magic 1.0 (C) 2009 George Styles www.georgestyles.co.uk\n\n");
 int iCpu = 0;
 setupCpu(0);
 setupCpu(1);
 setupCpu(2);
 setupCpu(3);

 //while (setupCpu(iCpu) != 0)
 //{
 //  iCpu++;
 //}
 return 0;
}
