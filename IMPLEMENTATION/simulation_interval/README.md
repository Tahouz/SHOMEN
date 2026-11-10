#How to use the template
- Duplicate the content of the folder and put it in framework_examples/<your_program>
- The word "template" should be updated with the name of your program, in the following files:
	+ Makefile
	+ template.adb
	+ template.gpr	
- A working example following this template can be found in framework_examples/tsn_sched

#Folder Description
This is only a guideline, try to respect it but feel free to make some adaptations.
- input: input data for your program, for example:
	+ A cheddar system model (.xmlv3)
	+ A set of input parameters	in a text file
	+ ...
- expected_output: expected output data for your program, for example:
	+ stdout information with analysis result
	+ A Cheddar system model after analysis
	+ A Cheddar event table as simulation result
	+ A screenshot
	+ ...
- script: any scripts that can be used to run your program
- util: utility ada classes
