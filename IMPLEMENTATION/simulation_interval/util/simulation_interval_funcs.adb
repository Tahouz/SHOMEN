with Ada.Text_IO;
with Doubles ; use Doubles ;
with task_set;
use task_set;
with Unbounded_Strings;        use Unbounded_Strings;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with tasks ; use tasks;
with Processors;                        use Processors;
with processor_set;                     use processor_set;
with natural_util ; 
with fifos;
with feasibility_test.feasibility_interval; use feasibility_test.feasibility_interval;
with Ada.Integer_Text_IO;
package body simulation_interval_funcs is



function is_scheduling_period_2022 (my_tasks : in tasks_set; processor : in generic_processor_ptr) return Boolean
is
   a_task      : generic_task_ptr;
   my_iterator : tasks_iterator;
   Current_Task_O : Natural;
   Current_Task_T : Natural;
   Current_Task_D : Natural;
   
   Async : Boolean := False; 
   With_Preemption_Delay : Boolean := True;
   deadline_nequal_to_period : Boolean := True;

   Work_Conserving_Deterministic_memoryLessSchduler : Boolean; 
   processor_name : Unbounded_String := processor.name;
   
   -- Variables to track the first task's offset
   First_Offset     : Natural := 0;
   First_Offset_Set : Boolean := False;

