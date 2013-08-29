(**
This file is part of the Coquelicot formalization of real
analysis in Coq: http://coquelicot.saclay.inria.fr/

Copyright (C) 2011-2013 Sylvie Boldo
#<br />#
Copyright (C) 2011-2013 Catherine Lelay
#<br />#
Copyright (C) 2011-2013 Guillaume Melquiond

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
COPYING file for more details.
*)

Require Import Reals Rbar.
Require Import ssreflect.
Require Import Rcomplements.
Require Import List.

Open Scope R_scope.

(** * Filters *)

(** ** Definitions *)

Class Filter {T : Type} (F : (T -> Prop) -> Prop) := {
  filter_true : F (fun _ => True) ;
  filter_and : forall P Q : T -> Prop, F P -> F Q -> F (fun x => P x /\ Q x) ;
  filter_imp : forall P Q : T -> Prop, (forall x, P x -> Q x) -> F P -> F Q
}.

Class ProperFilter {T : Type} (F : (T -> Prop) -> Prop) := {
  filter_ex : forall P, F P -> exists x, P x ;
  filter_filter :> Filter F
}.

Lemma filter_forall :
  forall {T : Type} {F} {FF: @Filter T F} (P : T -> Prop),
  (forall x, P x) -> F P.
Proof.
intros T F FF P H.
apply filter_imp with (fun _ => True).
easy.
apply filter_true.
Qed.

Lemma filter_const :
  forall {T : Type} {F} {FF: @ProperFilter T F} (P : Prop),
  F (fun _ => P) -> P.
