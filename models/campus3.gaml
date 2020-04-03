/***
* Name: campus3
* Author: pc
* Description: 基于功能联系的阶段式生成
* Tags: Tag1, Tag2, TagN
***/

model campus2

global control:fsm{
	/** Insert the global definitions, variables and actions here */
	file grid_data <- file('../includes/file5.asc');
	
	geometry shape <- envelope(grid_data);
	int current_cycle update: cycle;
	
	int public_growth <- 5 max: 10 min: 1 parameter: "公共服务地块生长周期:" category: "rules";
	int rs_growth <- 4 max: 10 min: 1 parameter: "文体娱乐地块生长周期:" category: "rules";
	int d_growth <- 5 max: 10 min: 1 parameter: "宿舍地块生长周期:" category: "rules";	
	int r_growth <- 12 max: 12 min: 1 parameter: "住宅地块生长周期:" category: "rules";	
	int t_growth <- 7 max: 12 min: 1 parameter: "教学楼地块生长周期:" category: "rules";	
	int exp_growth <- 5 max: 12 min: 1 parameter: "实验楼地块生长周期:" category: "rules";	
	int a_growth <- 5 max: 12 min: 1 parameter: "行政楼地块生长周期:" category: "rules";
	int s_growth <- 5 max: 12 min: 1 parameter: "中小学地块生长周期:" category: "rules";	
	int o_growth <- 5 max: 12 min: 1 parameter: "开敞空间地块生长周期:" category: "rules";	
		
	int n_center <- 4 max: 10 min: 1 parameter: "邻里中心数量:" category: "rules";
	float mute_coeff <- 0.2 max: 1.0 min: 0.0 parameter: "突变概率:" category: "rules";
	
	
	int neighbours_distance <- 2 max: 10 min: 1 parameter: "地块识别距离:" category: "init";



	//ca1阶段需要的列表
	list<plot> total_places;
	list<plot> green_places;
	list<plot> total_plots;
	list<plot> moving_plots;

	list<plot> u_places;
	list<plot> c_places;
	list<plot> u_plots;	
	list<plot> c_plots;	
	
	//用别名代替rgb值
	rgb c_road <- rgb(255,255,255);
	rgb c_mroad <- rgb(125,125,125);
	rgb c_university <-	rgb(62,130,195);
	rgb c_community <- rgb(242,202,66);
	rgb c_green <- rgb(105,197,91);
	rgb c_null <- rgb(0,0,0);
	rgb c_public <- #red;
	rgb c_rs <- rgb (230,45,126);
	rgb c_dormitory <- #orange;
	rgb c_residential <- rgb (242,202,66);
	rgb c_teaching <- rgb (62,130,195);
	rgb c_exp <- #cyan;
	rgb c_admin <- #brown;
	rgb c_school <- #pink;
	rgb c_open <- #purple;
	map<float,string> num2type <- [0.0::"road", 1.0::"university", 2.0::"community", 3.0::"green", 4.0::"mroad", 5.0::"axis", 6.0::"null"];
	map<string,rgb> type2color <- ["road"::rgb(255,255,255), "university"::rgb(62,130,195), "community"::rgb(242,202,66), "green"::rgb(105,197,91), "mroad"::rgb(200,200,200), "axis"::rgb(100,200,100), "null"::rgb(0,0,0)];	

	//map<string,rgb> type2color <- ["road"::c_road, "university"::c_university, "community"::c_community, "green"::rgb(105,197,91), "null"::c_null];


	
	init {

	}
	
	state get_plots initial: true{//阶段1，将两大功能区加入会变化的地块列表total_places,不包含确定不变的十字主路
		enter {
			write("start, calculating size of site");
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
		exit {
			write("total number of cells is: " + length(total_places));
			ask total_places {
				color <- #grey;
			}
		}
		transition to:spawn_public when:flag = 0  {}
	}
	
	state spawn_public {//阶段2，初始化公共功能区
		enter {
			write("entering state 2, initializing pulic zones");
		}
		
		int flag <- 1;
		int a <- 0;
		if flag = 1 {
			ask total_places {
				do spawn_public;
			}		
			loop while: a < n_center {
				ask 1 among total_places {
				my_neighbors_center <- self neighbors_at 10;
				if sum_neighbors_center = 0 and sum_neighbors_road = 0{
					color <- c_public;
					a <- a + 1;
				}
				
				}				
			}

			flag <- 0;
		}

		
		exit {
			write("public zones already spawned");
		}		
		
		transition to:expand_public when: flag = 0{}		

	}
	
	state expand_public {
		enter {
			write("entering state 3,  expanding public zones");
		}
		
		if public_growth > 0 {
			ask total_places {
				sum_n <- sum_of_n_public;
				c_n <- c_public;
				do expand_zone;
			}
			
			public_growth <- public_growth - 1;
		}
		  
		exit {
			write("public zones growth done");					
		}

		transition to:road_generate1 when:public_growth = 1 {}
	}
	
	state road_generate1 {
		enter {
			write("entering state 4,  generating sub roads");
		}
		int flag <- 1;
		
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_public;
			c_n <- c_road;
			do generate_road;
		}
		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_rs when:flag = 0 {}
	}
	
	state spawn_rs {
		enter {
			write("entering state 5,  generating recreating and sport");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_public <- my_neighbors_12 count (each.color = c_public);
				float mute <- 0.1 * temp_sum_public / 8;
				if flip(mute) {
					color <- c_rs;
				}
			}			
			flag <- 0;		
		}	  

		
		exit {
			write("rs zones growth done");					
		}

		transition to:expand_rs when:flag = 0 {}		
	}	
	
	state expand_rs {
		enter {
			write("entering state 6,  expanding recreating and sport");
		}
		
		if rs_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_rs;
				c_n <- c_rs;
				do expand_zone;
			}
			
			rs_growth <- rs_growth - 1;

		}
				
		exit {
			write("public zones growth done");					
		}

		transition to:road_generate2 when:rs_growth = 1 {}	
	}
	
	state road_generate2 {
		enter {
			write("entering state 7,  generating sub roads");
		}
		
		int flag <- 1;
		
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_rs;
			c_n <- c_road;
			do generate_road;
		}
		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_d when:flag = 0 {}
	}
	
	state spawn_d {
		enter {
			write("entering state 8,  generating dormitory");
		}
		int flag <- 1;
		int a <- 0;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_rs <- my_neighbors_12 count (each.color = c_rs);
				float mute <- 0.3*temp_sum_rs / 8;
				if flip(mute) {
					color <- c_dormitory;						
				}
			}		
			loop while: a < n_center {
				ask 1 among total_places where(each.color = #grey) {
				my_neighbors_center <- self neighbors_at 10;
				if sum_neighbors_center = 0 and sum_neighbors_road = 0{
					color <- c_dormitory;
					a <- a + 1;
				}
				
				}				
			}				
			flag <- 0;		
		}	  		
		exit {
			write("dr zones growth done");					
		}
		transition to:expand_d when:flag = 0 {}		
	}		
	state expand_d {
		enter {
			write("entering state 9,  expanding dormitory");
		}
		
		if d_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_dormitory;
				c_n <- c_dormitory;
				do expand_zone;
			}
		
			d_growth <- d_growth - 1;
		}				
		exit {
			write("public zones growth done");					
		}

		transition to:road_generate3 when:d_growth = 1 {}	
	}	
	state road_generate3 {
		enter {
			write("entering state 10,  generating sub roads");
		}
		
		int flag <- 1;
		
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_dormitory;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_r when:flag = 0 {}
	}	
	state spawn_r {
		enter {
			write("entering state 10,  generating residential");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_green <- my_neighbors_12 count (each.color = rgb(105,197,91));//周围两格内有绿地
				float mute <- 0.1*temp_sum_green / 8;
				if flip(mute) {
					color <- c_residential;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {
			write("dr zones growth done");					
		}
		transition to:expand_r when:flag = 0 {}		
	}		
	state expand_r {
		enter {
			write("entering state 11,  expanding residential");
		}
		
		if r_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_residential;
				c_n <- c_residential;
				do expand_zone;
			}			
			r_growth <- r_growth - 1;
		}				
		exit {
			write("residential zones growth done");					
		}

		transition to:road_generate4 when:r_growth = 1 {}	
	}	
	state road_generate4 {
		enter {
			write("entering state 12,  generating sub roads");
		}
		
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_residential;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_t when:flag = 0 {}
	}	
	state spawn_t {
		enter {
			write("entering state 13,  generating teaching");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_teaching <- my_neighbors_12 count (each.color = c_dormitory);//周围两格内有宿舍
				float mute <- 0.5*temp_sum_teaching / 8;
				if flip(mute) {
					color <- c_teaching;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {
			write("teaching zones growth done");					
		}
		transition to:expand_t when:flag = 0 {}		
	}		
	state expand_t {
		enter {
			write("entering state 14,  expanding teaching");
		}
		
		if t_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_teaching;
				c_n <- c_teaching;
				do expand_zone;
			}			
			t_growth <- t_growth - 1;
		}				
		exit {
			write("teaching zones growth done");					
		}

		transition to:road_generate5 when:t_growth = 1 {}	
	}	
	state road_generate5 {
		enter {
			write("entering state 15,  generating sub roads");
		}
		
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_teaching;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_exp when:flag = 0 {}
	}	
	
	state spawn_exp {
		enter {
			write("entering state 16,  generating exp");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_exp <- my_neighbors_12 count (each.color = c_teaching);//周围两格内有宿舍
				float mute <- 0.1*temp_sum_exp / 8;
				if flip(mute) {
					color <- c_exp;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {
			write("exp zones growth done");					
		}
		transition to:expand_exp when:flag = 0 {}		
	}		
	state expand_exp {
		enter {
			write("entering state 17,  expanding exp");
		}
		
		if exp_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_exp;
				c_n <- c_exp;
				do expand_zone;
			}			
			exp_growth <- exp_growth - 1;
		}				
		exit {
			write("exp zones growth done");					
		}

		transition to:road_generate6 when:exp_growth = 1 {}	
	}	
	state road_generate6 {
		enter {
			write("entering state 18,  generating sub roads");
		}
		
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_exp;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_a when:flag = 0 {}
	}		
	
	state spawn_a {
		enter {
			write("entering state 19,  generating admin");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_admin <- my_neighbors_12 count (each.color = c_exp);//周围两格内有宿舍
				float mute <- 0.1*temp_sum_admin / 8;
				if flip(mute) {
					color <- c_admin;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {
			write("admin zones growth done");					
		}
		transition to:expand_a when:flag = 0 {}		
	}		
	state expand_a {
		enter {
			write("entering state 20,  expanding admin");
		}
		
		if a_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_admin;
				c_n <- c_admin;
				do expand_zone;
			}			
			a_growth <- a_growth - 1;
		}				
		exit {
			write("admin zones growth done");					
		}

		transition to:road_generate7 when:a_growth = 1 {}	
	}	
	state road_generate7 {
		enter {
			write("entering state 21,  generating sub roads");
		}
		
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_admin;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_s when:flag = 0 {}
	}			
	
	state spawn_s {
		enter {
			write("entering state 22,  generating school");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_school <- my_neighbors_12 count (each.color = c_residential);//周围两格内有住宅
				float mute <- 0.1*temp_sum_school / 8;
				if flip(mute) {
					color <- c_school;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {
			write("school zones growth done");					
		}
		transition to:expand_s when:flag = 0 {}		
	}		
	state expand_s {
		enter {
			write("entering state 23,  expanding school");
		}
		
		 
		if s_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_school;
				c_n <- c_school;
				do expand_zone;
			}			
			s_growth <- s_growth - 1;
		}				
		exit {
			write("school zones growth done");					
		}

		transition to:road_generate8 when:s_growth = 1 {}	
	}	
	state road_generate8 {
		enter {
			write("entering state 24,  generating sub roads");
		}
		
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_school;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_o when:flag = 0 {}
	}	
	
	state spawn_o {
		enter {
			write("entering state 25,  generating open");
		}
		int a <- 1;
		int flag <- 1;
		if flag = 1 {
			loop while: a < n_center {
				ask 1 among total_places where(each.color = #grey){
					color <- c_open;
					a <- a + 1;				
				}				
			}	
			flag <- 0;			
		}  		
		exit {
			write("school zones growth done");					
		}
		transition to:expand_o when:flag = 0 {}		
	}		
	state expand_o {
		enter {
			write("entering state 26,  expanding open");
		}
		if o_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_open;
				c_n <- c_open;
				do expand_zone;
			}			
			o_growth <- o_growth - 1;
		}			
		exit {
			write("open zones growth done");					
		}

		transition to:road_generate9 when:o_growth = 1 {}	
	}	
	state road_generate9 {
		enter {
			write("entering state 27,  generating sub roads");
		}
		
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_open;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {
			write("sub road generate done");					
		}

		transition to:spawn_g when:flag = 0 {}
	}	
	
	state spawn_g {
		enter {
			write("entering state 28,  generating green");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				color <- c_green;
			}			
			flag <- 0;
		}


		exit {
			write("green zones spawned done");					
		}
		transition to:optimize_road when:flag = 0 {}		
	}			
	
	state optimize_road {
		enter {
			write("entering state 29,  optimizing_road");
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places {
				int temp_sum_road <- my_neighbors_8 count (each.color = c_road);
				if temp_sum_road >= 5{
					color <- c_road;					
				}
			}			
			flag <- 0;
		}


		exit {
			write("green zones spawned done");					
		}
		transition to:end when:flag = 0 {}		
	}		
	
	state end {
		
	}		
	reflex check {
		
	}
	
	
}//end of global


