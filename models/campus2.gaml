/***
* Name: campus2
* Author: pc
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model campus2

global control:fsm{
	/** Insert the global definitions, variables and actions here */
	file grid_data <- file('../includes/file.asc');

	geometry shape <- envelope(grid_data);
	int current_cycle update: cycle;
	
	//Neighbours distance for the perception of the agents单元可以感知的距离范围
	int neighbours_distance <- 2 max: 10 min: 1 parameter: "地块识别距离:" category: "init";
	float mix_rate_u <- 0.3 max: 1.0 min: 0.0 parameter: "高校混合率:" category: "init";
	float mix_rate_c <- 0.5 max: 1.0 min: 0.0 parameter: "社区混合率:" category: "init";
	float percent_same <- 0.6 min: float (0) max: float (1) parameter: "周边地块相同率:" category: "init";
	float u_real;
	float percent_green <- 0.05 min: float (0) max: float (1) parameter: "绿地率:" category: "init";
	float percent_u ->
		round(((plot count (each.num = 1.0)) / sum_plots)*10)/10;
	float u <- percent_u;		
	float percent_c ->
		round(((plot count (each.num = 2.0)) / sum_plots)*10)/10;
	int sum_plots -> 
		(plot count (each.num = 1.0)) + (plot count (each.num = 2.0));
	
	rgb dormitory <- rgb (251,207,141) parameter: "宿舍:" category: "User interface";
	rgb teaching <- rgb (62,130,195) parameter: "教学:" category: "User interface";
	rgb exper <- rgb (0,69,133) parameter: "科研:" category: "User interface";
	rgb create <- rgb (209,10,63) parameter: "生产:" category: "User interface";	
	rgb admin <- rgb ("purple") parameter: "行政:" category: "User interface";
	rgb r_s <- rgb (230,45,126) parameter: "文体:" category: "User interface";
			
	rgb residential <- rgb (242,202,66) parameter: "居住:" category: "User interface";
	rgb commercial <- rgb ("red") parameter: "商业:" category: "User interface";
	rgb c_r <- rgb (246,202,66) parameter: "商住:" category: "User interface";
	rgb green <- rgb ("green") parameter: "绿地:" category: "User interface";
	rgb transport <- rgb ("grey") parameter: "交通:" category: "User interface";   
	rgb school <- rgb ("pink") parameter: "中小学:" category: "User interface";
	rgb recreation <- rgb ("orange") parameter: "文化娱乐:" category: "User interface";
	
    //list colors <- [dormitory, teaching, exper, admin, residential, commercial, c_r, green, transport, school, recreation] of: rgb;
    //list mix_set <- [exper, create, r_s, commercial, c_r, green, transport, school, recreation] of: rgb;	
    list mix_set_c <- [create, r_s] of: rgb;	
    list mix_set_u <- [commercial, school] of: rgb;	
	int total_mixfunction_c -> length (mix_set_c);
	int total_mixfunction_u -> length (mix_set_u);
		
	//ca1阶段需要的列表
	list<plot> total_places;
	list<plot> green_places;
	list<plot> total_plots;
	list<plot> moving_plots;

	list<plot> u_places;
	list<plot> c_places;
	list<plot> u_plots;	
	list<plot> c_plots;	
	
	map<float,string> num2type <- [0.0::"road", 1.0::"university", 2.0::"community", 3.0::"transport", 4.0::"green", 5.0::"zero"];
	map<string,rgb> type2color <- ["road"::rgb(255,255,255), "university"::rgb(62,130,195), "community"::rgb(242,202,66), "transport"::rgb(150,150,150), "green"::rgb(105,197,91), "zero"::rgb(0,0,0)];
		
	//map<string,rgb> color_per_type <- ["water"::#blue, "vegetation":: #green, "building":: #pink];

	
	init {
		write(0.6*12);
		u_real <- percent_u*(1-percent_green);
		write(u_real);
		write(int(0.4*sum_plots));
		//do initialize_plots;		
		//do initialze_places;
		}
	
	state original_plots initial: true{
		
		transition to:init_plots when:cycle = 1 {}
	}
	
	state init_plots {
		enter {
			write("start");
		}
		int flag <- 1;
		if flag = 1 {
			ask plot {
				if num = 1.0 {
					add self to: total_places;
				}
				else if num = 2.0 {
					add self to: total_places;
				}
			}		
			flag <- 0;
		}

		write(length(total_places));
		exit {
			ask total_places {
				color <- #grey;
			}
		}
		transition to:disaggregate when:flag = 0 {}		

	}
	
	state disaggregate {
		enter {
			write("entered disaggregate");
			int enter_cycle <- cycle;
		}		
	
		 
		  
		ask total_places {
			if flip(u) {
				color <- teaching;
			}
			else {
				color <- residential;
			}		
		}
			
		green_places <- int(percent_green * float(sum_plots)) among total_places;
		ask green_places {
			color <- green; 
		}
		
		
		exit {
			total_plots <- shuffle(total_places);			
		}

		transition to:aggregate when:cycle = enter_cycle + 10 {}
	}
	
	state aggregate {
		enter {
			write("entered ca1");
			int enter_cycle <- cycle;
		}		
		ask copy(total_plots) {
			free_places <- total_places;
			all_plots <- total_plots;
			temp_color <- green;
			do migrate;
		}		
		moving_plots <- total_plots where(each.is_moving = true);
		exit {
			write(length(moving_plots));
		}	
		
		transition to:optimize1 when: cycle = enter_cycle + 200; //and length(moving_plots) <= 0.1*sum_plots) {}//当循环大于且移动的地块小于10%的总地块数量时，进入下一个阶段
	}
	
	state optimize1 {
		enter {
			write("entered optimize1");
			int enter_cycle <- cycle;			
		}		
		ask total_plots {
			if (color = self.color and similar_nearby_4 <2) {
				color <- green;//这样优化会导致优化后绿地太多且破坏整体形态！！！！
			}
			else {
				color <- self.color;
			}	
		}
		exit {
		u_places <- total_plots where(each.color = teaching);
		u_plots <- shuffle(u_places);

		c_places <- total_plots where(each.color = residential);
		c_plots <- shuffle(c_places);		
		}		
		transition to:subdivide when: cycle = enter_cycle + 10;		
	}	
	
	state subdivide {
		int flag <- 1;
		if flag = 1 {
			ask total_plots {
				if (color = teaching and flip(mix_rate_u)) {
					color <- mix_set_u at (rnd(total_mixfunction_u - 1));
				}
				else if (color = residential and flip(mix_rate_c)) {
					color <- mix_set_c at (rnd(total_mixfunction_c - 1));
				}			
			}		
			flag <- 0;	
			write(flag);
		}	
		transition to:aggregate2 when: flag = 0;		
	}
	
	state aggregate2 {
		enter {
			write("entered aggregate2");
		}			
		ask copy(u_plots) {
			free_places <- u_places;
			all_plots <- u_plots;
			temp_color <- teaching;
			do migrate;
		}	
		ask copy(c_plots) {
			free_places <- c_places;
			all_plots <- c_plots;
			temp_color <- residential;
			do migrate;
		}			
	}
	
	
	
	
	
	//Action to initialize the places
	action initialize_places {
		ask plot {
			if num = 1.0 {
				add self to: u_places;
			}
			else if num = 2.0 {
				add self to: c_places;
			}
		}
		u_plots <- shuffle(u_places);
		c_plots <- shuffle(c_places);		

	}

	 action initialize_plots {

		ask plot {
			if num = 1.0 and flip(mix_rate_u) {
				color <- mix_set_u at (rnd(total_mixfunction_u - 1));
			}
			else if num = 2.0 and flip(mix_rate_c) {
				color <- mix_set_c at (rnd(total_mixfunction_c - 1));
			}
		}
		


	}


	
	

	
}


