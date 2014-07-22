package components {
	import mx.core.UIComponent;
	import flash.geom.Point;
	
	/**
	 * Class has math methods for circles 
	 * @author aguard
	 * 
	 */
	public class CircleMath {
		
		/**
		 * number of degrees in a circle
		 */
		public static const NUM_DEGREES_IN_CIRCLE:Number = 360;
		
		
		/**
		 *
		 * Converts a length and angle to (x, y) coordinates on a circle
		 * @param radius in degrees
		 * @param angle out of 360 - default set to 12
		 * @returns a x, y point in cartesian space with 0,0 as center of circle
		 * 
		 */
		public static function getPointOnCircle( radius:Number, angle:Number ):Point {
			
			var radians:Number =  angle  * Math.PI / (NUM_DEGREES_IN_CIRCLE / 2);
			
			var position:Point = Point.polar(radius, radians);
			
			return position;
		}
		
		
		/**
		 * 
		 * Sets the center point of the clock
		 * @param width based on the unscaledWidth
		 * @param height based on the unscaledHeight
		 * @return 
		 * 
		 */
		public static function getCircleCenterPoint( width:Number, height:Number ):Point {
			
			var xcoord:Number = width / 2;
			
			var ycoord:Number = height / 2;
			
			var clockCenterPoint:Point = new Point(xcoord, ycoord);
			
			return clockCenterPoint;
		}
		
		
		/**
		 * constructor
		 * 
		 */
		public function CircleMath() {
			super();
		}
	}
}