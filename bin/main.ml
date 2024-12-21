let usage_msg = "askier <file>"

let input_file = ref ""

let input_file_fun fn = input_file := fn

let speclist = []

let () = Arg.parse speclist input_file_fun usage_msg;
         print_endline !input_file