grid plot file: grid_data{
	float num <- grid_value;
	string type <- num2type[num];
	rgb color <- type2color[type];
	bool is_moving <- true;


	rgb temp_color;
	list<plot> free_places;
	list<plot> all_plots;
	list<plot> my_neighbours_4 <- self neighbors_at 1;
	list<plot> my_neighbours <- self neighbors_at neighbours_distance;//获取邻居列表	
	int similar_nearby -> 
		(my_neighbours count (each.color = color));//计算邻居中与自己颜色（功能）相同的邻居数量
	int similar_nearby_4 -> 
		(my_neighbours_4 count (each.color = color));//计算邻居中与自己颜色（功能）相同的邻居数量
	int total_nearby -> 
		length (my_neighbours);//计算邻居数量（这里统一为8）
			
	bool is_same -> similar_nearby >= (percent_same * total_nearby ) ;
	//当相同颜色的邻居数量大于等于设定值（这里为0.5 * 8 = 4），说明该地块与周边地块颜色相似，保持不变从而形成聚集
	

	
	action migrate {

		if !is_same {
			//如果相同颜色的邻居数量小于4，说明该地块处于孤立中，迁移到开敞的地方寻求与其他颜色（功能）聚合		
			plot pp <- any(my_neighbours where (each.color = temp_color));
			if (pp != nil) {
				free_places <+ self;
				free_places >- pp;
				all_plots >- self;
				all_plots << pp;
				pp.color <- color;
				color <- temp_color;
			}
		}
		else {
			is_moving <- false;
		}		
	}
	
}






experiment campus2 type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map {
			grid plot;
		}
	}
}