Proof.
intros T F FF P H.
destruct (filter_ex (fun _ => P) H) as [_ H'].
exact H'.
Qed.

Definition filter_le {T : Type} (F G : (T -> Prop) -> Prop) :=
  forall P, G P -> F P.

Lemma filter_le_refl :
  forall T F, @filter_le T F F.
Proof.
now intros T F P.
Qed.

Lemma filter_le_trans :
  forall T F G H, @filter_le T F G -> filter_le G H -> filter_le F H.
Proof.
intros T F G H FG GH P K.
now apply FG, GH.
Qed.

Definition filtermap {T U : Type} (f : T -> U) (F : (T -> Prop) -> Prop) :=
  fun P => F (fun x => P (f x)).

Global Instance filtermap_filter :
  forall T U (f : T -> U) (F : (T -> Prop) -> Prop),
  Filter F -> Filter (filtermap f F).
Proof.
intros T U f F FF.
unfold filtermap.
constructor.
- apply filter_true.
- intros P Q HP HQ.
  now apply filter_and.
- intros P Q H HP.
  unfold filtermap.
  apply (filter_imp (fun x => P (f x))).
  intros x Hx.
  now apply H.
  exact HP.
Qed.

(** ** Continuity expressed with filters *)

Definition filterlim {T U : Type} (f : T -> U) F G :=
  filter_le (filtermap f F) G.

Lemma filterlim_compose :
  forall T U V (f : T -> U) (g : U -> V) F G H,
  filterlim f F G -> filterlim g G H ->
  filterlim (fun x => g (f x)) F H.
Proof.
intros T U V f g F G H FG GH P HP.
unfold filtermap.
apply (FG (fun x => P (g x))).
now apply GH.
Qed.

Lemma filterlim_ext_loc :
  forall {T U F G} {FF : Filter F} (f g : T -> U),
  F (fun x => f x = g x) ->
  filterlim f F G ->
  filterlim g F G.
Proof.
intros T U F G FF f g Efg Lf P GP.
specialize (Lf P GP).
unfold filtermap.
generalize (filter_and _ _ Efg Lf).
apply filter_imp.
now intros x [-> H].
Qed.

Lemma filterlim_ext :
  forall {T U F G} {FF : Filter F} (f g : T -> U),
  (forall x, f x = g x) ->
  filterlim f F G ->
  filterlim g F G.
Proof.
intros T U F G FF f g Efg.
apply filterlim_ext_loc.
now apply filter_forall.
Qed.

(** ** Filters for pairs *)

Inductive filter_prod {T U : Type} (F G : _ -> Prop) (P : T * U -> Prop) : Prop :=
  Filter_prod (Q : T -> Prop) (R : U -> Prop) :
    F Q -> G R -> (forall x y, Q x -> R y -> P (x, y)) -> filter_prod F G P.

Global Instance filter_prod_filter :
  forall T U (F : (T -> Prop) -> Prop) (G : (U -> Prop) -> Prop),
  Filter F -> Filter G -> Filter (filter_prod F G).
Proof.
intros T U F G FF FG.
constructor.
- exists (fun _ => True) (fun _ => True).
  apply filter_true.
  apply filter_true.
  easy.
- intros P Q [AP BP P1 P2 P3] [AQ BQ Q1 Q2 Q3].
  exists (fun x => AP x /\ AQ x) (fun x => BP x /\ BQ x).
  now apply filter_and.
  now apply filter_and.
  intros x y [Px Qx] [Py Qy].
  split.
  now apply P3.
  now apply Q3.
- intros P Q HI [AP BP P1 P2 P3].
  exists AP BP ; try easy.
  intros x y Hx Hy.
  apply HI.
  now apply P3.
Qed.

Lemma filterlim_fst :
  forall {T U F G} {FG : Filter G},
  filterlim (@fst T U) (filter_prod F G) F.
Proof.
intros T U F G FG P HP.
exists P (fun _ => True) ; try easy.
apply filter_true.
Qed.

Lemma filterlim_snd :
  forall {T U F G} {FF : Filter F},
  filterlim (@snd T U) (filter_prod F G) G.
Proof.
intros T U F G FF P HP.
exists (fun _ => True) P ; try easy.
apply filter_true.
Qed.

Lemma filterlim_pair :
  forall {T U V F G H} {FF : Filter F},
  forall (f : T -> U) (g : T -> V),
  filterlim f F G ->
  filterlim g F H ->
  filterlim (fun x => (f x, g x)) F (filter_prod G H).
Proof.
intros T U V F G H FF f g Cf Cg P [A B GA HB HP].
unfold filtermap.
apply (filter_imp (fun x => A (f x) /\ B (g x))).
intros x [Af Bg].
now apply HP.
apply filter_and.
now apply Cf.
now apply Cg.
Qed.

Lemma filterlim_compose_2 :
  forall {T U V W F G H I} {FF : Filter F},
  forall (f : T -> U) (g : T -> V) (h : U -> V -> W),
  filterlim f F G ->
  filterlim g F H ->
  filterlim (fun x => h (fst x) (snd x)) (filter_prod G H) I ->
  filterlim (fun x => h (f x) (g x)) F I.
Proof.
intros T U V W F G H I FF f g h Cf Cg Ch.
change (fun x => h (f x) (g x)) with (fun x => h (fst (f x, g x)) (snd (f x, g x))).
apply: filterlim_compose Ch.
now apply filterlim_pair.
Qed.

(** ** Open sets using filters *)

Definition open_for {T} (F : T -> ((T -> Prop) -> Prop)) (D : T -> Prop) :=
  forall x, D x -> F x D.

Lemma open_true :
  forall {T F} {FF : forall x : T, Filter (F x)},
  open_for F (fun x => True).
Proof.
intros T F FF x _.
apply filter_true.
Qed.

Lemma open_and :
  forall {T F} {FF : forall x : T, Filter (F x)} D E,
  open_for F D -> open_for F E -> open_for F (fun x => D x /\ E x).
Proof.
intros T F FF D E HD HE x [Dx Ex].
specialize (HD _ Dx).
specialize (HE _ Ex).
now apply filter_and.
Qed.

Lemma open_or :
  forall {T F} {FF : forall x : T, Filter (F x)} D E,
  open_for F D -> open_for F E -> open_for F (fun x => D x \/ E x).
Proof.
intros T F FF D E HD HE x [Dx|Ex].
specialize (HD _ Dx).
apply: filter_imp HD.
now left.
specialize (HE _ Ex).
apply: filter_imp HE.
now right.
Qed.

(** ** Specific filters *)

(** Eventually = "for integers large enough" *)

Definition eventually (P : nat -> Prop) :=
  exists N : nat, forall n, (N <= n)%nat -> P n.

Global Instance eventually_filter : ProperFilter eventually.
Proof.
constructor.
  intros P [N H].
  exists N.
  apply H.
  apply le_refl.
constructor.
- now exists 0%nat.
- intros P Q [NP HP] [NQ HQ].
  exists (max NP NQ).
  intros n Hn.
  split.
  apply HP.
  apply le_trans with (2 := Hn).
  apply Max.le_max_l.
  apply HQ.
  apply le_trans with (2 := Hn).
  apply Max.le_max_r.
- intros P Q H [NP HP].
  exists NP.
  intros n Hn.
  apply H.
  now apply HP.
Qed.

(** Restriction of a filter to a domain *)

Definition within {T : Type} D (F : (T -> Prop) -> Prop) (P : T -> Prop) :=
  F (fun x => D x -> P x).

Global Instance within_filter :
  forall T D F, Filter F -> Filter (@within T D F).
Proof.
intros T D F FF.
unfold within.
constructor.
- now apply filter_forall.
- intros P Q WP WQ.
  apply filter_imp with (fun x => (D x -> P x) /\ (D x -> Q x)).
  intros x [HP HQ] HD.
  split.
  now apply HP.
  now apply HQ.
  now apply filter_and.
- intros P Q H FP.
  apply filter_imp with (fun x => (D x -> P x) /\ (P x -> Q x)).
  intros x [H1 H2] HD.
  apply H2, H1, HD.
  apply filter_and.
  exact FP.
  now apply filter_forall.
Qed.

(** * Metric spaces *)

Class MetricSpace T := {
  distance : T -> T -> R ;
  distance_refl : forall a, distance a a = 0 ;
  distance_comm : forall a b, distance a b = distance b a ;
  distance_triangle : forall a b c, distance a c <= distance a b + distance b c
}.

Lemma distance_ge_0 :
  forall {T} {MT : MetricSpace T} (a b : T),
  0 <= distance a b.
Proof.
intros T MT a b.
apply Rmult_le_reg_l with 2.
apply Rlt_0_2.
rewrite Rmult_0_r.
rewrite -(distance_refl a).
rewrite Rmult_plus_distr_r Rmult_1_l.
rewrite -> (distance_comm a b) at 2.
apply distance_triangle.
Qed.

(** ** Filters for open balls *)

Definition locally_dist {T : Type} (d : T -> R) (P : T -> Prop) :=
  exists delta : posreal, forall y, d y < delta -> P y.

Global Instance locally_dist_filter :
  forall T (d : T -> R), Filter (locally_dist d).
Proof.
intros T d.
constructor.
- now exists (mkposreal _ Rlt_0_1).
- intros P Q [dP HP] [dQ HQ].
  exists (mkposreal _ (Rmin_stable_in_posreal dP dQ)).
  simpl.
  intros y Hy.
  split.
  apply HP.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_l.
  apply HQ.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy.
  apply H.
  now apply HP.
Qed.

Definition locally {T} {MT : MetricSpace T} (x : T) :=
  locally_dist (distance x).

Global Instance locally_filter :
  forall T (MT : MetricSpace T) (x : T), ProperFilter (locally x).
Proof.
intros T MT x.
constructor.
  intros P [eps H].
  exists x.
  apply H.
  rewrite distance_refl.
  apply cond_pos.
apply locally_dist_filter.
Qed.

Definition locally' {T} {MT : MetricSpace T} (x : T) (P : T -> Prop) :=
  locally_dist (distance x) (fun y => y <> x -> P y).

Global Instance locally'_filter :
  forall T (MT : MetricSpace T) (x : T), Filter (locally' x).
Proof.
intros T MT x.
constructor.
- now exists (mkposreal _ Rlt_0_1).
- intros P Q [dP HP] [dQ HQ].
  exists (mkposreal _ (Rmin_stable_in_posreal dP dQ)).
  simpl.
  intros y Hy Hy'.
  split.
  apply HP with (2 := Hy').
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_l.
  apply HQ with (2 := Hy').
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy Hy'.
  apply H.
  now apply HP.
Qed.

(** ** [R] is a metric space *)

Definition distR x y := Rabs (y - x).

Lemma distR_refl :
  forall x, distR x x = 0.
Proof.
intros x.
rewrite /distR /Rminus Rplus_opp_r.
apply Rabs_R0.
Qed.

Lemma distR_comm :
  forall x y, distR x y = distR y x.
Proof.
intros x y.
apply Rabs_minus_sym.
Qed.

Lemma distR_triangle :
  forall x y z, distR x z <= distR x y + distR y z.
Proof.
intros x y z.
unfold distR.
replace (z - x) with (y - x + (z - y)) by ring.
apply Rabs_triang.
Qed.

Global Instance R_metric : MetricSpace R.
Proof.
apply (Build_MetricSpace R distR).
- exact distR_refl.
- exact distR_comm.
- exact distR_triangle.
Defined.

Notation at_left x := (within (fun u : R => Rlt u x) (locally (x)%R)).
Notation at_right x := (within (fun u : R => Rlt x u) (locally (x)%R)).

(** ** Products of metric spaces *)

Fixpoint Tn (n : nat) (T : Type) : Type :=
  match n with
  | O => unit
  | S n => prod T (Tn n T)
  end.

Fixpoint Fn (n : nat) (T U : Type) : Type :=
  match n with
  | O => U
  | S n => T -> Fn n T U
  end.

Definition dist_prod {T U : Type} (dT : T -> T -> R) (dU : U -> U -> R) (x y : T * U) :=
  Rmax (dT (fst x) (fst y)) (dU (snd x) (snd y)).

Lemma dist_prod_refl :
  forall {T U} {MT : MetricSpace T} {MU : MetricSpace U} (x : T * U),
  dist_prod distance distance x x = 0.
Proof.
intros T U MT MU [xt xu].
unfold dist_prod.
apply Rmax_case ; apply distance_refl.
Qed.

Lemma dist_prod_comm :
  forall {T U} {MT : MetricSpace T} {MU : MetricSpace U} (x y : T * U),
  dist_prod distance distance x y = dist_prod distance distance y x.
Proof.
intros T U MT MU [xt xu] [yt yu].
unfold dist_prod.
rewrite distance_comm.
apply f_equal.
apply distance_comm.
Qed.

Lemma dist_prod_triangle :
  forall {T U} {MT : MetricSpace T} {MU : MetricSpace U} (x y z : T * U),
  dist_prod distance distance x z <= dist_prod distance distance x y + dist_prod distance distance y z.
Proof.
intros T U MT MU [xt xu] [yt yu] [zt zu].
unfold dist_prod.
apply Rmax_case.
apply Rle_trans with (distance xt yt + distance yt zt).
apply distance_triangle.
apply Rplus_le_compat ; apply Rmax_l.
apply Rle_trans with (distance xu yu + distance yu zu).
apply distance_triangle.
apply Rplus_le_compat ; apply Rmax_r.
Qed.

Global Instance prod_metric : forall T U, MetricSpace T -> MetricSpace U -> MetricSpace (T * U).
Proof.
intros T U MT MU.
apply (Build_MetricSpace _ (dist_prod distance distance)).
- exact dist_prod_refl.
- exact dist_prod_comm.
- exact dist_prod_triangle.
Defined.

Fixpoint dist_pow (n : nat) (T : Type) (d : T -> T -> R) : Tn n T -> Tn n T -> R :=
  match n with
  | O => fun _ _ => 0
  | S n => fun x y =>
    Rmax (d (fst x) (fst y)) (dist_pow n T d (snd x) (snd y))
  end.

Lemma dist_pow_refl :
  forall {T} {MT : MetricSpace T} n x,
  dist_pow n T distance x x = 0.
Proof.
induction n.
reflexivity.
intros [x xn].
simpl.
rewrite distance_refl IHn.
now apply Rmax_case.
Qed.

Lemma dist_pow_comm :
  forall {T} {MT : MetricSpace T} n x y,
  dist_pow n T distance x y = dist_pow n T distance y x.
Proof.
induction n.
reflexivity.
intros [x xn] [y yn].
simpl.
now rewrite distance_comm IHn.
Qed.

Lemma dist_pow_triangle :
  forall {T} {MT : MetricSpace T} n x y z,
  dist_pow n T distance x z <= dist_pow n T distance x y +  dist_pow n T distance y z.
Proof.
induction n.
simpl.
intros _ _ _.
rewrite Rplus_0_r.
apply Rle_refl.
intros [x xn] [y yn] [z zn].
simpl.
apply Rmax_case.
apply Rle_trans with (1 := distance_triangle x y z).
apply Rplus_le_compat ; apply Rmax_l.
apply Rle_trans with (1 := IHn xn yn zn).
apply Rplus_le_compat ; apply Rmax_r.
Qed.

Global Instance pow_metric : forall T, MetricSpace T -> forall n, MetricSpace (Tn n T).
Proof.
intros T MT n.
apply (Build_MetricSpace _ (dist_pow n T distance)).
- exact (dist_pow_refl n).
- exact (dist_pow_comm n).
- exact (dist_pow_triangle n).
Defined.

(** ** Currified variant of locally for R^2 *)

Definition locally_2d (P : R -> R -> Prop) x y :=
  exists delta : posreal, forall u v, Rabs (u - x) < delta -> Rabs (v - y) < delta -> P u v.

Lemma locally_2d_locally :
  forall P x y,
  locally_2d P x y <-> locally (x,y) (fun z => P (fst z) (snd z)).
Proof.
intros P x y.
split ; intros [d H] ; exists d.
- rewrite /= /distR.
  intros [u v] H'.
  apply H.
  apply Rle_lt_trans with (2 := H').
  apply Rmax_l.
  apply Rle_lt_trans with (2 := H').
  apply Rmax_r.
- intros u v Hu Hv.
  rewrite /= /dist_prod /distR in H.
  apply (H (u,v)).
  now apply Rmax_case.
Qed.

Lemma locally_2d_locally' :
  forall P x y,
  locally_2d P x y <-> locally ((x,(y,tt)) : Tn 2 R) (fun z : Tn 2 R => P (fst z) (fst (snd z))).
Proof.
intros P x y.
split ; intros [d H] ; exists d.
- rewrite /= /distR.
  move => [u [v t]] /= {t} H'.
  apply H.
  apply Rle_lt_trans with (2 := H').
  apply Rmax_l.
  apply Rle_lt_trans with (2 := H').
  rewrite (Rmax_left _ 0).
  apply Rmax_r.
  apply Rabs_pos.
- intros u v Hu Hv.
  rewrite /= /distR in H.
  apply (H (u,(v,tt))).
  apply Rmax_case.
  exact Hu.
  apply Rmax_case.
  exact Hv.
  apply cond_pos.
Qed.

Lemma locally_2d_align :
  forall (P Q : R -> R -> Prop) x y,
  ( forall eps : posreal, (forall u v, Rabs (u - x) < eps -> Rabs (v - y) < eps -> P u v) ->
    forall u v, Rabs (u - x) < eps -> Rabs (v - y) < eps -> Q u v ) ->
  locally_2d P x y -> locally_2d Q x y.
Proof.
intros P Q x y K (d,H).
exists d => u v Hu Hv.
now apply (K d).
Qed.

Lemma locally_open :
  forall {T} {MT : MetricSpace T} x (P : T -> Prop),
  locally x P -> locally x (fun y => locally y P).
Proof.
intros T MT x P [dp Hp].
exists dp.
intros y Hy.
exists (mkposreal _ (Rlt_Rminus _ _ Hy)) => /= z Hz.
apply Hp.
apply Rle_lt_trans with (1 := distance_triangle x y z).
replace (pos dp) with (distance x y + (dp - distance x y)) by ring.
now apply Rplus_lt_compat_l.
Qed.

Lemma locally_singleton :
  forall {T} {MT : MetricSpace T} x (P : T -> Prop),
  locally x P -> P x.
Proof.
intros T MT P x [dp H].
apply H.
rewrite distance_refl.
apply cond_pos.
Qed.

Lemma locally_2d_impl_strong :
  forall (P Q : R -> R -> Prop) x y, locally_2d (fun u v => locally_2d P u v -> Q u v) x y ->
  locally_2d P x y -> locally_2d Q x y.
Proof.
intros P Q x y Li LP.
apply locally_2d_locally in Li.
apply locally_2d_locally in LP.
apply locally_open in LP.
apply locally_2d_locally.
generalize (filter_and _ _ Li LP).
apply: filter_imp.
intros [u v] [H1 H2].
apply H1.
now apply locally_2d_locally.
Qed.

Lemma locally_2d_singleton :
  forall (P : R -> R -> Prop) x y, locally_2d P x y -> P x y.
Proof.
intros P x y LP.
apply locally_2d_locally in LP.
apply: locally_singleton LP.
Qed.

Lemma locally_2d_impl :
  forall (P Q : R -> R -> Prop) x y, locally_2d (fun u v => P u v -> Q u v) x y ->
  locally_2d P x y -> locally_2d Q x y.
Proof.
intros P Q x y (d,H).
apply locally_2d_impl_strong.
exists d => u v Hu Hv Hp.
apply H => //.
now apply locally_2d_singleton.
Qed.

Lemma locally_2d_forall :
  forall (P : R -> R -> Prop) x y, (forall u v, P u v) -> locally_2d P x y.
Proof.
intros P x y Hp.
now exists (mkposreal _ Rlt_0_1) => u v _ _.
Qed.

Lemma locally_2d_and :
  forall (P Q : R -> R -> Prop) x y, locally_2d P x y -> locally_2d Q x y ->
  locally_2d (fun u v => P u v /\ Q u v) x y.
Proof.
intros P Q x y H.
apply: locally_2d_impl.
apply: locally_2d_impl H.
apply locally_2d_forall.
now split.
Qed.

Lemma locally_2d_1d_const_x :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally y (fun t => P x t).
Proof.
intros P x y (d,Hd).
exists d; intros z Hz.
apply Hd.
rewrite Rminus_eq_0 Rabs_R0; apply cond_pos.
exact Hz.
Qed.

Lemma locally_2d_1d_const_y :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally x (fun t => P t y).
Proof.
intros P x y (d,Hd).
exists d; intros z Hz.
apply Hd.
exact Hz.
rewrite Rminus_eq_0 Rabs_R0; apply cond_pos.
Qed.

Lemma locally_2d_1d_strong :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally_2d (fun u v => forall t, 0 <= t <= 1 ->
    locally t (fun z => locally_2d P (x + z * (u - x)) (y + z * (v - y)))) x y.
Proof.
intros P x y.
apply locally_2d_align => eps HP u v Hu Hv t Ht.
assert (Zm: 0 <= Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmax_case ; apply Rabs_pos.
destruct Zm as [Zm|Zm].
(* *)
assert (H1: Rmax (Rabs (u - x)) (Rabs (v - y)) < eps).
now apply Rmax_case.
set (d1 := mkposreal _ (Rlt_Rminus _ _ H1)).
assert (H2: 0 < pos_div_2 d1 / Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmult_lt_0_compat.
apply cond_pos.
now apply Rinv_0_lt_compat.
set (d2 := mkposreal _ H2).
exists d2 => z Hz.
exists (pos_div_2 d1) => p q Hp Hq.
apply HP.
(* . *)
replace (p - x) with (p - (x + z * (u - x)) + (z - t + t) * (u - x)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
replace (pos eps) with (pos_div_2 d1 + (eps - pos_div_2 d1)) by ring.
apply Rplus_lt_le_compat with (1 := Hp).
rewrite Rabs_mult.
apply Rle_trans with ((d2 + 1) * Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmult_le_compat.
apply Rabs_pos.
apply Rabs_pos.
apply Rle_trans with (1 := Rabs_triang _ _).
apply Rplus_le_compat.
now apply Rlt_le.
now rewrite Rabs_pos_eq.
apply Rmax_l.
rewrite /d2 /d1 /=.
field_simplify.
apply Rle_refl.
now apply Rgt_not_eq.
(* . *)
replace (q - y) with (q - (y + z * (v - y)) + (z - t + t) * (v - y)) by ring.
apply Rle_lt_trans with (1 := Rabs_triang _ _).
replace (pos eps) with (pos_div_2 d1 + (eps - pos_div_2 d1)) by ring.
apply Rplus_lt_le_compat with (1 := Hq).
rewrite Rabs_mult.
apply Rle_trans with ((d2 + 1) * Rmax (Rabs (u - x)) (Rabs (v - y))).
apply Rmult_le_compat.
apply Rabs_pos.
apply Rabs_pos.
apply Rle_trans with (1 := Rabs_triang _ _).
apply Rplus_le_compat.
now apply Rlt_le.
now rewrite Rabs_pos_eq.
apply Rmax_r.
rewrite /d2 /d1 /=.
field_simplify.
apply Rle_refl.
now apply Rgt_not_eq.
(* *)
apply: filter_forall => z.
exists eps => p q.
replace (u - x) with 0.
replace (v - y) with 0.
rewrite Rmult_0_r 2!Rplus_0_r.
apply HP.
apply sym_eq.
apply Rabs_eq_0.
apply Rle_antisym.
rewrite Zm.
apply Rmax_r.
apply Rabs_pos.
apply sym_eq.
apply Rabs_eq_0.
apply Rle_antisym.
rewrite Zm.
apply Rmax_l.
apply Rabs_pos.
Qed.

Lemma locally_2d_1d :
  forall (P : R -> R -> Prop) x y,
  locally_2d P x y ->
  locally_2d (fun u v => forall t, 0 <= t <= 1 -> locally_2d P (x + t * (u - x)) (y + t * (v - y))) x y.
Proof.
intros P x y H.
apply locally_2d_1d_strong in H.
apply: locally_2d_impl H.
apply locally_2d_forall => u v H t Ht.
specialize (H t Ht).
apply: locally_singleton H.
Qed.

(** ** Relations between filters and continuity over R. *)

Lemma filterlim_locally :
  forall {T U} {MU : MetricSpace U} {F} {FF : Filter F} (f : T -> U) y,
  filterlim f F (locally y) <->
  forall eps : posreal, F (fun x => distance y (f x) < eps).
Proof.
intros T U MU F FF f y.
unfold filterlim, filter_le, filtermap.
split.
- intros Cf eps.
  apply (Cf (fun x => distance y x < eps)).
  now exists eps.
- intros Cf P [eps He].
  apply: filter_imp (Cf eps).
  intros t.
  apply He.
Qed.

Lemma continuity_pt_locally :
  forall f x,
  continuity_pt f x <->
  forall eps : posreal, locally x (fun u => Rabs (f u - f x) < eps).
Proof.
intros f x.
split.
intros H eps.
move: (H eps (cond_pos eps)) => {H} [d [H1 H2]].
rewrite /= /R_dist /D_x /no_cond in H2.
exists (mkposreal d H1) => y H.
destruct (Req_dec x y) as [<-|Hxy].
rewrite /Rminus Rplus_opp_r Rabs_R0.
apply cond_pos.
by apply H2.
intros H eps He.
move: (H (mkposreal _ He)) => {H} [d H].
exists d.
split.
apply cond_pos.
intros h [Zh Hh].
exact: H.
Qed.

Lemma continuity_pt_locally' :
  forall f x,
  continuity_pt f x <->
  forall eps : posreal, locally' x (fun u => Rabs (f u - f x) < eps).
Proof.
intros f x.
split.
intros H eps.
move: (H eps (cond_pos eps)) => {H} [d [H1 H2]].
rewrite /= /R_dist /D_x /no_cond in H2.
exists (mkposreal d H1) => y H H'.
destruct (Req_dec x y) as [<-|Hxy].
rewrite /Rminus Rplus_opp_r Rabs_R0.
apply cond_pos.
by apply H2.
intros H eps He.
move: (H (mkposreal _ He)) => {H} [d H].
exists d.
split.
apply cond_pos.
intros h [Zh Hh].
apply H.
exact Hh.
apply proj2 in Zh.
now contradict Zh.
Qed.

Lemma continuity_pt_filterlim :
  forall f x,
  continuity_pt f x <->
  filterlim f (locally x) (locally (f x)).
Proof.
intros f x.
eapply iff_trans.
apply continuity_pt_locally.
apply iff_sym.
apply: filterlim_locally.
Qed.

Lemma continuity_pt_filterlim' :
  forall f x,
  continuity_pt f x <->
  filterlim f (locally' x) (locally (f x)).
Proof.
intros f x.
eapply iff_trans.
apply continuity_pt_locally'.
apply iff_sym.
apply: filterlim_locally.
Qed.

Lemma locally_comp (P : R -> Prop) (f : R -> R) (x : R) :
  locally (f x) P -> continuity_pt f x ->
  locally x (fun x => P (f x)).
Proof.
intros Lf Cf.
apply continuity_pt_filterlim in Cf.
now apply Cf.
Qed.

(** ** Intervals *)

Lemma locally_interval (P : R -> Prop) (x : R) (a b : Rbar) :
  Rbar_lt a x -> Rbar_lt x b ->
  (forall (y : R), Rbar_lt a y -> Rbar_lt y b -> P y) ->
  locally x P.
Proof.
  move => Hax Hxb Hp.
  case: (Rbar_lt_locally _ _ _ Hax Hxb) => d Hd.
  exists d => y Hy.
  apply Hp ; by apply Hd.
Qed.

(** * locally in Set *)

Require Import Markov Lub.

Lemma locally_ex_dec :
  forall P (x : R),
  (forall x, P x \/ ~P x) ->
  locally x P ->
  {d:posreal | forall y, Rabs (y-x) < d -> P y}.
Proof.
intros P x P_dec H.
set (Q := fun z => forall y,  Rabs (y-x) < z -> P y).
destruct (ex_lub_Rbar_ne Q) as ([d| |],(H1,H2)).
destruct H as (d1,Hd1).
now exists d1.
(* *)
assert (Zd: 0 < d).
destruct H as (d1,Hd1).
apply Rlt_le_trans with (1 := cond_pos d1).
apply Rbar_finite_le.
now apply H1.
exists (mkposreal d Zd).
simpl.
intros y Hy.
destruct (P_dec y) as [Py|Py].
exact Py.
elim (Rlt_not_le _ _ Hy).
apply Rbar_finite_le.
apply H2.
intros u Hu.
apply Rbar_finite_le.
apply Rnot_lt_le.
contradict Py.
now apply Hu.
(* *)
exists (mkposreal 1 Rlt_0_1).
simpl.
intros y Hy.
destruct (P_dec y) as [Py|Py].
exact Py.
elim (Rlt_not_le _ _ Hy).
apply Rbar_finite_le.
apply Rbar_le_trans with p_infty.
now left.
apply H2.
intros u Hu.
apply Rbar_finite_le.
apply Rnot_lt_le.
contradict Py.
now apply Hu.
(* *)
elimtype False.
destruct H as (d1,Hd1).
now destruct (H1 d1).
Qed.

Lemma locally_2d_ex_dec: forall P x y, (forall x y, P x y \/ ~P x y) -> locally_2d P x y
   -> {d:posreal| forall u v, Rabs (u-x) < d -> Rabs (v-y) < d -> P u v}.
Proof.
intros P x y P_dec H.
set (Q := fun z => forall u v,   Rabs (u-x) < z -> Rabs (v-y) < z -> P u v).
destruct (ex_lub_Rbar_ne Q) as ([d| |],(H1,H2)).
destruct H as (d1,Hd1).
now exists d1.
(* *)
assert (Zd: 0 < d).
destruct H as (d1,Hd1).
apply Rlt_le_trans with (1 := cond_pos d1).
apply Rbar_finite_le.
now apply H1.
exists (mkposreal d Zd).
simpl.
intros u v Hu Hv.
destruct (P_dec  u v) as [Puv|Puv].
exact Puv.
assert (Hi:(Rmax (Rabs (u - x)) (Rabs (v - y)) < d)).
now apply Rmax_case.
elim (Rlt_not_le _ _ Hi).
apply Rbar_finite_le.
apply H2.
intros z Hz.
apply Rbar_finite_le.
apply Rnot_lt_le.
contradict Puv.
apply Hz.
apply Rle_lt_trans with (2:=Puv).
apply Rmax_l.
apply Rle_lt_trans with (2:=Puv).
apply Rmax_r.
(* *)
exists (mkposreal 1 Rlt_0_1).
simpl.
intros u v Hu Hv.
destruct (P_dec u v) as [Puv|Puv].
exact Puv.
assert (Hi:(Rmax (Rabs (u - x)) (Rabs (v - y)) < 1)).
now apply Rmax_case.
elim (Rlt_not_le _ _ Hi).
apply Rbar_finite_le.
apply Rbar_le_trans with p_infty.
now left.
apply H2.
intros z Hz.
apply Rbar_finite_le.
apply Rnot_lt_le.
contradict Puv.
apply Hz.
apply Rle_lt_trans with (2:=Puv).
apply Rmax_l.
apply Rle_lt_trans with (2:=Puv).
apply Rmax_r.
(* *)
elimtype False.
destruct H as (d1,Hd1).
now destruct (H1 d1).
Qed.

Lemma derivable_pt_lim_locally :
  forall f x l,
  derivable_pt_lim f x l <->
  forall eps : posreal, locally x (fun y => y <> x -> Rabs ((f y - f x) / (y - x) - l) < eps).
Proof.
intros f x l.
split.
intros H eps.
move: (H eps (cond_pos eps)) => {H} [d H].
exists d => y Hy Zy.
specialize (H (y - x) (Rminus_eq_contra _ _ Zy) Hy).
now ring_simplify (x + (y - x)) in H.
intros H eps He.
move: (H (mkposreal _ He)) => {H} /= [d H].
exists d => h Zh Hh.
simpl in H.
unfold distR in H.
specialize (H (x + h)).
ring_simplify (x + h - x) in H.
apply H => //.
contradict Zh.
apply Rplus_eq_reg_l with x.
now rewrite Rplus_0_r.
Qed.

(** * Filters for Rbar *)

Definition Rbar_locally (a : Rbar) (P : R -> Prop) :=
  match a with
    | Finite a => exists delta : posreal, 
	forall x, Rabs (x-a) < delta -> x <> a -> P x
    | p_infty => exists M : R, forall x, M < x -> P x
    | m_infty => exists M : R, forall x, x < M -> P x
  end.

Global Instance Rbar_locally_filter :
  forall x, ProperFilter (Rbar_locally x).
Proof.
intros [x| |] ; (constructor ; [idtac | constructor]).
- intros P [eps HP].
  exists (x + eps / 2).
  apply HP.
  ring_simplify (x + eps / 2 - x).
  rewrite Rabs_pos_eq.
  apply Rminus_lt_0.
  replace (eps - eps / 2) with (eps / 2) by field.
  apply is_pos_div_2.
  apply Rlt_le, is_pos_div_2.
  apply Rgt_not_eq, Rminus_lt_0 ; ring_simplify.
  apply is_pos_div_2.
- now exists (mkposreal _ Rlt_0_1).
- intros P Q [dP HP] [dQ HQ].
  exists (mkposreal _ (Rmin_stable_in_posreal dP dQ)).
  simpl.
  intros y Hy H.
  split.
  apply HP with (2 := H).
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_l.
  apply HQ with (2 := H).
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy H'.
  apply H.
  now apply HP.
- intros P [N HP].
  exists (N + 1).
  apply HP.
  apply Rlt_plus_1.
- now exists 0.
- intros P Q [MP HP] [MQ HQ].
  exists (Rmax MP MQ).
  intros y Hy.
  split.
  apply HP.
  apply Rle_lt_trans with (2 := Hy).
  apply Rmax_l.
  apply HQ.
  apply Rle_lt_trans with (2 := Hy).
  apply Rmax_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy.
  apply H.
  now apply HP.
- intros P [N HP].
  exists (N - 1).
  apply HP.
  apply Rlt_minus_l, Rlt_plus_1.
- now exists 0.
- intros P Q [MP HP] [MQ HQ].
  exists (Rmin MP MQ).
  intros y Hy.
  split.
  apply HP.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_l.
  apply HQ.
  apply Rlt_le_trans with (1 := Hy).
  apply Rmin_r.
- intros P Q H [dP HP].
  exists dP.
  intros y Hy.
  apply H.
  now apply HP.
Qed.

Definition Rbar_locally' (a : Rbar) (P : R -> Prop) :=
  match a with
    | Finite a => exists delta : posreal,
	forall x, Rabs (x-a) < delta -> P x
    | p_infty => exists M : R, forall x, M < x -> P x
    | m_infty => exists M : R, forall x, x < M -> P x
  end.

Global Instance Rbar_locally'_filter :
  forall x, ProperFilter (Rbar_locally' x).
Proof.
intros [x| |].
- apply: locally_filter.
- exact (Rbar_locally_filter p_infty).
- exact (Rbar_locally_filter m_infty).
Qed.

Lemma Rbar_locally_le :
  forall x, filter_le (Rbar_locally x) (Rbar_locally' x).
Proof.
intros [x| |] P [eps HP] ; exists eps ; intros ; now apply HP.
Qed.

Lemma Rbar_locally_le_finite :
  forall x : R, filter_le (Rbar_locally x) (locally x).
Proof.
intros x P [eps HP] ; exists eps ; intros ; now apply HP.
Qed.

Lemma open_Rbar_lt :
  forall y, open_for Rbar_locally' (fun u => Rbar_lt u y).
Proof.
intros [y| |].
- intros [x| |] Hxy.
  apply Rminus_lt_0 in Hxy.
  exists (mkposreal _ Hxy).
  simpl.
  intros u Hu.
  apply Rabs_lt_between in Hu.
  apply Rplus_lt_reg_r with (1 := proj2 Hu).
  easy.
  now exists y.
- intros x _.
  now apply filter_forall.
- intros x Hx.
  now destruct x.
Qed.

Lemma open_Rbar_gt :
  forall y, open_for Rbar_locally' (fun u => Rbar_lt y u).
Proof.
intros [y| |].
- intros [x| |] Hxy.
  apply Rminus_lt_0 in Hxy.
  exists (mkposreal _ Hxy).
  simpl.
  intros u Hu.
  apply Rabs_lt_between in Hu.
  apply Rplus_lt_reg_r with (- x).
  generalize (proj1 Hu).
  now rewrite Ropp_minus_distr.
  now exists y.
  easy.
- intros x Hx.
  now destruct x.
- intros x _.
  now apply filter_forall.
Qed.

(** A particular sequence converging to a point *)

Definition Rbar_loc_seq (x : Rbar) (n : nat) := match x with
    | Finite x => x + / (INR n + 1)
    | p_infty => INR n
    | m_infty => - INR n
  end.

Lemma filterlim_Rbar_loc_seq :
  forall x, filterlim (Rbar_loc_seq x) eventually (Rbar_locally x).
Proof.
  intros x P.
  unfold Rbar_loc_seq.
  case: x => /= [x | | ] [delta Hp].
(* x \in R *)
  case: (nfloor_ex (/delta)) => [ | N [_ HN]].
  by apply Rlt_le, Rinv_0_lt_compat, delta.
  exists N => n Hn.
  apply Hp.
  ring_simplify (x + / (INR n + 1) - x).
  rewrite Rabs_pos_eq.
  rewrite -(Rinv_involutive delta).
  apply Rinv_lt_contravar.
  apply Rmult_lt_0_compat.
  apply Rinv_0_lt_compat.
  by apply delta.
  exact: INRp1_pos.
  apply Rlt_le_trans with (1 := HN).
  by apply Rplus_le_compat_r, le_INR.
  by apply Rgt_not_eq, delta.
  by apply Rlt_le, RinvN_pos.
  apply Rgt_not_eq, Rminus_lt_0.
  ring_simplify.
  by apply RinvN_pos.
(* x = p_infty *)
  case: (nfloor_ex (Rmax 0 delta)) => [ | N [_ HN]].
  by apply Rmax_l.
  exists (S N) => n Hn.
  apply Hp.
  apply Rle_lt_trans with (1 := Rmax_r 0 _).
  apply Rlt_le_trans with (1 := HN).
  rewrite -S_INR ; by apply le_INR.
(* x = m_infty *)
  case: (nfloor_ex (Rmax 0 (-delta))) => [ | N [_ HN]].
  by apply Rmax_l.
  exists (S N) => n Hn.
  apply Hp.
  rewrite -(Ropp_involutive delta).
  apply Ropp_lt_contravar.
  apply Rle_lt_trans with (1 := Rmax_r 0 _).
  apply Rlt_le_trans with (1 := HN).
  rewrite -S_INR ; by apply le_INR.
Qed.
