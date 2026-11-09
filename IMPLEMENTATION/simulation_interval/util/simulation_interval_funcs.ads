with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Doubles ; use Doubles ;
with task_set;
use task_set;
with Unbounded_Strings;        use Unbounded_Strings;

package simulation_interval_funcs 
is
--gossens 2022 paper
function scheduling_period_2022 (my_tasks : in tasks_set; processor_name : in Unbounded_String)
return Double;

function Release(t: Integer ; my_tasks : in tasks_set ; processor_name : Unbounded_String) return Integer ;

function Request(t: Integer ; Old_Request :Integer ; my_tasks : in tasks_set ; processor_name : Unbounded_String) return Integer;


end simulation_interval_funcs;