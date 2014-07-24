package components {
	
	import flash.display.*;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.*;
	import flash.utils.Timer;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	import spark.components.Label;
	
	
	[Style(name="labelColor", type="uint", format="Color", inherit="yes")]
	[Style(name="secondsHandColor", type="uint", format="Color", inherit="yes")]
	[Style(name="minutesHandColor", type="uint", format="Color", inherit="yes")]
	[Style(name="hoursHandColor", type="uint", format="Color", inherit="yes")]
	[Style(name="labelSize", type="Number", format="Length", inherit="yes")]
	
	/**
	 * Dispatched when the time changes 
	 */
	[Event(name="currentTimeChange", type="flash.events.Event")]
	
	/**
	 * This class knows and shows the time on a clock
	 * @author aguard
	 */
	public class Clock extends UIComponent {
		
		/**
		 * The number of time markers on the clock - currently must be 12
		 */
		protected static const NUM_TIMEMARKERS_ON_CLOCKFACE:Number = 12;
		
		/**
		 * Multiplied by circle radius to calculate inset of labels containing digit symbols from the clock's edge
		 */
		protected static const DIGITS_OFFSET_AS_PERCENTAGE_OF_RADIUS:Number = 0.10;
		
		/**
		 * The width of the lines for the clock's center dot and outer edge
		 */
		protected static const CIRCLE_LINE_WIDTH:Number = 5;
		
		/**
		 * Width of the hour hand's line
		 */
		protected static const HOURS_HAND_WIDTH:Number = 4;
		
		/**
		 * Width of the minute hand's line
		 */
		protected static const MINUTES_HAND_WIDTH:Number = 3;
		
		/**
		 * Width of the second hand's line
		 */
		protected static const SECONDS_HAND_WIDTH:Number = 2;
		
		/**
		 * Number of minutes per hour
		 */
		protected static const NUM_MINUTES_PER_HOUR:Number = 60;
		
		/**
		 * Number of seconds per minute
		 */
		protected static const NUM_SECONDS_PER_MINUTE:Number = 60;
		
		/**
		 * Number of milliseconds per second
		 */
		protected static const NUM_MILLISECONDS_PER_SECOND:Number = 1000;
		
		/**
		 * Used to convert each second hand tick to a degree in a circle
		 */
		protected static const NUM_DEGREES_IN_MINUTE:Number = CircleMath.NUM_DEGREES_IN_CIRCLE / NUM_MINUTES_PER_HOUR;
		
		/**
		 * The radius of the centerpoint drawn in the middle of the circle
		 */
		protected static const CENTER_POINT_RADIUS:Number = 2;
		
		/**
		 * Length of hours hand as a proportion of the clock radius
		 */
		protected static const PROPORTION_OF_HOURS_HAND_TO_CLOCK_RADIUS:Number = 0.5;
		
		/**
		 * Length of minutes hand as a proportion of the clock radius 
		 */
		protected static const PROPORTION_OF_MINUTES_HAND_TO_CLOCK_RADIUS:Number = 0.6;
		
		/**
		 * Length of seconds hand as a proportion of the clock radius
		 */
		protected static const PROPORTION_OF_SECONDS_HAND_TO_CLOCK_RADIUS:Number = 0.7;
		
		/**
		 * Resets radian math by 90 degrees so the clock labels begin at the top of the circle
		 */
		protected static const RADIANS_OFFSET:Number = 90;
		
		/**
		 * Used to size the clock in proportion to the labelSize. 
		 */
		protected static const RATIO_OF_RADIUS_TO_LABEL_SIZE:Number = 18;
		
		/**
		 * How often the clock finds out the time
		 */
		protected static const TIMER_INTERVAL:Number = 250;
		
		/**
		 * Used to resize the clocks in updateDisplayList
		 */
		protected static const DIVISOR_TO_RESIZE_CLOCKS_PROPORTIONALLY_TO_PARENT:Number = 2.2;
		
		/**
		 * Default label size  
		 */
		protected static const LABEL_SIZE:Number = 22;
		
		/**
		 * Default clock font size 
		 */
		protected static const FONT_SIZE:Number = 15;
		
		/**
		 * Default clock numbers color 
		 */
		protected static const DEFAULT_LABEL_COLOR:String = "red";
		
		/**
		 * Default hours hand color 
		 */
		protected static const DEFAULT_HOURS_HAND_COLOR:Number = 234567;
		
		/**
		 * Default minutes hand color 
		 */
		protected static const DEFAULT_MINUTES_HAND_COLOR:Number = 234567;
		
		/**
		 * Default seconds hand color 
		 */
		protected static const DEFAULT_SECONDS_HAND_COLOR:Number = 234567;
		
		/**
		 * Default clock face color 
		 */
		protected static const DEFAULT_CLOCK_FACE_COLOR:Number = 234567;
		
		/**
		 * Used in styleChanged() and placeHourLabels() 
		 */
		protected static const MAXIMUM_HEIGHT_OF_LABELS_AS_PERCENTAGE_OF_CLOCK_RADIUS:Number = 0.3;
		
		/**
		 * Set in measure()
		 */
		protected static const DEFAULT_MINIMUM_HEIGHT_OF_COMPONENT:Number = 300;
		
		/**
		 * Set in measure()
		 */
		protected static const DEFAULT_MINIMUM_WIDTH_OF_COMPONENT:Number = 300;
		
		/**
		 * Used to set a default limit on how large fonts can be when clock dimensions are set. 
		 */
		protected static const RATIO_OF_RADIUS_TO_RESPONSIVE_FONT_SIZE:Number = 10;
		
		/**
		 * Event name for current time change
		 */
		public static const TIME_CHANGE:String = "currentTimeChange";
		
		/**
		 * Holds the timemarkers to iterate over and convert to a string
		 */
		protected var labels:Array;
		
		/**
		 * Timer for updating clock state
		 */
		protected var clockTimer:Timer;
		
		/**
		 * @private
		 * stores current time property
		 */
		protected var _currentTime:Date;
		
		[Bindable(event="currentTimeChange")]
		/**
		 * 
		 * Clock's current time
		 */
		public function get currentTime():Date {
			
			return _currentTime;
		}
		
		/**
		 * @private
		 */
		public function set currentTime( value : Date ):void {
			
			if ( _currentTime != value) {
				
				_currentTime = value;
				
				invalidateDisplayList();
				
				dispatchEvent(new Event(TIME_CHANGE));
			}
		}
		
		/**
		 * 
		 * @param event for a current time event handler
		 * 
		 */
		protected function handleTimer( event:TimerEvent ):void {
			
			currentTime = new Date();
		}	
		
		/**
		 * 
		 * Places time-markers on clock face
		 * @param clockCenterPoint a cartesian center of the circular clock
		 * @param radiansOffset is used to reset the beginning of placing clock elements at the top of the clock
		 * @param clockNumbersRadius a truncated radius based on the radius of the clock
		 * 
		 */
		
		private function placeHourLabels( clockCenterPoint:Point, clockRadius:Number ):void {
			
			if (labels) {
				for (var i:int = 0; i < labels.length; i++ ) {

					var label:Label = labels[ i ];
					if (label) {
						
						var labelWidth:Number = label.getExplicitOrMeasuredWidth();
						var labelHeight:Number = label.getExplicitOrMeasuredHeight();
						
						if ( ( labelHeight / clockRadius ) > MAXIMUM_HEIGHT_OF_LABELS_AS_PERCENTAGE_OF_CLOCK_RADIUS ) {
  							// To account for instances with two digits and twice the width as height
							labelWidth = labelWidth * ( 2 * MAXIMUM_HEIGHT_OF_LABELS_AS_PERCENTAGE_OF_CLOCK_RADIUS );
							labelHeight = labelHeight * MAXIMUM_HEIGHT_OF_LABELS_AS_PERCENTAGE_OF_CLOCK_RADIUS;
						}
						
						var clockTimeMarkersRadius:Number = clockRadius - labelHeight;
						var labelPositionXOffset:Number = labelWidth / 2;
						var labelPositionYOffset:Number = labelHeight / 2;
						
						label.setActualSize( labelWidth, labelHeight );
						
						var angle:Number = i * ( CircleMath.NUM_DEGREES_IN_CIRCLE / NUM_TIMEMARKERS_ON_CLOCKFACE ) - RADIANS_OFFSET;
						var labelPosition:Point = CircleMath.getPointOnCircle( clockTimeMarkersRadius, angle );
						var xCoord:Number = clockCenterPoint.x - ( labelPositionXOffset );
						var yCoord:Number = clockCenterPoint.y - ( labelPositionYOffset );
						
						labelPosition.offset( xCoord,  yCoord );
						label.move( labelPosition.x, labelPosition.y );
					}
				}
			}
		}
		
		/**
		 * 
		 * Moves the hands of the clock
		 * @param g graphics object on which to draw
		 * @param circleRadius the radius of the circular clock
		 * @param clockCenterPoint cartesian centerpoint of the clock
		 * @param angle the cartesian angle of the clockhand within the clockface circle
		 * 
		 */
		private function moveClockHand( g:Graphics, circleRadius:Number, clockCenterPoint:Point,  handLength:Number, angle:Number ):void {
			
			var handCoordinates:Point = CircleMath.getPointOnCircle(circleRadius * handLength, angle - RADIANS_OFFSET);
			var handXCoord:Number = handCoordinates.x + clockCenterPoint.x;
			var handYCoord:Number = handCoordinates.y + clockCenterPoint.y;
			
			g.moveTo( clockCenterPoint.x, clockCenterPoint.y );
			g.lineTo( handXCoord, handYCoord );
		}
		
		
		/**
		 * 
		 * Used to help calculate the angle of minute and hour hands
		 * @param secondsCount
		 * @return secondsProportion a fraction of the (current seconds amount of the current time) / (the number of minutes per hour * the number of seconds per minute)
		 * 
		 */
		private function calculateSecondsProportion( secondsCount:Number ):Number {
			
			var secondsProportion:Number = ( secondsCount / (NUM_MINUTES_PER_HOUR * NUM_SECONDS_PER_MINUTE) );
			return secondsProportion;
		}
		
		
		/**
		 * 
		 * Used to help calculate the angle of minute and hour hands
		 * @param minutesCount
		 * @return minutesProportion a fraction of the (current minutes amount of the current time) / (the number of minutes per hour)
		 * 
		 */
		private function calculateMinutesProportion( minutesCount:Number ):Number {
			
			var minutesProportion:Number = ( minutesCount / NUM_MINUTES_PER_HOUR );
			return minutesProportion;
		}
		
		
		/**
		 *
		 * Draws the hour hand based on the radius of the clock and the current time
		 * @param g graphics object on which to draw
		 * @param clockCenterPoint cartesian centerpoint of the clock
		 * @param circleRadius the radius of the circular clock
		 * @param hoursCount number of hours in currentTime
		 * @param minutesCount number of minutes in currentTime
		 * @param secondsCount number of seconds in currentTime
		 * 
		 */
		private function positionHoursHand( g:Graphics, clockCenterPoint:Point, circleRadius:Number, hoursCount:Number, minutesCount:Number, secondsCount:Number ):void {
			
			var hoursHandColor:* = getStyle( "hoursHandColor" );
			
			if ( hoursHandColor == undefined  ) {
				hoursHandColor = DEFAULT_HOURS_HAND_COLOR;
			}
			g.lineStyle( HOURS_HAND_WIDTH, hoursHandColor );
			
			var handLength:Number = PROPORTION_OF_HOURS_HAND_TO_CLOCK_RADIUS;
			var secondsProportion:Number = calculateSecondsProportion(secondsCount);
			var minutesProportion:Number = calculateMinutesProportion(minutesCount);
			var hoursProportion:Number = (hoursCount / NUM_TIMEMARKERS_ON_CLOCKFACE);
			var numOfClockFaceMarkersDivisor:Number = (1 / NUM_TIMEMARKERS_ON_CLOCKFACE);
			var hourHandCalibrator:Number = hoursProportion + minutesProportion * numOfClockFaceMarkersDivisor + secondsProportion * numOfClockFaceMarkersDivisor;
			var angle:Number = hourHandCalibrator * CircleMath.NUM_DEGREES_IN_CIRCLE;
			
			moveClockHand(g, circleRadius, clockCenterPoint, handLength, angle);
		}
		
		
		/**
		 *
		 * Draws the minute hand based on the radius of the clock and the current time 
		 * @param g graphics object on which to draw
		 * @param clockCenterPoint cartesian centerpoint of the clock
		 * @param circleRadius the radius of the circular clock
		 * @param minutesCount number of minutes in currentTime
		 * @param secondsCount number of seconds in currentTime
		 * 
		 */
		private function positionMinutesHand( g:Graphics, clockCenterPoint:Point, circleRadius:Number, minutesCount:Number, secondsCount:Number ):void {
			
			var minutesHandColor:* = getStyle("minutesHandColor");
			
			if ( minutesHandColor == undefined ) {
				minutesHandColor = DEFAULT_MINUTES_HAND_COLOR;
			}
			
			g.lineStyle(MINUTES_HAND_WIDTH, minutesHandColor);
			
			var handLength:Number = PROPORTION_OF_MINUTES_HAND_TO_CLOCK_RADIUS;
			var secondsProportion:Number = calculateSecondsProportion(secondsCount);
			var minutesProportion:Number = calculateMinutesProportion(minutesCount);
			var minutesHandCalibrator:Number = ( minutesProportion + secondsProportion );
			var angle:Number = minutesHandCalibrator * CircleMath.NUM_DEGREES_IN_CIRCLE;
			
			moveClockHand(g, circleRadius, clockCenterPoint, handLength, angle);
		}
		
		
		/**
		 *
		 * Draws the second hand based on the radius of the clock and the current time 
		 * @param g graphics object on which to draw
		 * @param clockCenterPoint cartesian centerpoint of the clock
		 * @param circleRadius the radius of the circular clock
		 * @param secondsCount number of seconds in currentTime
		 * @param millisecondsCount the number of milliseconds in currentTime
		 * 
		 */
		private function positionSecondsHand( g:Graphics, clockCenterPoint:Point, circleRadius:Number, secondsCount:Number, millisecondsCount:Number ):void {
			
			var secondsHandColor:* = getStyle("secondsHandColor");
			
			if ( secondsHandColor == undefined ) {
				secondsHandColor = DEFAULT_SECONDS_HAND_COLOR;
			}
			
			g.lineStyle(SECONDS_HAND_WIDTH, secondsHandColor);
			
			var handLength:Number = PROPORTION_OF_SECONDS_HAND_TO_CLOCK_RADIUS;
			var secondsHandCalibrator:Number = millisecondsCount / NUM_MILLISECONDS_PER_SECOND;
			var adjustedCount:uint = Math.floor(secondsCount + secondsHandCalibrator);
			var angle:Number = NUM_DEGREES_IN_MINUTE * adjustedCount;	
			
			moveClockHand(g, circleRadius, clockCenterPoint, handLength, angle);
		}
		
		
		/**
		 *
		 * Draws the outer boundary of the clock face 
		 * @param g graphics object on which to draw
		 * @param clockCenterPoint cartesian centerpoint of clock
		 * @param circleRadius the radius of the circular clock
		 * 
		 */
		private function drawClockFace( g:Graphics, clockCenterPoint:Point, circleRadius:Number, clockFaceColor:* ):void {
			
			g.lineStyle(CIRCLE_LINE_WIDTH, clockFaceColor);
			g.drawCircle(clockCenterPoint.x, clockCenterPoint.y, circleRadius);
		}
		
		
		/**
		 *
		 * Draws a small circle in the middle of the clock 
		 * @param g graphics object on which to draw
		 * @param clockCenterPoint a cartesian center of the circlular clock
		 * 
		 */
		private function drawClockCenterPoint( g:Graphics, clockCenterPoint:Point, clockFaceColor:* ):void {	
			
			g.lineStyle(CIRCLE_LINE_WIDTH, clockFaceColor);
			g.drawCircle(clockCenterPoint.x, clockCenterPoint.y, CENTER_POINT_RADIUS);
		}
		
		
		/**
		 * 
		 * Breaks apart current time into separate vars for hours, minutes, seconds, and milliseconds and passes the vars to the clock hands
		 * @param g graphics object on which to draw
		 * @param clockCenterPoint cartesian centerpoint of clock
		 * @param circleRadius the radius of the circular clock
		 * @param currentTime the current time 
		 * 
		 */
		private function callClockHands( g:Graphics, clockCenterPoint:Point, circleRadius:Number, currentTime:Date ):void {
			
			var hoursCount:Number = currentTime.getHours();
			var minutesCount:Number = currentTime.getMinutes();
			var secondsCount:Number = currentTime.getSeconds();
			var millisecondsCount:Number = currentTime.getMilliseconds();
			
			//to make sure that the hours count is never greater than 12
			hoursCount = hoursCount % NUM_TIMEMARKERS_ON_CLOCKFACE;
			
			positionHoursHand(g, clockCenterPoint, circleRadius, hoursCount, minutesCount, secondsCount);
			positionMinutesHand(g, clockCenterPoint, circleRadius, minutesCount, secondsCount);
			positionSecondsHand(g, clockCenterPoint, circleRadius, secondsCount, millisecondsCount);
		}
		
		
		/**
		 * 
		 * Displays the clock elements
		 * @param g graphics object on which to draw
		 * @param clockCenterPoint cartesian centerpoint of clock
		 * @param clockNumbersRadius a truncated radius based on the radius of the clock
		 * @param xLengthOfLabelForTimedigits width of labels for clock time markers
		 * @param yLengthOfLabelForTimedigits height of labels for clock time markers
		 * @param clockRadius the radius of the clock
		 * @param currentTime the current time
		 * 
		 */
		private function drawClock( clockRadius:Number, currentTime:Date ):void {
			
			var g:Graphics = this.graphics;
			g.clear();

			var clockCenterPoint:Point = CircleMath.getCircleCenterPoint(unscaledWidth, unscaledHeight);
			var clockFaceColor:* = getStyle( "clockFaceColor" );
			
			if ( clockFaceColor == undefined ) {
				clockFaceColor = DEFAULT_CLOCK_FACE_COLOR;
			}
			
			drawClockFace(g, clockCenterPoint, clockRadius, clockFaceColor);
			drawClockCenterPoint(g, clockCenterPoint, clockFaceColor);
			callClockHands(g, clockCenterPoint, clockRadius, currentTime);
			placeHourLabels(clockCenterPoint, clockRadius);
		}
		
		
		/**
		 * 
		 * Calculates the radius of the clock based off of unscaledWidth and unscaledHeight
		 * @param width based on the unscaledWidth
		 * @param height based on the unscaledHeight
		 * @return 
		 * 
		 */
		private function getClockRadius( width:Number, height:Number ):Number {
			
			var clockRadius:Number = Math.min(width, height) / DIVISOR_TO_RESIZE_CLOCKS_PROPORTIONALLY_TO_PARENT;
			return clockRadius;
		}
		

		/**
		 * Returns an adjusted label height based on the radius of the circle.
		 * @return 
		 * 
		 */
		private function getAdjustedHeightBasedOnLabelSize():Number {
			
			if ( labels ) {
				
				var label:Label = labels[ 0 ];
				
				if ( label ) {
					var fontSize:Number = label.getStyle( "fontSize" );
					var adjustedHeight:Number = fontSize * RATIO_OF_RADIUS_TO_LABEL_SIZE;
				}
			}
			return adjustedHeight;
		}
		

		/**
		 * Sets the clock radius based on the label sizes and, if the clock's dimensions are defined, 
		 * limits its size to the proscribed size. 
		 * @return 
		 * 
		 */
		private function setClockRadius():Number {
			
			var clockHeight:Number = this.getExplicitOrMeasuredHeight();
			var adjustedHeight:Number = getAdjustedHeightBasedOnLabelSize();
			var minimumHeight:Number = Math.max( clockHeight, adjustedHeight );
			var preferredHeight:Number = Math.min( minimumHeight, clockHeight );
			var maxFontSize:Number = preferredHeight / RATIO_OF_RADIUS_TO_RESPONSIVE_FONT_SIZE;
			
			if ( preferredHeight == clockHeight ) {
				
				if ( labels ) {
					
					for ( var j:int = 0; j < labels.length; j++ ) {
						
						var adjustedLabel:Label = labels[ j ];
						var responsiveFontSize:Number = adjustedLabel.getStyle( "fontSize" );
						
						if ( responsiveFontSize > maxFontSize ) {
							responsiveFontSize = maxFontSize;
						}
						adjustedLabel.setStyle( "fontSize", responsiveFontSize );
					}
				}
			}
			
			var adjustedClockRadius:Number = getClockRadius( preferredHeight, preferredHeight );
			var maxRadiusOfClock:Number = ( clockHeight / 2 );
			
			if ( adjustedClockRadius > maxRadiusOfClock ) {
				adjustedClockRadius = maxRadiusOfClock;
			}
			return adjustedClockRadius;
		}
		
		
		/**
		 * 
		 * @inheritDoc
		 * 
		 */
		override protected function updateDisplayList( unscaledWidth:Number, unscaledHeight:Number ):void { 
			
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			var adjustedClockRadius:Number = setClockRadius();
			
			if ( currentTime ) {
				drawClock( adjustedClockRadius, currentTime );
			}
		}
		
		
		/**
		 * 
		 * For styling the clock - changes label colors and sizes
		 * @param styleProp
		 * 
		 */
		override public function styleChanged( styleProp:String ):void { 
			
			var checkAllProps:Boolean = ( styleProp == null ) || ( styleProp == "" );
			
			if ( labels ) {
				if ( checkAllProps || styleProp == "labelColor" ) {
					var labelColor:* = getStyle( styleProp );
					if ( labelColor != undefined ) {
						for ( var i:int = 0; i < labels.length; i++ ) {
							var currentColor:* = labels[i].getStyle( "color" );
							if ( labelColor != currentColor ) {
								labels[i].setStyle("color", labelColor);
							}
						}
					}
				}
			}
			
			if ( checkAllProps || styleProp == "labelSize" ) {
				var labelSize:* = getStyle( styleProp );
				if ( labelSize == undefined ) {
					labelSize = LABEL_SIZE;
				}  
				
				if ( labels ) {
					for ( var j:int = 0; j < labels.length; j++ ) {
						var label:Label = labels[ j ];
						var fontSize:Number = getStyle( styleProp );
						if ( fontSize as Number ) {
							fontSize;
						} else {
							fontSize = FONT_SIZE;
						}
							
						if ( label ) {
							var currentFontSize:Number = label.getStyle( "fontSize" );
							if ( fontSize != currentFontSize ) { 
								label.setStyle( "fontSize", fontSize );
							}
						}
					}
				}
			}
			super.styleChanged( styleProp );
		}
		
		
		/**
		 * @inheritDoc 
		 * Is used when the developer does not specify dimensions for the clock.
		 */
		override protected function measure():void {
			super.measure();
			var fontSize:Number;
			
			if ( labels ) 
			{
				var label:Label = labels[ 0 ];
				fontSize = label.getStyle( "fontSize" );
			} 
			else 
			{
				fontSize = FONT_SIZE;
			}
			
			var defaultMinimumOfComponentDimension:Number = fontSize * RATIO_OF_RADIUS_TO_LABEL_SIZE;
			this.measuredHeight = this.measuredMinHeight = defaultMinimumOfComponentDimension;
			this.measuredWidth = this.measuredMinWidth = defaultMinimumOfComponentDimension;
			
		}
		
		
		/**
		 * Creates a label to use for time-markers
		 * @param clockNumber a string, currently from 1 through 12
		 * @return a label with text for clock time-markers.
		 */
		protected function createLabel( clockNumber:String ):Label {

			var label:Label = new Label();
			label.text = clockNumber;
			label.setStyle( "textAlign", "center" );
			var clockColor:* = this.getStyle( "labelColor" );
			if ( clockColor == undefined ) {
				label.setStyle( "color", DEFAULT_LABEL_COLOR );
			} else {
				label.setStyle( "color", clockColor );
			}
			var labelSize:* = this.getStyle( "labelSize" );
			if ( labelSize == undefined ) {
				labelSize = LABEL_SIZE;
			} 
			
			label.setStyle("fontSize", labelSize );
			return label;
		}
		

		/**
		 * @inheritDoc
		 * 	Begins the clock timer, creates an array of numbers to 
		 *  represent time digits on the clock face - depicted as 
		 * 	strings. Replaces "0" with "12".
		 */
		override protected function createChildren():void {
			super.createChildren();
			if ( !labels ) {
				labels = new Array();	
				for ( var i:int = 0; i < NUM_TIMEMARKERS_ON_CLOCKFACE; i++ ) {
					var hourLabel:String;
					switch ( i ) {
						case ( 0 ): 
							hourLabel = "XII";
							break;
						case ( 1 ):
							hourLabel = "I";
							break;
						case ( 2 ): 
							hourLabel = "II";
							break;
						case ( 3 ):
							hourLabel = "III";
							break;
						case ( 4 ): 
							hourLabel = "IV";
							break;
						case ( 5 ):
							hourLabel = "V";
							break;
						case ( 6 ): 
							hourLabel = "VI";
							break;
						case ( 7 ):
							hourLabel = "VII";
							break;
						case ( 8 ): 
							hourLabel = "VIII";
							break;	
						case ( 9 ):
							hourLabel = "IX";
							break;
						case ( 10 ): 
							hourLabel = "X";
							break;
						case ( 11 ):
							hourLabel = "XI";
							break;
					}
					var label:Label = createLabel( hourLabel );
					labels.push( label );
					addChild( label );
				}
			}
		}
		
		
		/**
		 * @inheritDoc
		 * 	Creates a timer to update the clock time every second
		 */
		override public function initialize():void {
			
			super.initialize();
			clockTimer = new Timer(TIMER_INTERVAL);
			clockTimer.addEventListener(TimerEvent.TIMER, handleTimer, false, 0, true);
			clockTimer.start();
		}
		
		
		/**
		 * Constructor
		 */
		public function Clock() {
			
			super();
		}
	}
}