

const Coord = struct{x:usize, y:usize};
pub fn walkUp(x:usize,y:usize)?Coord{}
pub fn walkRight(x:usize,y:usize)?Coord{}
pub fn walkDown(x:usize,y:usize)?Coord{}
pub fn walkLeft(x:usize,y:usize)?Coord{}

pub fn walkFurthestUp(x:usize,y:usize)Coord{}
pub fn walkFurthestRight(x:usize,y:usize)Coord{}
pub fn walkFurthestDown(x:usize,y:usize)Coord{}
pub fn walkFurthestLeft(x:usize,y:usize)Coord{}