      subroutine input_mem_size(stack_size, heap_size, global_size,
     $   overify, ohardfail)
C$Id: input_mem.F 19697 2010-10-29 16:57:34Z d3y133 $
      implicit none
#include "inp.fh"
#include "mafdecls.fh"
#include "global.fh"
#include "tcgmsg.fh"
#include "msgids.fh"
#include "stdio.fh"
      integer stack_size        ! [output]
      integer heap_size         ! [output]
      integer global_size       ! [output]
      logical overify           ! [output]
      logical ohardfail         ! [output]
C
      integer Total_Size
      Character*1 Total_Src, Heap_Src, Stack_Src, Global_Src
c
c     Scan the input file for the memory directive and call
c     memory_input() to parse the line without storing the data
c     in the database (which may not be available for use)
c
c     Return also flag to enable/disable automatic memory verification.
c
c     Search for memory keyword from beginning of input file
c
      overify    = .true.       ! Verify unless told otherwise!
      ohardfail  = .false.      ! Don't hard fail
C
      if (nodeid() .eq. 0) then ! tcgmsg not GA due to init. order
         rewind LuIn
         call inp_init(LuIn,LuOut)
         if (inp_search(.false., 'memory', 1)) then
            call memory_input(-1, .false., stack_size, heap_size, 
     $           global_size, Total_Size, overify, ohardfail)
         Else
            Total_Src = 'N'
            Heap_Src = 'N'
            Stack_Src = 'N'
            Global_Src = 'N'
            Call Memory_Defaults( Total_Size, Total_Src, Heap_Size,
     $         Heap_Src, Stack_Size, Stack_Src, Global_Size,
     $         Global_Src )
         EndIf
         rewind LuIn
         call inp_init(LuIn,LuOut)
      endif
c
c     Has to be TCGMSG broadcast since GA is not yet initialized
c
      call brdcst(Msg_HeapMem, heap_size,  mitob(1), 0)
      call brdcst(Msg_StkMem, stack_size,  mitob(1), 0)
      call brdcst(Msg_GblMem, global_size, mitob(1), 0)
      call brdcst(Msg_StkMem,    overify,  mitob(1), 0)
c
      end
