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
<script type='text/javascript'>
	var text_in_element = document.getElementById('input');
	var text_out_element = document.getElementById('output');
	text_in_element.value = '// write your code here';

    function CompileAndRun()
    {
        text_out_element.value = 'TODO - run interpreter';
    }
</script>
</div>