begin
   Work_Conserving_Deterministic_memoryLessSchduler := 
      is_resettable_deterministic_scheduler(Mono_Core_Processor_Ptr (processor).core.scheduling.scheduler_type) 
      and is_work_conserving_scheduler(Mono_Core_Processor_Ptr (processor).core.scheduling.scheduler_type);
   periodic_control (my_tasks, processor_name);
   reset_iterator (my_tasks, my_iterator);
   loop
      current_element (my_tasks, a_task, my_iterator);

      if (a_task.cpu_name = processor_name and a_task.task_type = periodic_type) then
         Current_Task_O := a_task.start_time;
         if not First_Offset_Set then
            First_Offset := Current_Task_O;
            First_Offset_Set := True;
         elsif Current_Task_O /= First_Offset then
            Async := True;
         end if;

         Current_Task_T := periodic_task_ptr (a_task).period;
         Current_Task_D := a_task.deadline;
         
         if Current_Task_D = Current_Task_T then 
            deadline_nequal_to_period := False;
         end if;
      end if;
      
      exit when is_last_element (my_tasks, my_iterator) or (not deadline_nequal_to_period) ;
      next_element (my_tasks, my_iterator);
   end loop;
   Ada.Text_IO.Put_Line (deadline_nequal_to_period'Image);

   return deadline_nequal_to_period and Work_Conserving_Deterministic_memoryLessSchduler and Async and With_Preemption_Delay;

end is_scheduling_period_2022;
--- This Function still needs a way to calculate the max preemption delay 
function scheduling_period_2022 (my_tasks : in tasks_set; processor_name : in Unbounded_String) return Double
is
Return_Value : Double := 1.0 ;
Number_of_Tasks :Natural  :=1; --Natural 0 -> 100
Hyper_Period : Integer := 1;
Applicable : Boolean := True;
begin
-- verify if it is applicable 




--calculate *(min((Oi+Di-Ti),0) + 1)
declare 
   a_task      : generic_task_ptr;
   my_iterator : tasks_iterator;
   Formula : Natural := 1;
   Current_Task_O :Natural;
   Current_Task_T :Natural;
   Current_Task_D :Natural;

begin
   periodic_control (my_tasks, processor_name);
   reset_iterator (my_tasks, my_iterator);
   loop
         current_element (my_tasks, a_task, my_iterator);

   if (a_task.cpu_name = processor_name and a_task.task_type = periodic_type) then
      Number_of_Tasks := Number_of_Tasks + 1;
      Current_Task_O := a_task.start_time;
      Current_Task_T := periodic_task_ptr (a_task).period ;
      Current_Task_D := a_task.deadline ;
      Hyper_Period :=natural_util.lcm (Hyper_Period, periodic_task_ptr (a_task).period);
      Formula := Formula * (Integer'Min((Integer(Current_Task_O + Current_Task_D) - Integer(Current_Task_T)),0) +1);
      end if;
         exit when is_last_element (my_tasks, my_iterator);
      next_element (my_tasks, my_iterator);
   end loop;
      Return_Value := Double(Formula * Hyper_Period * Number_of_Tasks);
end;

return Return_Value;



end scheduling_period_2022;


-- Release functions for pure periodic tasks
function Release(t: Integer ; my_tasks : in tasks_set ; processor_name : Unbounded_String) return Integer
is
a_task      : generic_task_ptr;
my_iterator : tasks_iterator;
Return_Value : Natural :=0;
begin 


periodic_control (my_tasks, processor_name);
reset_iterator (my_tasks, my_iterator);
loop
         current_element (my_tasks, a_task, my_iterator);

   if (a_task.cpu_name = processor_name and a_task.task_type = periodic_type) then
      declare 
         Current_Task_T :Natural;
         start_time : Natural;
      begin 
      Current_Task_T := periodic_task_ptr (a_task).period;
      start_time := a_task.start_time;
      if (((t-start_time) mod Current_Task_T )= 0 and (t-start_time) >= 0) then
         Return_Value := Return_Value + a_task.capacity;
      end if; 
      end;
   end if;
   exit when is_last_element (my_tasks, my_iterator);
   next_element (my_tasks, my_iterator);
end loop;


return Return_Value;
end Release;


function Request(t: Integer ; Old_Request :Integer ; my_tasks : in tasks_set ; processor_name : Unbounded_String) return Integer
is 
begin

if Old_Request > 0 then  
   return Old_Request - 1 + Release (t, my_tasks, processor_name);
else
   return Release(t, my_tasks, processor_name);
end if;
end Request ;

procedure scheduling_period_2004
  (My_Tasks       : in Tasks_Set;
   Processor_Name : in Unbounded_String;
   R              : in Natural; -- Max Offset
   P              : in Positive; --HyperPeriod
   U              : in Double;--Utilization
   T_C            : out Integer;--Last Idle Slot
   R_0            : out Integer )--Last Idle Slot + 1 (where should we simulate) 
is

   procedure Put_Integer (Value : in Integer) is
   begin
      Ada.Integer_Text_IO.Put (Value);
   end Put_Integer;
   package Idle_Fifos is new Fifos
     (max_element => P + 1,
      element     => Integer,
      put         => Put_Integer);

   Idle_Slots : Idle_Fifos.Fifo;

   Req    : Integer := 0;
   Nb_I   : Natural := 0;
   Tfirst : Integer := 0;
   T      : Integer := 0;
   Last   : Integer := -1;
   Found  : Boolean := False;

   Cyclic_Idles : Natural;

begin

   if U < 0.0 or else U > 1.0 then
      raise Constraint_Error;
   end if;

   Idle_Fifos.Reset (Idle_Slots);

   Cyclic_Idles :=
      Natural (Double (P) * (1.0 - U));

   while T < R + P and then not Found loop

      Req := Request (T, Req, My_Tasks, Processor_Name);

      if Req = 0 then
         Nb_I := Nb_I + 1;
         Idle_Fifos.Insert (Idle_Slots, T);

      end if;
      if T - Tfirst + 1 = P then

         if Nb_I > Cyclic_Idles then
            declare
               Position : constant Positive :=
                  Nb_I - Cyclic_Idles;

               Slot : Integer;
            begin
               for I in 1 .. Nb_I loop

                  Slot := Idle_Fifos.Consult (Idle_Slots);

                  if I = Position then
                     Last := Slot;
                  end if;

                  Idle_Fifos.Remove (Idle_Slots);
                  Idle_Fifos.Insert (Idle_Slots, Slot);

               end loop;

            end;

         else
            Found := True;

         end if;
         Tfirst := Tfirst + 1;
         if not Idle_Fifos.Is_Empty (Idle_Slots) then

            if Idle_Fifos.Consult (Idle_Slots)
               = Tfirst - 1
            then

               Idle_Fifos.Remove (Idle_Slots);
               Nb_I := Nb_I - 1;

            end if;

         end if;

      end if;
      T := T + 1;

   end loop;

   T_C := Last;
   R_0 := Last + 1;

end scheduling_period_2004;


end simulation_interval_funcs;
