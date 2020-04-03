/***
* Name: neighbors
* Author: MaxEx
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model neighbors

global {

}


grid base neighbors:4{

	list<base> neighbors_ud1;//上下领域
	list<base> neighbors_lr1;//左右领域
	list<base> neighbors_udlr;//十字领域;
	list<base> neighbors_ud2;//扩展上下领域
	list<base> neighbors_lr2;//扩展左右领域
	list<base> neighbors_udlr2;//扩展十字领域
	list<base> neighbors_12;//扩展冯诺依曼领域
	list<base> neighbors_8;//摩尔领域
	list<base> neighbors_24 ;//扩展摩尔领域

		
	action load_neighbors_ud1 {
		neighbors_ud1 <- [base[self.grid_x, self.grid_y-1], base[self.grid_x, self.grid_y+1]];//上下领域
	}
	action load_neighbors_lr1 {
		neighbors_lr1 <- [base[self.grid_x-1, self.grid_y], base[self.grid_x+1, self.grid_y]];//左右领域
	}	
	action load_neighbors_udlr{
		neighbors_udlr <- [base[self.grid_x, self.grid_y-1], base[self.grid_x, self.grid_y+1],
						   base[self.grid_x-1, self.grid_y], base[self.grid_x+1, self.grid_y]];//十字领域		
	}
	action load_neighbors_ud2{
		neighbors_ud2 <- [base[self.grid_x, self.grid_y-1], base[self.grid_x, self.grid_y-2], 
						  base[self.grid_x, self.grid_y+1], base[self.grid_x, self.grid_y+2]];//扩展上下领域		
	}
	action load_neighbors_lr2{
		neighbors_lr2 <- [base[self.grid_x-1, self.grid_y], base[self.grid_x-2, self.grid_y], 
						  base[self.grid_x+1, self.grid_y], base[self.grid_x+2, self.grid_y]];//扩展左右领域		
	}
	action load_neighbors_udlr2{
		neighbors_udlr2 <- [base[self.grid_x, self.grid_y-1], base[self.grid_x, self.grid_y-2], 
							base[self.grid_x, self.grid_y+1], base[self.grid_x, self.grid_y+2], 
							base[self.grid_x-1, self.grid_y], base[self.grid_x-2, self.grid_y], 
							base[self.grid_x+1, self.grid_y], base[self.grid_x+2, self.grid_y]];//扩展十字领域		
	}
	action load_neighbors_12{
		neighbors_12 <- self neighbors_at 2;		
	}
	action load_neighbors_8{
		neighbors_8 <- [base[self.grid_x, self.grid_y-1], base[self.grid_x, self.grid_y+1],
						base[self.grid_x-1, self.grid_y], base[self.grid_x+1, self.grid_y],
						base[self.grid_x-1, self.grid_y-1], base[self.grid_x+1, self.grid_y-1],
						base[self.grid_x-1, self.grid_y+1], base[self.grid_x+1, self.grid_y+1]];//摩尔领域 			
	}	
	action load_neighbors_24{
		neighbors_24 <- self neighbors_at 2 + [base[self.grid_x-2, self.grid_y-2], base[self.grid_x-1, self.grid_y-2], 
									   		   base[self.grid_x+1, self.grid_y-2], base[self.grid_x+2, self.grid_y-2], 
									  		   base[self.grid_x-2, self.grid_y-1], base[self.grid_x+2, self.grid_y-1], 
									  		   base[self.grid_x-2, self.grid_y+1], base[self.grid_x+2, self.grid_y+1], 
									   		   base[self.grid_x-2, self.grid_y+2], base[self.grid_x-1, self.grid_y+2], 
									  		   base[self.grid_x+1, self.grid_y+2], base[self.grid_x+2, self.grid_y+2]];//扩展摩尔领域			
	}
	
 	
}


