with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Doubles ; use Doubles ;
with task_set;
use task_set;
with Unbounded_Strings;        use Unbounded_Strings;
with processors;use processors;

package simulation_interval_funcs 
is


function is_scheduling_period_2022 (my_tasks : in tasks_set; processor : in generic_processor_ptr) return Boolean ;
--gossens 2022 paper
function scheduling_period_2022 (my_tasks : in tasks_set; processor_name : in Unbounded_String)
return Double;

function Release(t: Integer ; my_tasks : in tasks_set ; processor_name : Unbounded_String) return Integer ;

function Request(t: Integer ; Old_Request :Integer ; my_tasks : in tasks_set ; processor_name : Unbounded_String) return Integer;
procedure scheduling_period_2004
  (My_Tasks       : in Tasks_Set;
   Processor_Name : in Unbounded_String;
   R              : in Natural; 
   P              : in Positive; 
   U              : in Double;
   T_C            : out Integer;
   R_0            : out Integer );

end simulation_interval_funcs;