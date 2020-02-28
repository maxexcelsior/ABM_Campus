/***
* Name: campus1
* Author: pc
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model campus1

global {
	/** Insert the global definitions, variables and actions here */
	file road_file <- file("../includes/shp_file/road.shp");
	//file fill_file <- file("../includes/shp_file/fill.shp");
	file building_file <- file("../includes/shp_file/building.shp");
	file grid_data <- file('../includes/file.asc') ;
	
	
	geometry shape <- envelope(road_file);
	graph road_network;
	
	int nb_people <- 1000;
	float step <- 1 #minutes;
	float communicate_distance <- 2.0 #m;
	float proba_happy <- 0.5;
	int current_hour update: current_date.hour;
	int current_day update: current_date.day;
	float staying_coeff update: 10.0 ^ (1 + min([abs(current_hour - 9), abs(current_hour - 12), abs(current_hour - 18)]));
	int nb_happy_init <- 5;
	float happy_rate update: nb_happy/nb_people;
	
	list<people_in_building> ls_people_in_building update: (building accumulate each.people_in_building);
	int nb_happy <- nb_happy_init update: (people + ls_people_in_building) count (each.is_happy);
	int nb_not_happy <- nb_people - nb_happy_init update: nb_people - nb_happy; 
	
	
	init {
	
		create road from: road_file with: [hierachy::string(get("Layer"))];
		road_network <- as_edge_graph(road);
		//create fill from: fill_file;
		create building from: building_file;
		create people number:nb_people {
			speed <- 5.0 #km/#h;
			location <- any_location_in(one_of(building));
			 
		}
		
		map hierachies <- list(road) group_by each.hierachy;
		ask hierachies['primary']{color <- rgb(193,10,41); width <- 100.0;}//width只能接受0.0~10.0的浮点数，根据浮点数的差距决定线宽，不能指定实际距离
		ask hierachies['secondary']{color <- rgb(78,125,192); width <- 8.0;}
		ask hierachies['tertiary']{color <- rgb(202,181,68); width <- 8.0;}
		ask hierachies['sub']{color <- rgb(169,169,169); width <- 4.0;}
		ask hierachies['green']{color <- rgb(105,180,59); width <- 4.0;}
		
		ask nb_happy_init among people {
			is_happy <- true;
			write self.location;
		}
	}
	
	reflex stop when: happy_rate = 1.0 {
		do pause;
	}
}

species road {
	string hierachy;
	rgb color;
	float width;
	geometry display_shape <- shape ;
	aspect default {
		draw display_shape color: color width: width;
	}
}

species fill {
	float height <- 0.1#m;
	aspect default {//没人显示灰色，感染人数过半显示红色，否则绿色
		draw shape color:rgb(180,180,180) depth: height;
	}
}

species building {
	int nb_happy <- 0 update: self.people_in_building count each.is_happy;//定义一个计算建筑内感染人数的变量
	int nb_total <- 0 update:length(self.people_in_building);//定义一个计算内总人数的变量
	float height <- 24#m +rnd(5)#m;
	
	
	aspect default {
		draw shape color:#white depth: height;
	}
	
	//创建一个继承自people物种的子物种，内嵌于building物种，schedules为空则房子里的agent不会显示出来
	species people_in_building parent: people schedules: [] {}
	
	reflex let_people_leave  {
		ask  people_in_building {
			staying_counter <- staying_counter + 1;
		}
		//release语句允许某agent释放其中的micro-agent，agent可以释放micro-agent的首要条件是这个micro-agent是其他agent的子agent
		release people_in_building where (flip(each.staying_counter / staying_coeff)) as: people in: world  {//release a as: b in: world 将a释放为world中的b，同时改变他们的目的地
			target <- any_location_in (one_of(building));
		}
	}
	
	reflex let_people_enter {//target = nil 时即agent已经到达目的地或保持停留，所以此时可将其捕捉为micro-agent
		capture (people inside self where (each.target = nil)) as: people_in_building ;//capture a as: b 将a捕捉为b，即将macro-agent(a)转变为micro-agent(b)
	}
}

species people skills:[moving] {
	bool is_happy <- false;
	point target;
	int staying_counter;
	
	reflex move when:target != nil{
		do goto target:target on: road_network;
		if (location = target) {
			target <- any_location_in (one_of(building));
			target <- nil;
			staying_counter <- 0;
		} 
	}
	reflex happy when: is_happy {
		ask people at_distance communicate_distance {
			if flip(proba_happy) {
				is_happy <- true;
			}
		}
	}

	aspect sphere3D{//定义立体图例
		draw sphere(5) at: {location.x,location.y,location.z + 3} color:is_happy ? #red : #blue;
	}
}


grid cell file: grid_data{
	init {
		color<- grid_value = 0.0 ? #black  : (grid_value = 1.0  ? #green :   #yellow);
	}
}

experiment main type: gui {
	parameter "Communicate distance" var: communicate_distance;
	parameter "Proba communicate" var: proba_happy min: 0.0 max: 1.0;
	parameter "Number of creative people at init" var: nb_happy_init ;   
	output {
		monitor "Current day" value: current_day;
		monitor "Current hour" value: current_hour;
		monitor "Infected people rate" value: happy_rate;
		display map_3D type: opengl {//3D展示模型
		species road ;
		species fill ;
		species building transparency: 0.3;
		species people aspect: sphere3D;
		//species cell ;
		}



	}

}
