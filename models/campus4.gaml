/***
* Name: campus3
* Author: pc
* Description: 基于功能联系的阶段式生成
* Tags: Tag1, Tag2, TagN
***/

model campus2

global control:fsm{
	/** Insert the global definitions, variables and actions here */
	file grid_data <- file('../includes/file6.asc');
	
	geometry shape <- envelope(grid_data);
	int current_cycle update: cycle;

//--------------------------------------↓地块相关全局参数↓-------------------------------------------------------//	
	int academic_growth <- 10 max: 12 min: 1 parameter: "学术功能地块生长周期:" category: "plots";	
	int admin_growth <- 7 max: 12 min: 1 parameter: "行政楼地块生长周期:" category: "plots";
	int rs_growth <- 10 max: 10 min: 1 parameter: "文体娱乐地块生长周期:" category: "plots";
	int green_growth <- 3 max: 10 min: 1 parameter: "开敞空间生长周期:" category: "plots";
	int ss_growth <- 5 max: 10 min: 1 parameter: "体育与小型服务设施地块生长周期:" category: "plots";
	int dormitory_growth <- 7 max: 10 min: 1 parameter: "宿舍地块生长周期:" category: "plots";	
	int residential_growth <- 12 max: 12 min: 1 parameter: "住宅地块生长周期:" category: "plots";	
	int commercial_growth <- 7 max: 12 min: 1 parameter: "商业地块生长周期:" category: "plots";	
	int school_growth <- 8 max: 12 min: 1 parameter: "中小学地块生长周期:" category: "plots";	
	int transport_growth <- 6 max: 12 min: 1 parameter: "交通场地生长周期:" category: "plots";	
	int mix_growth <- 8 max: 12 min: 1 parameter: "综合用地生长周期:" category: "plots";	
			
	int n_center <- 4 max: 10 min: 1 parameter: "邻里中心数量:" category: "plots";
	float mute_coeff <- 0.2 max: 1.0 min: 0.0 parameter: "突变概率:" category: "plots";
	
	int neighbours_distance <- 2 max: 10 min: 1 parameter: "地块识别距离:" category: "plots";
//--------------------------------------↑地块相关全局参数↑-------------------------------------------------------//

//--------------------------------------↓建筑相关全局参数↓-------------------------------------------------------//
	int growth <- 5 max: 10 min: 1 parameter: "生长周期:" category: "architecture";
	list<float> academic_height <- [12.0, 24.0, 3.0] parameter: "学术建筑高度" category: "architectures";	
	list<float> residential_height <- [60.0, 72.0, 3.0] parameter: "住宅建筑高度" category: "architectures";	
	list<float> commercial_height <- [24.0, 120.0, 4.0] parameter: "商业建筑高度" category: "architectures";	
	list<float> green_height <- [3.0, 6.0, 3.0] parameter: "景观建筑高度" category: "architectures";	
//--------------------------------------↑建筑相关全局参数↑-------------------------------------------------------//


//--------------------------------------↓选择列表↓-------------------------------------------------------//
	list<plot> total_places;
	list<plot> academic_plots update: plot where(each.type = "academic");
	list<plot> residential_plots update: plot where(each.type = "residential");	
	list<plot> commercial_plots update: plot where(each.type = "commercial");	
	list<plot> green_plots update: plot where(each.type = "green");
//--------------------------------------↑选择列表↑-------------------------------------------------------//


//--------------------------------------↓颜色全局参数↓-------------------------------------------------------//
	rgb c_road <- rgb(230,230,230);
	rgb c_mroad <- rgb(125,125,125);
	rgb c_university <-	rgb(62,130,195);
	rgb c_community <- rgb(252, 162, 249);
	rgb c_green <- rgb(105,197,91);
	rgb c_env <- rgb(100,200,90);
	rgb c_null <- rgb(0,0,0);
	rgb c_commercial <- #red;
	rgb c_rs <- rgb (230,45,126);
	rgb c_dormitory <- #orange;
	rgb c_ss <- #cyan;//小型体育场地、停车场与服务设施
	rgb c_residential <- rgb (255, 251, 128);
	rgb c_academic <- rgb (62,130,195);
	rgb c_admin <- #purple;
	rgb c_school <- rgb (252, 162, 249);
	rgb c_transport <- rgb (220,220,220);
	rgb c_mix <- rgb (252, 181, 117);	
//--------------------------------------↑颜色全局参数↑-------------------------------------------------------//	

//--------------------------------------↓数据匹配↓-------------------------------------------------------//
	map<float,string> num2type <- [0.0::"road", 1.0::"university", 2.0::"community", 3.0::"green", 4.0::"mroad", 5.0::"axis", 6.0::"null", 7.0::"subaxis"];
	map<string,rgb> type2color <- ["road"::rgb(230,230,230), "university"::rgb(62,130,195), "community"::rgb(242,202,66), "green"::rgb(100,200,90), "mroad"::rgb(200,200,200), "axis"::rgb(100,200,100), "null"::rgb(0,0,0), "subaxis"::rgb(110,197,91)];	
	map<string, list<float>> type2height <- ["academic"::academic_height, "residential"::residential_height, "commercial"::commercial_height, "green"::green_height];
	map<string,rgb> type2color2 <- ["road"::rgb(255,255,255), "green"::rgb(105,197,91), "commercial"::#red, "dormitory"::#orange, "ss"::#cyan, "residential"::rgb (255, 251, 128),
												    "academic"::rgb (62,130,195), "admin"::#purple, "school"::rgb (252, 162, 249), "transport"::rgb (220,220,220), "mix"::rgb (252, 181, 117)];
//--------------------------------------↑数据匹配↑-------------------------------------------------------//

//	init {
//
//	}

//-----------------------------------------------↓start of fsm↓----------------------------------------------//	
	state get_plots initial: true{//将两大功能区加入会变化的地块列表total_places,不包含确定不变的十字主路
		enter {write("entering state: get_plots");}
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
		transition to:spawn_academic when:flag = 0  {}
	}
	//生成学术区域点↓
	state spawn_academic {
		enter {write("entering state: 2, spawn_academic");}
		
		int flag <- 1;
		int a <- 0;
		if flag = 1 {
			ask total_places {
				sum_of_n_mroad <- neighbors_8 count (each.type = "mroad");
				float mute1 <- 0.8*mute_coeff * sum_of_n_mroad / 8;
				if flip(mute1) {
					color <- c_academic;
				}
				sum_of_n_axis <- neighbors_8 count (each.type = "axis");
				float mute2 <- 0.8*mute_coeff * sum_of_n_axis / 8;
				if flip(mute2) {
					color <- c_academic;
				}					
			}		
//			loop while: a < n_center {
//				ask 1 among total_places {
//					neighbors_center <- self neighbors_at 10;
//					if sum_neighbors_center = 0 and sum_neighbors_road = 0{
//						color <- c_public;
//						a <- a + 1;
//					}				
//				}				
//			}
			flag <- 0;
		}		
		exit {write("spawn_academic done");}				
		transition to:expand_academic when: flag = 0{}		
	}
	
	state expand_academic {
		enter {write("entering state: expand_academic");}
		if academic_growth > 0 {
			ask total_places {
				sum_n <- sum_of_n_academic;
				c_n <- c_academic;
				do expand_zone;
			}			
			academic_growth <- academic_growth - 1;
		}		  
		exit {write("expand_academic done");}
		transition to:generate_road_academic when:academic_growth = 1 {}
	}
	
	state generate_road_academic {
		enter {
			write("entering state: generate_road1");
		}
		int flag <- 1;
		
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_academic;
			c_n <- c_road;
			do generate_road;
		}
		
		flag <- 0;  
		exit {write("generate_road_academic done");}
		transition to:spawn_rs when:flag = 0 {}
	}
	//生成大型公共服务区域点↓
	state spawn_rs {
		enter {write("entering state: spawn_rs");}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey){
				sum_of_n_mroad <- neighbors_8 count (each.type = "mroad");
				float mute1 <- mute_coeff * sum_of_n_mroad / 8;
				if flip(mute1) {
					color <- c_rs;
				}				
				sum_of_n_axis <- neighbors_8 count (each.type = "axis");
				float mute2 <- 0.5*mute_coeff * sum_of_n_axis / 8;
				if flip(mute2) {
					color <- c_rs;
				}	
			}				
			ask 2 among (total_places where(each.color = #grey )){
				color <- c_rs;	
			}		
			flag <- 0;
		}	  
		exit {write("spawn_rs done");}
		transition to:expand_rs when:flag = 0 {}		
	}	
	
	state expand_rs {
		enter {write("entering state: expand_rs");}
		
		if rs_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_rs;
				c_n <- c_rs;
				do expand_zone;
			}
			rs_growth <- rs_growth - 1;
		}	
		exit {write("expand_rs done");}
		transition to:generate_road_rs when:rs_growth = 1 {}	
	}
	
	state generate_road_rs {
		enter {write("entering state: generate_road_rs");}
		
		int flag <- 1;
		
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_rs;
			c_n <- c_road;
			do generate_road;
		}
		flag <- 0;  
		exit {write("generate_road_rs done");}

		transition to:spawn_admin when:flag = 0 {}
	}
	//生成行政办公区域点↓
	state spawn_admin {
		enter {write("entering state: spawn_admin");}	
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey){
				sum_of_n_mroad <- neighbors_8 count (each.type = "mroad");
				float mute1 <- mute_coeff * sum_of_n_mroad / 8;
				if flip(mute1) {
					color <- c_admin;
				}
				sum_of_n_axis <- neighbors_8 count (each.type = "axis");
				float mute2 <- 0.5*mute_coeff * sum_of_n_axis / 8;
				if flip(mute2) {
					color <- c_admin;
				}	
			}		
			flag <- 0;
		}		
		exit {write("spawn_admin done");}		
		transition to:expand_admin when: flag = 0{}		
	}
	
	state expand_admin {
		enter {write("entering state: expand_admin");}
		if admin_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_admin;
				c_n <- c_admin;
				do expand_zone;
			}			
			admin_growth <- admin_growth - 1;
		}	
		exit {write("expand_admin done");}
		transition to:generate_road_admin when:admin_growth = 1 {}
	}
	
	state generate_road_admin {
		enter {write("entering state: generate_road2");}
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_admin;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {write("generate_road_admin done");}
		transition to:spawn_green when:flag = 0 {}
	}	
	//生成开敞空间区域点↓
	state spawn_green {
		enter {
			write("entering state: spawn_green");
		}
		int flag <- 1;
		int a <- 0;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum <- neighbors_12 count (each.color = c_admin or each.color = c_academic);//两格内有行政或学术
				float mute <- 0.3*temp_sum / 8;
				if flip(mute) {
					color <- c_green;						
				}
			}					
			flag <- 0;		
		}	  		
		exit {
			write("spawn_green done");					
		}
		transition to:expand_green when:flag = 0 {}		
	}		
	
	state expand_green {
		enter {write("entering state: expand_green");}
		
		if green_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_green;
				c_n <- c_green;
				do expand_zone;
			}
			green_growth <- green_growth - 1;
		}				
		exit {write("public zones growth done");}
		transition to:spawn_dormitory when:green_growth = 1 {}	
	}	
	
