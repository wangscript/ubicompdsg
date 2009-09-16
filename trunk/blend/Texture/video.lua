-- This is script is used to update the water and fire
-- video only if the objects containing them are visible.

video = {};

video.fire			= 0;
video.fire_img	= 0;
video.fire_vid	= 0;


function video.init()


	video.fire     = SIO2.sio2ResourceGetObject( SIO2.sio2._SIO2resource, "object/fire"     );
	video.fire_img = SIO2.sio2ResourceGetImage ( SIO2.sio2._SIO2resource, "image/fire.ogv"  );
	video.fire_vid = SIO2.sio2ResourceGetVideo ( SIO2.sio2._SIO2resource, "fire"            );

end




function video.render_fire()

	if video.fire.dst or video.fire001.dst then
	
		SIO2.sio2VideoGetImage( video.fire_vid,
											 			video.fire_img,
											 			SIO2.SIO2_IMAGE_MIPMAP,
											 			0.0 );
	end

end
