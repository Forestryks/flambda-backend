(* TEST
 flags = "-g";
 reason = "port stat-mem-prof : https://github.com/ocaml/ocaml/pull/8634";
*)

module MP = Gc.Memprof

let rec allocate_list accu = function
  | 0 -> accu
  | n -> allocate_list (n::accu) (n-1)

let[@inline never] allocate_lists len cnt =
  for j = 0 to cnt-1 do
    ignore (Sys.opaque_identity (allocate_list [] len))
  done

let check_distrib len cnt rate =
  Printf.printf "check_distrib %d %d %f\n%!" len cnt rate;
  let tracked = ref 0 in
  let smp = ref 0 in
  let _:MP.t = MP.start ~callstack_size:10 ~sampling_rate:rate
    { MP.null_tracker with
      alloc_major = (fun _ -> assert false);
      alloc_minor = (fun info ->
        assert (info.size = 2);
        assert (info.n_samples > 0);
        assert (info.source = Normal);
        incr tracked;
        smp := !smp + info.n_samples;
        None);
    } in
  allocate_lists len cnt;
  MP.stop ();

  (* The probability distribution of the number of samples follows a
     binomial distribution of parameters tot_alloc and rate. Given
     that tot_alloc*rate and tot_alloc*(1-rate) are large (i.e., >
     100), this distribution is approximately equal to a normal
     distribution. We compute a 1e-8 confidence interval for !smp
     using quantiles of the normal distribution, and check that we are
     in this confidence interval. *)
  let tot_alloc = float (cnt*len*3) in
  assert (tot_alloc *. rate > 100. &&
          tot_alloc *. (1. -. rate) > 100.);
  let mean = tot_alloc *. rate in
  let stddev = sqrt (tot_alloc *. rate *. (1. -. rate)) in
   (* This should fail approximately one time in 100,000,000 *)
   assert (abs_float (mean -. float !smp) <= stddev *. 5.7)

let () =
  check_distrib 10 1000000 0.01;
  check_distrib 1000000 10 0.00001;
  check_distrib 1000000 10 0.0001;
  check_distrib 1000000 10 0.001;
  check_distrib 1000000 10 0.01;
  check_distrib 100000 10 0.1;
  check_distrib 100000 10 0.9

let () =
  Printf.printf "OK !\n"