//	state generate_road_green {
//		enter {write("entering state: generate_road_green");}	
//		int flag <- 1;
//		ask total_places where(each.color = #grey) {
//			sum_n <- sum_of_n_green;
//			c_n <- c_road;
//			do generate_road;
//		}		
//		flag <- 0;  
//		exit {write("generate_road_green done");}
//		transition to:spawn_dormitory when:flag = 0 {}
//	}	
	//生成宿舍区域点↓
	state spawn_dormitory {
		enter {write("entering state: spawn_dormitory");}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum <- neighbors_12 count (each.color = rgb(105,197,91) or each.color = c_academic);//周围两格内有绿地或学术
				float mute <- 0.1*temp_sum / 12;
				if flip(mute) {
					color <- c_dormitory;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {write("spawn_dormitory done");}
		transition to:expand_dormitory when:flag = 0 {}		
	}		
	
	state expand_dormitory {
		enter {write("entering state: expand_apartment");}
		if dormitory_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_dormitory;
				c_n <- c_dormitory;
				do expand_zone;
			}			
			dormitory_growth <- dormitory_growth - 1;
		}				
		exit {write("expand_dormitory done");}
		transition to:spawn_ss when:dormitory_growth = 1 {}	
	}	
	//生成运动及小型服务区域点↓
	state spawn_ss {
		enter {write("entering state: spawn_ss");}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_dormitory <- neighbors_8 count (each.color = c_dormitory);//周围有宿舍
				float mute <- 0.3*temp_sum_dormitory / 8;
				if flip(mute) {
					color <- c_ss;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {write("spawn_ss done");}
		transition to:expand_ss when:flag = 0 {}		
	}		
	
	state expand_ss {
		enter {write("entering state: expand_ss");}
		if ss_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_ss;
				c_n <- c_ss;
				do expand_zone;
			}			
			ss_growth <- ss_growth - 1;
		}				
		exit {write("expand_ss done");}
		transition to:generate_road_dormitory when:ss_growth = 1 {}	
	}		
	state generate_road_dormitory {
		enter {write("entering state: generate_road_dormitory");}
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_dormitory;
			c_n <- c_road;
			do generate_road;
		}	
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_ss;
			c_n <- c_road;
			do generate_road;
		}				
		flag <- 0;  
		exit {write("generate_road_dormitory done");}
		transition to:spawn_residential when:flag = 0 {}
	}	
	//生成住宅区域点↓
	state spawn_residential {
		enter {write("entering state: spawn_residential");}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_residential <- neighbors_12 count (each.color = c_env);//周围两格内有环境
				float mute <- 0.2*temp_sum_residential / 8;
				if flip(mute) {
					color <- c_residential;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {write("spawn_residential done");}
		transition to:expand_residential when:flag = 0 {}		
	}		
	state expand_residential {
		enter {write("entering state: expand_residential");}
		
		if residential_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_residential;
				c_n <- c_residential;
				do expand_zone;
			}			
			 residential_growth <-  residential_growth - 1;
		}				
		exit {write("expand_residential done");}
		transition to:generate_road_residential when: residential_growth = 1 {}	
	}	
	state generate_road_residential {
		enter {
			write("entering state 15,  generating sub roads");
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

		transition to:spawn_school when:flag = 0 {}
	}	
	//生成中小学区域点↓
	state spawn_school {
		enter {write("entering state: spawn_school");}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_school <- neighbors_12 count (each.color = c_residential);//周围两格内有住宅
				float mute <- 0.1*temp_sum_school / 8;
				if flip(mute) {
					color <- c_school;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {write("sspawn_school done");}
		transition to:expand_school when:flag = 0 {}		
	}		
	
	state expand_school {
		enter {write("entering state 23,  expanding school");} 
		if school_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_school;
				c_n <- c_school;
				do expand_zone;
			}			
			school_growth <- school_growth - 1;
		}				
		exit {write("expand_school done");}
		transition to:generate_road_school when:school_growth = 1 {}	
	}	
	
	state generate_road_school {
		enter {write("entering state: generate_road_school");}
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_school;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {write("generate_road_school done");}
		transition to:spawn_transport when:flag = 0 {}
	}	
	//生成交通场站区域点↓
	state spawn_transport {
		enter {write("entering state: spawn_transport");}
		int a <- 1;
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_road <- neighbors_8 count (each.type = "road");//周围有道路
				float mute <- 0.05*temp_sum_road / 8;
				if flip(mute) {
					color <- c_transport;						
				}
			}	
			flag <- 0;		
		}  		
		exit {write("spawn_transport done");}
		transition to:expand_transport when:flag = 0 {}		
	}		
	
	state expand_transport {
		enter {write("entering state: expand_transport");}
		if transport_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_transport;
				c_n <- c_transport;
				do expand_zone;
			}			
			transport_growth <- transport_growth - 1;
		}			
		exit {write("expand_transport done");}
		transition to:generate_road_transport when:transport_growth = 1 {}	
	}	
	
	state generate_road_transport {
		enter {write("entering state 27,  generating sub roads");}
		int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_transport;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {write("sub road generate done");}
		transition to:spawn_commercial when:flag = 0 {}
	}	
	//生成商业区域点↓	
	state spawn_commercial {
		enter {write("entering state: spawn_business");}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				int temp_sum_road <- neighbors_8 count (each.color = c_road);//周围有道路
				float mute <- 0.1*temp_sum_road / 8;
				if flip(mute) {
					color <- c_commercial;						
				}
			}			
			flag <- 0;		
		}	  		
		exit {write("spawn_business done");}
		transition to:expand_commercial when:flag = 0 {}		
	}	
		
	state expand_commercial {
		enter {write("entering state: expand_commercial");}
		
		if commercial_growth > 0 {
			ask total_places where(each.color = #grey){
				sum_n <- sum_of_n_commercial;
				c_n <- c_commercial;
				do expand_zone;
			}			
			commercial_growth <- commercial_growth - 1;
		}				
		exit {write("expand_commercial done");}

		transition to:generate_road_commercial when:commercial_growth = 1 {}	
	}	
	
	state generate_road_commercial {
		enter {write("entering state: generate_road_commercial");}
				int flag <- 1;
		ask total_places where(each.color = #grey) {
			sum_n <- sum_of_n_commercial;
			c_n <- c_road;
			do generate_road;
		}		
		flag <- 0;  
		exit {write("generate_road_commercial done");}
		transition to:spawn_mix when:flag = 0 {}
	}			
	//生成综合功能区域点↓
	state spawn_mix {
		enter {write("entering state: spawn_mix");}
		int flag <- 1;
		if flag = 1 {
			ask total_places where(each.color = #grey) {
				color <- c_mix;
			}			
			flag <- 0;
		}
		exit {write("spawn_mix done");}
		transition to:initiate_building when:flag = 0 {}		
	}			
	//生成建筑↓
	state initiate_building {
		enter {
			write("entering state: initiate_building");
				ask total_places {
					if color = rgb(255,255,255){type <- "road";}
					else if color = rgb(230,230,230){type <- "sroad";}
					else if color = rgb(200,200,200){type <- "mroad";}
					else if color = rgb(105,197,91){type <- "green";}
					else if color = #red{type <- "commercial";}
					else if color = #orange{type <- "dormitory";}
					else if color = #cyan{type <- "ss";}
					else if color = rgb (255, 251, 128){type <- "residential";}
					else if color = rgb (62,130,195){type <- "academic";}
					else if color = #purple{type <- "admin";}
					else if color = rgb (252, 162, 249){type <- "school";}
					else if color = rgb (220,220,220){type <- "transport";}
					else if color = rgb (252, 181, 117){type <- "mix";}				
//					map<rgb, string> color2type <- [rgb(255,255,255)::"road", rgb(105,197,91)::"green", #red::"commercial", #orange::"dormitory", #cyan::"ss", rgb (255, 251, 128)::"residential",
//												    rgb (62,130,195)::"academic", #purple::"admin", rgb (252, 162, 249)::"school", rgb (220,220,220)::"transport", rgb (252, 181, 117)::mix];
			}
		}
		int flag <- 1;
		if flag = 1 {
			ask total_places parallel: true{
				sum_road <- neighbors count (each.type = "road" or each.type = "sroad" or each.type = "mroad");
				if sum_road = 0 {
					if type = "academic" {
						//build <- true;
						color <- #white;
					}
					else if type = "commercial" {
						//build <- flip(0.5)? true:false;
						color <- flip(0.7)? #white:color;
					}
					else if type = "residential" {
						//build <- flip(0.3)? true:false;
						do load_neighbors_12;					
						
						if neighbors_12 count (each.type = "road") >= 1 and neighbors_12 count (each.type = "road") <= 2 {
							color <- #white;
						}	
					}									
				}				
			}
			flag <- 0;	
		}
		exit {
			write("initiate_building done");
			ask plot {
				if color = #white {
					build <- true;
				}
			}			
		}
		transition to:modify_buildings when:flag = 0 {}		
	}			
	
	state modify_buildings {
		enter {write "enter state: modify_buildings";}
		int flag <- 1;
		if flag = 1 {
			ask academic_plots where (each.color = #white) parallel: true{		
				do academic_adapting;

			}
			ask academic_plots {
				color <- build? #white:type2color2[type];
			}	
			ask academic_plots {
				do light_adapting;
			}				
			ask academic_plots {
				color <- build? #white:type2color2[type];			
			}
			
			ask residential_plots where (each.color = #white) parallel: true{
				do residential_adapting;
			}
			ask residential_plots {
				color <- build? #white:type2color2[type];
			}			
			ask residential_plots where (each.color = #white) parallel: true{
				do break_adapting;
			}
			ask residential_plots {
				color <- build? #white:type2color2[type];
			}
			
			ask commercial_plots parallel: true {
				do load_neighbors_udlr2;
				do load_neighbors_8;
				sum_road <- neighbors_udlr2 count (each.type = "road");
			}


				ask 1 among (commercial_plots where(each.sum_road = 0)) {
					build <- true;
					higher <- true;
					loop i over:neighbors_8 {
						i.build <- true;
						i.higher <- true;
					}
				}	
				
			ask commercial_plots {
				color <- build? #white:type2color2[type];
			}	
							
			write growth;
			growth <- growth - 1;
			flag <- 0;
		}
		exit {
			write "modify_buildings done";
			ask academic_plots {
				do detect_height;
			}
		}
		transition to:generate_buildings when:flag = 0 {}	
	}
	
	
	state generate_buildings {
		enter {write "enter state: generate_buildings";}		
		int nb_buildings <- plot count (each.color = #white);
		list<plot> built_area <- plot where (each.color = #white);
		int flag <- 1;
		if flag = 1 {
			create building number: nb_buildings ;
				loop i from: 0 to: nb_buildings -1 {					
						building[i].location <- built_area[i].location;
						building[i].type <- built_area[i].type;
						building[i].height <- type2height[building[i].type];
						building[i].min_height <- building[i].height[0];
						building[i].total_height <- building[i].height[1];
						building[i].storey_height <- building[i].height[2];
						building[i].higher <- built_area[i].higher;													
				}	
			flag <- 0;						
		}	
				
		exit {write "generate_buildings done";}
		transition to:end when:flag = 0 {}			
	}		
	
	state end {
		do pause;
	}		
//-----------------------------------------------↑end of fsm↑----------------------------------------------//	
	
	
//	reflex check {
//		
//	}
	
	
}//end of global
species building parallel:true{
	string type;
	rgb color;
	list<float> height; 
	float min_height;
	float total_height;
	float storey_height;	
	bool higher;

	aspect base {
		if higher {
			draw rectangle(15, 15) color:#white border:#black depth: total_height;//rnd(min_height, total_height, storey_height);			
		}
		else {
			draw rectangle(15, 15) color:#white border:#black depth: min_height;//rnd(min_height, total_height, storey_height);						
		}
	}
}

grid plot neighbors:8 file: grid_data{
	float num <- grid_value;
	string type <- num2type[num];
	rgb color <- type2color[type];
	bool build;
	bool higher;
	int sum_n;
	rgb c_n;
	int sum_road;

	list<plot> neighbors_ud1;//上下领域
	list<plot> neighbors_lr1;//左右领域
	list<plot> neighbors_udlr <- self neighbors_at 1;//十字领域;
	list<plot> neighbors_ud2;//扩展上下领域
	list<plot> neighbors_lr2;//扩展左右领域
	list<plot> neighbors_udlr2;//扩展十字领域
	list<plot> neighbors_12 <- self neighbors_at 2;//扩展冯诺依曼领域
	list<plot> neighbors_8 <- self.neighbors;//摩尔领域
	list<plot> neighbors_24 ;//扩展摩尔领域

	int sum_of_n_mroad <- 0;
	int sum_of_n_axis <- 0;
	int sum_of_n_ss update:neighbors_8 count (each.color = c_ss);
	int sum_of_n_academic update:neighbors_8 count (each.color = c_academic);
	int sum_of_n_admin update:neighbors_8 count (each.color = c_admin);
	int sum_of_n_rs update:neighbors_8 count (each.color = c_rs);
	int sum_of_n_green update:neighbors_8 count (each.color = c_green);		
	int sum_of_n_dormitory update:neighbors_8 count (each.color = c_dormitory);	
	int sum_of_n_residential update:neighbors_8 count (each.color = c_residential);	
	int sum_of_n_commercial update:neighbors_8 count (each.color = c_commercial);	
	int sum_of_n_school update:neighbors_8 count (each.color = c_school);
	int sum_of_n_transport update:neighbors_8 count (each.color = c_transport);
	int sum_of_n_mix update:neighbors_8 count (each.color = c_mix);	
	
//--------------------------------------↓plots action↓-----------------------------------//	
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
//--------------------------------------↑plots action↑-----------------------------------//	

//--------------------------------------↓architectures action↓-----------------------------------//		
	action academic_adapting {
		do load_neighbors_24;							       
						   									       								  		    			
		if (neighbors_24 count (each.color = #white)) >= 24 {
			//color <- flip(0.5)? type2color[type]:color;
			//color <- type2color[type];		
			build <- flip(0.8)? false:true;	
		}
	
	}
	
	action residential_adapting {
		neighbors_ud1 <- [plot[self.grid_x, self.grid_y-1], plot[self.grid_x, self.grid_y+1]];//上下领域

		if (neighbors_ud1 count (each.color = #white)) = 2 {
			build <- false;	
		}
	}

	action commercial_adapting {
		do load_neighbors_udlr2;
		 
	}

	action break_adapting {
		do load_neighbors_lr1;	
						   
		if neighbors_lr1 count (each.color = #white) = 2 {
			//color <- type2color[type];
			build <- flip(0.5)? false:true;
		}							   
	}
	
	action light_adapting {
		do load_neighbors_8;	
						   
		if neighbors_8 count (each.color = #white) >= 8 {
			//color <- type2color[type];
			build <- flip(0.9)? false:true;
		}							   
	}
	
	action detect_height {
		neighbors_ud1 <- [plot[self.grid_x, self.grid_y-1], plot[self.grid_x, self.grid_y+1]];//上下领域
		neighbors_lr1 <- [plot[self.grid_x-1, self.grid_y], plot[self.grid_x+1, self.grid_y]];//左右领域
		
		if neighbors_ud1 count (each.color = #white) = 2 or neighbors_lr1 count (each.color = #white) = 2 {
			higher <- flip(0.8)? true:false;
		}

	}	
//--------------------------------------↑architectures action↑-----------------------------------//		
	
	
	
//-----------------------------------------------领域相关-----------------------------------------//	
	action load_neighbors_ud1 {
		neighbors_ud1 <- [plot[self.grid_x, self.grid_y-1], plot[self.grid_x, self.grid_y+1]];//上下领域
	}
	action load_neighbors_lr1 {
		neighbors_lr1 <- [plot[self.grid_x-1, self.grid_y], plot[self.grid_x+1, self.grid_y]];//左右领域
	}	
	action load_neighbors_udlr{
		neighbors_udlr <- [plot[self.grid_x, self.grid_y-1], plot[self.grid_x, self.grid_y+1],
						   plot[self.grid_x-1, self.grid_y], plot[self.grid_x+1, self.grid_y]];//十字领域		
	}
	action load_neighbors_ud2{
		neighbors_ud2 <- [plot[self.grid_x, self.grid_y-1], plot[self.grid_x, self.grid_y-2], 
						  plot[self.grid_x, self.grid_y+1], plot[self.grid_x, self.grid_y+2]];//扩展上下领域		
	}
	action load_neighbors_lr2{
		neighbors_lr2 <- [plot[self.grid_x-1, self.grid_y], plot[self.grid_x-2, self.grid_y], 
						  plot[self.grid_x+1, self.grid_y], plot[self.grid_x+2, self.grid_y]];//扩展左右领域		
	}
	action load_neighbors_udlr2{
		neighbors_udlr2 <- [plot[self.grid_x, self.grid_y-1], plot[self.grid_x, self.grid_y-2], 
							plot[self.grid_x, self.grid_y+1], plot[self.grid_x, self.grid_y+2], 
							plot[self.grid_x-1, self.grid_y], plot[self.grid_x-2, self.grid_y], 
							plot[self.grid_x+1, self.grid_y], plot[self.grid_x+2, self.grid_y]];//扩展十字领域		
	}
	action load_neighbors_12{
		neighbors_12 <- neighbors + [plot[self.grid_x-2, self.grid_y], plot[self.grid_x+2, self.grid_y],
									 plot[self.grid_x, self.grid_y-2], plot[self.grid_x, self.grid_y+2]];//扩展冯诺依曼	
	}
	action load_neighbors_8{
		neighbors_8 <- neighbors;//摩尔领域 			
	}	
	action load_neighbors_24{
		neighbors_24 <- self neighbors_at 2;//扩展摩尔领域			
	}	
//-----------------------------------------------领域相关结束-----------------------------------------//		
	
}//end of species






experiment campus2 type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display map type:opengl  {
			light 1 color:(50); 
			species building aspect:base;
			grid plot;
		}
	}
}
