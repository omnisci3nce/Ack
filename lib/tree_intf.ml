module type Scalar = sig
  type t

  val one : t
  val succ : t -> t
  val add : t -> t -> t
  val sub : t -> t -> t
  val mul : t -> t -> t
  val div : t -> t -> t
end

module type Point2D = sig
  type n
  type t = { x : n; y : n }

  val two : n
  val point : n -> n -> t
  val splat : n -> t
  val map : (n -> n) -> t -> t
  val map2 : (n -> n -> n) -> t -> t -> t
  val iter : (n -> unit) -> t -> unit
  val to_tuple : t -> n * n
  val ( +~ ) : t -> t -> t
  val ( -~ ) : t -> t -> t
  val ( *~ ) : t -> t -> t
  val ( /~ ) : t -> t -> t
  val ( +! ) : t -> n -> t
  val ( -! ) : t -> n -> t
  val ( *! ) : t -> n -> t
  val ( /! ) : t -> n -> t
end

module type Point3D = sig
  type n
  type t = { x : n; y : n; z : n }

  val two : n
  val point : n -> n -> n -> t
  val splat : n -> t
  val map : (n -> n) -> t -> t
  val map2 : (n -> n -> n) -> t -> t -> t
  val iter : (n -> unit) -> t -> unit
  val to_tuple : t -> n * n * n
  val ( +~ ) : t -> t -> t
  val ( -~ ) : t -> t -> t
  val ( *~ ) : t -> t -> t
  val ( /~ ) : t -> t -> t
  val ( +! ) : t -> n -> t
  val ( -! ) : t -> n -> t
  val ( *! ) : t -> n -> t
  val ( /! ) : t -> n -> t
end

module type Box2D = sig
  type t
  type n
  type point

  val box : point -> point -> t
  val midpoint : t -> point
  val split : t -> t * t * t * t
  val contains : t -> point -> bool
  val intersects : t -> t -> bool
end

module type Box3D = sig
  type t
  type n
  type point

  val box : point -> point -> t
  val midpoint : t -> point
  val split : t -> t * t * t * t * t * t * t * t
  val contains : t -> point -> bool
  val intersects : t -> t -> bool
end

module type Element = sig
  type t
  type n

  val position : t -> n * n
end

module type Quadtree = sig
  module Point : Point2D
  module Box : Box2D

  type elt
  type n
  type t

  val empty : Box.t -> int -> t
  val load : t -> elt list -> t
  val insert : t -> elt -> t
  val remove : t -> elt -> t
  val find : (elt -> bool) -> t -> elt option
  val range : Box.t -> t -> elt list
  val nearest : t -> Point.t -> elt option
  val map : (elt -> elt) -> t -> t
  val iter : (elt -> unit) -> t -> unit
  val filter : (elt -> bool) -> t -> t
  val filter_map : (elt -> elt option) -> t -> t
end