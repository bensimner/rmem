(*===============================================================================*)
(*                                                                               *)
(*                rmem executable model                                          *)
(*                =====================                                          *)
(*                                                                               *)
(*  This file is:                                                                *)
(*                                                                               *)
(*  Copyright Jon French, University of Cambridge 2018                           *)
(*                                                                               *)
(*  All rights reserved.                                                         *)
(*                                                                               *)
(*  It is part of the rmem tool, distributed under the 2-clause BSD licence in   *)
(*  LICENCE.txt.                                                                 *)
(*                                                                               *)
(*===============================================================================*)

(* Platform info for RISCV model *)

open Sail_lib

let dram_base  = 0x00000000L;;  (* Spike::DRAM_BASE *)
(* dram_size has to be big enough to include Elf_test_file.stack_base_address *)
let dram_size  = 0xffffff00000L;;
let clint_base = 0x82000000L;;  (* Spike::CLINT_BASE *)
let clint_size = 0x800c0000L;;  (* Spike::CLINT_SIZE *)
let rom_base   = 0x80001000L;;  (* Spike::DEFAULT_RSTVEC *)
let cpu_hz = 1000000000;;
let insns_per_tick = 100;;

let bits_of_int i =
  get_slice_int (Big_int.of_int 64, Big_int.of_int i, Big_int.zero)

let bits_of_int64 i =
  get_slice_int (Big_int.of_int 64, Big_int.of_int64 i, Big_int.zero)


let rom_base () = Lem_machine_word.wordFromInteger Lem_machine_word.instance_Machine_word_Size_Machine_word_ty64_dict (Big_int.of_int64 rom_base)
let rom_size () = Lem_machine_word.wordFromInteger Lem_machine_word.instance_Machine_word_Size_Machine_word_ty64_dict Big_int.zero   (* !rom_size_ref *)

let dram_base () = Lem_machine_word.wordFromInteger Lem_machine_word.instance_Machine_word_Size_Machine_word_ty64_dict (Big_int.of_int64 dram_base)
let dram_size () = Lem_machine_word.wordFromInteger Lem_machine_word.instance_Machine_word_Size_Machine_word_ty64_dict (Big_int.of_int64 dram_size)

let htif_tohost () =
  Lem_machine_word.wordFromInteger Lem_machine_word.instance_Machine_word_Size_Machine_word_ty64_dict (Big_int.of_int 0x100) (*  bits_of_int 0*) (* (Big_int.to_int64 (Elf.elf_tohost ())) *)

let clint_base () = Lem_machine_word.wordFromInteger Lem_machine_word.instance_Machine_word_Size_Machine_word_ty64_dict  (Big_int.of_int64 clint_base)
let clint_size () = Lem_machine_word.wordFromInteger Lem_machine_word.instance_Machine_word_Size_Machine_word_ty64_dict (Big_int.of_int64 clint_size)

let insns_per_tick () = Big_int.of_int insns_per_tick

let term_write _ = failwith "term_write stub"

let enable_dirty_update () = false

let enable_misaligned_access () = true

let mtval_has_illegal_inst_bits () = false