grid plot neighbors:8 file: grid_data{
	float num <- grid_value;
	string type <- num2type[num];
	rgb color <- type2color[type];
	bool is_moving <- true;
	int sum_n;
	rgb c_n;
	
	int sum_of_n_mroad <- 0;
	int sum_of_n_axis <- 0;
	int sum_of_n_public update:my_neighbors_8 count (each.color = c_public);
	int sum_of_n_rs update:my_neighbors_8 count (each.color = c_rs);
	int sum_of_n_dormitory update:my_neighbors_8 count (each.color = c_dormitory);	
	int sum_of_n_residential update:my_neighbors_8 count (each.color = c_residential);	
	int sum_of_n_teaching update:my_neighbors_8 count (each.color = c_teaching);
	int sum_of_n_exp update:my_neighbors_8 count (each.color = c_exp);
	int sum_of_n_admin update:my_neighbors_8 count (each.color = c_admin);
	int sum_of_n_school update:my_neighbors_8 count (each.color = c_school);
	int sum_of_n_open update:my_neighbors_8 count (each.color = c_open);
	
	int sum_neighbors_center update:my_neighbors_center count (each.color = c_public);
	int sum_neighbors_road update:my_neighbors_center count (each.color = c_road or each.color = c_mroad);
	int sum_void update:my_neighbors_8 count (each.color = #grey);
	
	rgb temp_color;
	list<plot> free_places;
	list<plot> all_plots;
	list<plot> my_neighbors_center;
	list<plot> my_neighbors_8 <- self.neighbors;
	list<plot> my_neighbors_4 <- self neighbors_at 1;
	list<plot> my_neighbors_12 <- self neighbors_at 2;
	
	list<plot> my_neighbors <- self neighbors_at neighbours_distance;//获取邻居列表	
	int similar_nearby -> 
		(my_neighbors count (each.color = color));//计算邻居中与自己颜色（功能）相同的邻居数量
	int similar_nearby_4 -> 
		(my_neighbors_4 count (each.color = color));//计算邻居中与自己颜色（功能）相同的邻居数量
	int total_nearby -> 
		length (my_neighbors);//计算邻居数量（这里统一为8）
			
	//bool is_same -> similar_nearby >= (percent_same * total_nearby ) ;
	//当相同颜色的邻居数量大于等于设定值（这里为0.5 * 8 = 4），说明该地块与周边地块颜色相似，保持不变从而形成聚集
	
	action spawn_public {
		sum_of_n_mroad <- my_neighbors_8 count (each.type = "mroad");
		float mute1 <- mute_coeff * sum_of_n_mroad / 8;
		if flip(mute1) {
			color <- c_public;
		}
		sum_of_n_axis <- my_neighbors_8 count (each.type = "axis");
		float mute2 <- mute_coeff * sum_of_n_axis / 8;
		if flip(mute2) {
			color <- c_public;
		}				
	}
	
	action expand_zone {
		if sum_n > 0 {
			color <- c_n;
		}
	}
	
	action generate_road {
		if sum_n > 0 {
			color <- c_n;
		}
	}
	

	
}//end of species






experiment campus2 type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map {
			grid plot;
		}
	}
}
