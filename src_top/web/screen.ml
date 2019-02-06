(*===============================================================================*)
(*                                                                               *)
(*                rmem executable model                                          *)
(*                =====================                                          *)
(*                                                                               *)
(*  This file is:                                                                *)
(*                                                                               *)
(*  Copyright Jon French, University of Cambridge             2017               *)
(*  Copyright Shaked Flur, University of Cambridge       2015-2018               *)
(*  Copyright Peter Sewell, University of Cambridge           2016               *)
(*  Copyright Christopher Pulte, University of Cambridge      2015               *)
(*                                                                               *)
(*  All rights reserved.                                                         *)
(*                                                                               *)
(*  It is part of the rmem tool, distributed under the 2-clause BSD licence in   *)
(*  LICENCE.txt.                                                                 *)
(*                                                                               *)
(*===============================================================================*)

let of_output_tree = Screen_base.html_of_output_tree;;

let final_state_color = "blue"

let getElementById x =
  let document = Dom_html.window##.document in
  Js.Opt.get (document##(getElementById (Js.string x)))
  (fun () ->
      Printf.printf "could not find element ID: \"%s\"\n" x;
      assert false)
;;

let replace_text js_str p r =
  let x = new%js Js.regExp_withFlags (Js.string p) (Js.string "mg") in
  let y = Js.string r in
  js_str##(replace x y)
;;

let escape_newline js_str = replace_text js_str "\\n" "<br/>";;

let clear_warnings : unit -> unit = fun () ->
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "clear_warnings") [||]

let input_cont : (string -> unit) ref = ref (fun _ -> ());;
let history : Interact_parser_base.ast list ref = ref []

let async_input new_history (cont: string -> unit) : unit =
  history := new_history;
  input_cont := (fun str -> input_cont := (fun _ -> ()); cont str)

let replacements = [
    ('&', "&amp;");
    ('<', "&lt;");
    ('>', "&gt;");
    ('"', "&quot;");
    ('\'', "&#x27;");
    ('/', "&#x2f;");
  ]

let replace_char c r s =
  let rec do_replace s =
    try
      let i = String.index s c in
      String.sub s 0 i :: r :: do_replace (String.sub s (i + 1) (String.length s - i - 1))
    with Not_found -> [s]
  in
  String.concat "" (do_replace s)


module WebPrinters : Screen_base.Printers = struct
  let println s = Js.Unsafe.fun_call (Js.Unsafe.js_expr "println")
                                     [|Js.Unsafe.inject (Js.string s)|]
  let clear_screen () = Js.Unsafe.fun_call (Js.Unsafe.js_expr "clear_screen") [||]
  let escape s = List.fold_left (fun s (c, r) -> replace_char c r s) s replacements
  let update_transition_history history available = Js.Unsafe.fun_call (Js.Unsafe.js_expr "update_transition_history")
                                                                       [|Js.Unsafe.inject (Js.string history);
                                                                         Js.Unsafe.inject (Js.string available)|]
                                                    |> ignore
  let read_filename basename = Js.to_bytestring (Js.Unsafe.fun_call (Js.Unsafe.js_expr "read_filename")
                                                                [|Js.Unsafe.inject (Js.string basename)|])
end

include (Screen_base.Make (WebPrinters))

let quit : unit -> unit = fun () ->
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "quit") [||] |> ignore

let render_dot ppmode legend_opt s cex (nc: (int * ('ss, 'b) MachineDefTypes.trans) list) = fun layout_dot ->
  (* Pp.split doesn't like this for some reason --
     I believe because of its 'skip beginning and end' behaviour *)
  let lines = (Js.string layout_dot)##split (Js.string "\n") |>
                Js.str_array |> Js.to_array |> Array.map Js.to_string |> Array.to_list in
  let positions = Graphviz.parse_dot_positions lines in
  let dot = Graphviz.pp_raw_dot ppmode legend_opt true positions s cex nc in
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "display_dot")
                     [|Js.Unsafe.inject (Js.string dot)|]
  |> ignore

let display_dot ppmode legend_opt s cex (nc: (int * ('ss, 'b) MachineDefTypes.trans) list) =
  let layout_dot = Graphviz.pp_raw_dot ppmode legend_opt false [] s cex nc in
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "layout_dot")
                     [|
                       Js.Unsafe.inject (Js.string layout_dot);
                       Js.Unsafe.inject (Js.wrap_callback
                                           (render_dot ppmode legend_opt s cex nc))
                     |]
  |> ignore

