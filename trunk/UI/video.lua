-- This is script is used to update the water and fire
-- video only if the objects containing them are visible.

video = {};

video.water     = 0;
video.water_img = 0;
video.water_vid = 0;

video.fire			= 0;
video.fire001		= 0;
video.fire_img	= 0;
video.fire_vid	= 0;


function video.init()

	video.water     = SIO2.sio2ResourceGetObject( SIO2.sio2._SIO2resource, "object/zwater"    );
	video.water_img = SIO2.sio2ResourceGetImage ( SIO2.sio2._SIO2resource, "image/water.ogv" );
	video.water_vid = SIO2.sio2ResourceGetVideo ( SIO2.sio2._SIO2resource, "water"           );

	video.fire     = SIO2.sio2ResourceGetObject( SIO2.sio2._SIO2resource, "object/Window"     );
	video.fire001  = SIO2.sio2ResourceGetObject( SIO2.sio2._SIO2resource, "object/fire.001" );
	video.fire_img = SIO2.sio2ResourceGetImage ( SIO2.sio2._SIO2resource, "image/fire.ogv"  );
	video.fire_vid = SIO2.sio2ResourceGetVideo ( SIO2.sio2._SIO2resource, "fire"            );

end


function video.render_water()

	if video.water.dst then
	
		SIO2.sio2VideoGetImage( video.water_vid,
										  			video.water_img,
											 			SIO2.SIO2_IMAGE_MIPMAP,
											 			0.0 );
	end

end



function video.render_fire()

	if video.fire.dst or video.fire001.dst then
	
		SIO2.sio2VideoGetImage( video.fire_vid,
											 			video.fire_img,
											 			SIO2.SIO2_IMAGE_MIPMAP,
											 			0.0 );
	end

end
