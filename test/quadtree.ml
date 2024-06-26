open OUnit2
open Core
open Util

module Elt = struct
  type n = Num.t
  type t = n * n

  let equal = Tuple2.equal ~eq1:Num.equal ~eq2:Num.equal
  let position = Fn.id
end

module Q = Ack.Quadtree.Make (Num) (Elt)
module Point = Q.Point
module Box = Q.Box

let test_domain = Box.box (Point.splat 0.) (Point.splat test_domain_max)
(* Test box/domain, in range 0-100 *)

let rand_es n max = List.init n ~f:(fun _ -> Random.float max, Random.float max)
(* Random elt generator *)

let tuple_splat n = n, n
(* Elt from int *)

(* Tests whether two boxes intersect *)
let test_intersects _ =
  let box = Box.box (Point.splat 25.) (Point.splat 75.) in
  assert (Box.intersects box test_domain)
;;

(* Tests whether a point is contained in a box *)
let test_contains _ =
  let pt = Point.splat 50. in
  assert (Box.contains test_domain pt)
;;

(* Test size of tree *)
let test_size _ =
  let size = 8 in
  let es = rand_es size 100. in
  let t = Q.load (Q.empty test_domain 4) es in
  assert_equal (Q.size t) size
;;

(* Test loading a lot of elements -- TODO optimize `Q.load` *)
let test_load_many _ =
  let op () =
    let size = 100_000 in
    let es = rand_es size 100. in
    let t = Q.load (Q.empty test_domain 64) es in
    assert_equal (Q.size t) size
  in
  time "TEST LOAD 100_000" op
;;

let test_load_lots _ =
  let op () =
    let size = 1_000_000 in
    let es = rand_es size 100. in
    let t = Q.load (Q.empty test_domain 256) es in
    assert_equal (Q.size t) size
  in
  time "TEST LOAD 1_000_000" op
;;

(* Test inserting a single elt *)
let test_insert _ =
  let empty = Q.empty test_domain 4 in
  let t = Q.insert empty @@ tuple_splat 50. in
  assert_equal (Q.size t) 1
;;

(* Test removing a single elt from a 1k elt tree *)
let test_remove _ =
  let target_size = 1_000 in
  let es = rand_es (pred target_size) 100. in
  let not_rand = 50., 50. in
  let empty = Q.empty test_domain 32 in
  let t = Q.load empty @@ (not_rand :: es) in
  assert_equal (Q.size t) target_size;
  let t = Q.remove t not_rand in
  assert_equal (Q.size t) (pred target_size)
;;

(* Test finding a single elt in a 1k elt tree *)
let test_find _ =
  let not_target_range = 90. in
  let es = rand_es 1_000 not_target_range in
  let target_elt = 95., 95. in
  let t = Q.load (Q.empty test_domain 32) @@ (target_elt :: es) in
  assert' @@ Option.is_some @@ Q.find (fun elt -> Elt.equal elt target_elt) t
;;

(* Test collecting all elements within a range, from within a 1k elt tree *)
let test_range _ =
  let range = Box.box (Point.splat 50.) (Point.splat 100.) in
  let target_es = [ 80., 80.; 90., 90. ] in
  let es = rand_es 1_000 50. in
  let empty = Q.empty test_domain 32 in
  let t = Q.load empty @@ target_es @ es in
  let result_es = Q.range range t in
  assert_equal (List.length result_es) 2
;;

(* Test finding the nearest elt to a query point *)
let test_nearest _ =
  let es = rand_es 1_000 50. in
  let target, nearest = (90., 90.), (80., 80.) in
  let empty = Q.empty test_domain 32 in
  let t = Q.load empty @@ (target :: nearest :: es) in
  let nearest' = Option.value_exn @@ Q.nearest t @@ Point.splat (fst target) in
  assert_equal nearest nearest'
;;

(* Test mapping over elts in 1k elt tree *)
let test_map _ =
  let es = List.init 1_000 ~f:(float_of_int >> tuple_splat) in
  let t = Q.load (Q.empty test_domain 32) es in
  let t = Q.map (fun (x, _) -> tuple_splat @@ Num.succ x) t in
  Q.iter (fun (x, _) -> assert (Float.(1. <= x && x <= 1_000.))) t
;;

(* Test iterating over elts *)
let test_iter _ =
  let es = List.init 1_000 ~f:(float_of_int >> tuple_splat) in
  let t = Q.load (Q.empty test_domain 32) es in
  Q.iter (fst >> Float.(fun i -> 0. <= i && i <= 1_000.) >> assert') t
;;

(* Test filtering elts *)
let test_filter _ =
  let es = List.init 1_000 ~f:(float_of_int >> tuple_splat) in
  let t = Q.load (Q.empty test_domain 32) es in
  let t = Q.filter (fst >> is_even) t in
  Q.iter (fst >> is_even >> assert') t
;;

(* Test filter_map-ing elts *)
let test_filter_map _ =
  let es = List.init 1_000 ~f:(float_of_int >> tuple_splat) in
  let t = Q.load (Q.empty test_domain 32) es in
  let t =
    Q.filter_map
      (function
       | pair when is_even @@ fst pair -> Some pair
       | _ -> None)
      t
  in
  Q.iter (fst >> is_even >> assert') t
;;

let test_mem _ =
  let target = tuple_splat 50. in
  let t = Q.load (Q.empty test_domain 4) [ target ] in
  assert (Q.mem t target)
;;

let qt_suite =
  "Quadtree test suite"
  >::: [ "Test Box.intersects" >:: test_intersects
       ; "Test Box.contains" >:: test_contains
       ; "Test Quadtree.load && Quadtree.size" >:: test_size
       ; "Test Quadtree.load w/ 100,000 elts" >:: test_load_many
       ; "Test Quadtree.load w/ 1,000,000 elts" >:: test_load_lots
       ; "Test insert" >:: test_insert
       ; "Test remove" >:: test_remove
       ; "Test find" >:: test_find
       ; "Test range" >:: test_range
       ; "Test nearest" >:: test_nearest
       ; "Test map" >:: test_map
       ; "Test filter" >:: test_filter
       ; "Test filter_map" >:: test_filter_map
       ; "Test iter" >:: test_iter
       ; "Test mem" >:: test_mem
       ]
;;

let run () = run_test_tt_main qt_suite
