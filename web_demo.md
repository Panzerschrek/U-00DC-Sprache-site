### Ü Web-Demo

On this page you can try Ü interpreter.
WebAssembly required.

Note that interpreter is pretty limited.
It is recommended to install and use proper compiler.

<div>
Input code:
<br>
<textarea id="input" style="font-family: monospace; width: 768px;" rows="12"></textarea>
<br>
<button onClick="CompileAndRun()"> Compile and run! </button>
<br>
Execution status:
<textarea id="execution_status" readonly style="font-family: monospace; width: 64px; resize: none;" rows="1"></textarea>
<br>
Stdout:
<br>
<textarea id="output" readonly style="font-family: monospace; width: 768px;" rows="8"></textarea>
<br>
Stderr:
<br>
<textarea id="output_err" readonly style="font-family: monospace; width: 768px;" rows="8"></textarea>
<script type="text/javascript">

	var text_in_element = document.getElementById("input");
	var text_out_element = document.getElementById("output");
	var text_out_err_element = document.getElementById("output_err");
	var execution_status_element = document.getElementById("execution_status");
	text_out_element.value = "";
	text_out_err_element.value = "";
	execution_status_element.value = "";

	function CompileAndRun()
	{

		execution_status_element.value=  '';
		text_out_element.value = '';
		text_out_err_element.value = '';

		var interpreter_result = InterpreterCompileAndRun( text_in_element.value );
		execution_status_element.value = interpreter_result[0];
		text_out_element.value = interpreter_result[1];
		text_out_err_element.value = interpreter_result[2];
	};

</script>
<script async="" src="Interpreter_launcher.js"></script>
<script async="" src="Interpreter.js"></script>
</div>
