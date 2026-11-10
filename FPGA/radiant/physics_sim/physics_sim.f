-L work
-reflib pmi_work
-reflib ovi_ice40up


"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/vga_timing.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/tb/tb_vga_timing.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/lab2_ta_counter.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/scene_renderer.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/tb/scene_renderer_tb.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/tb/tb_video_frame.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/demo_motion.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/track_renderer.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/tb/tb_track_frame.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/checkpoint_arches.sv"
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/race_scene.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/rtl/car_sprite.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/tb/tb_sprite_frame.sv" 
"C:/Users/thanderson/Documents/GitHub/e155-final-project/FPGA/tb/tb_physics_frames.sv" 
-sv
-optionset VOPTDEBUG
+noacc+pmi_work.*
+noacc+ovi_ice40up.*

-vopt.options
  -suppress vopt-7033
-end

-gui
-top tb_physics_frames
-vsim.options
  -suppress vsim-7033,vsim-8630,3009,3389
-end

-do "view wave"
-do "add wave /*"
-do "run -all"