let current_options (options : Screen_base.options_state) =
  let open Screen_base in
  let open RunOptions in
  let open MachineDefTypes in
  let open Globals in
  let run_options = options.run_options in
  let ppmode = options.ppmode in
  object%js
           (* These fields all have trailing underscores because of
              js_of_ocaml's overloading system *)
    val eager_fetch_single_ = run_options.eager_mode.eager_fetch_single
    val eager_fetch_multi_ = run_options.eager_mode.eager_fetch_multi
    val eager_pseudocode_internal_ = run_options.eager_mode.eager_pseudocode_internal
    val eager_constant_reg_read_ = run_options.eager_mode.eager_constant_reg_read
    val eager_reg_rw_ = run_options.eager_mode.eager_reg_rw
    val eager_memory_aux_ = run_options.eager_mode.eager_memory_aux
    val eager_finish_ = run_options.eager_mode.eager_finish
    val eager_fp_recalc_ = run_options.eager_mode.eager_fp_recalc
    val eager_thread_start_ = run_options.eager_mode.eager_thread_start
    val eager_up_to_shared_ = run_options.eager_up_to_shared
    val suppress_internal_ = run_options.suppress_internal
    val always_print_ = run_options.always_print
    val always_graph_ = options.always_graph
    val dot_final_ok_ = options.dot_final_ok
    val dot_final_not_ok_ = options.dot_final_not_ok
    val suppress_newpage_ = ppmode.pp_suppress_newpage
    val buffer_messages_ = ppmode.pp_buffer_messages
    val announce_options_ = ppmode.pp_announce_options
    val record_writes_ = run_options.record_shared_locations
    val random_ = run_options.pseudorandom
    val storage_first_ = run_options.storage_first
    val priority_reduction_ = run_options.priority_reduction
    val check_inf_loop_ = run_options.check_inf_loop
    val hash_prune_ = run_options.hash_prune
    val partial_order_reduction_ = run_options.partial_order_reduction
    val compare_analyses_ = run_options.compare_analyses
    val prune_restarts_ = run_options.prune_restarts
    val prune_discards_ = run_options.prune_discards
    val ppg_shared_ = ppmode.ppg_shared
    val ppg_rf_ = ppmode.ppg_rf
    val ppg_fr_ = ppmode.ppg_fr
    val ppg_co_ = ppmode.ppg_co
    val ppg_addr_ = ppmode.ppg_addr
    val ppg_data_ = ppmode.ppg_data
    val ppg_ctrl_ = ppmode.ppg_ctrl
    val ppg_regs_ = ppmode.ppg_regs
    val ppg_reg_rf_ = ppmode.ppg_reg_rf
    val ppg_trans_ = ppmode.ppg_trans
    val pp_hex_ = options.pp_hex
    val pp_colours_ = ppmode.pp_colours
    val prefer_symbolic_values_ = ppmode.pp_prefer_symbolic_values
    val condense_finished_instructions_ = ppmode.pp_condense_finished_instructions
    val dwarf_show_all_variable_locations_ = options.dwarf_show_all_variable_locations
    val pp_sail_ = ppmode.pp_sail
    val hide_pseudoregister_reads_ = ppmode.pp_hide_pseudoregister_reads
    val max_finished_ =
      match ppmode.pp_max_finished with
      | Some limit -> Js.some limit
      | None -> Js.null
    val verbosity_ =
      Js.string (match options.verbosity with
      | Globals.Quiet -> "quiet"
      | Globals.Normal -> "normal"
      | Globals.ThrottledInformation -> "verbose"
      | Globals.UnthrottledInformation -> "very"
      | Globals.Debug -> "debug")
    val pp_style_ = Js.string (Globals.pp_ppstyle ppmode.pp_style)
    val choice_history_limit_ =
      match ppmode.pp_choice_history_limit with
      | Some limit -> Js.some limit
      | None -> Js.null
    val transition_limit_ =
      match run_options.transition_limit with
      | Some limit -> Js.some limit
      | None -> Js.null
    val trace_limit_ =
      match run_options.trace_limit with
      | Some limit -> Js.some limit
      | None -> Js.null
    val time_limit_ =
      match run_options.time_limit with
      | Some limit -> Js.some limit
      | None -> Js.null
    val loop_limit_ =
      match options.model_params.MachineDefTypes.t.thread_loop_unroll_limit with
      | Some limit -> Js.some limit
      | None -> Js.null
  end

let prompt ppmode maybe_options prompt_str history cont =
  flush_buffer ppmode;
  Js.Unsafe.fun_call (Js.Unsafe.js_expr "show_prompt")
                     [|Js.Unsafe.inject (Js.string prompt_str)|] |> ignore;
  begin match maybe_options with
  | Some options -> Js.Unsafe.fun_call (Js.Unsafe.js_expr "update_options")
                                              [|Js.Unsafe.inject (current_options options)|] |> ignore
  | None -> ()
  end;
  async_input history cont

(* export functions to JS *)
let () =
  Js.export "interact_lib"
            (object%js
               (* These fields all have trailing underscores because of
                  js_of_ocaml's overloading system *)
               method input_str_ str = (!input_cont) (Js.to_string str)
               method update_sources_ new_sources = Files.update_sources new_sources
               method get_history_ = List.rev !history |> List.map (fun ast -> Js.string (Interact_parser_base.pp ast)) |> Array.of_list |> Js.array
             end)

let interactive = true