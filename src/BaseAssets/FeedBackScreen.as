package BaseAssets
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	/**
	 * ...
	 * @author Alexandre
	 */
	public class FeedBackScreen extends MovieClip
	{
		public var okCancelMode:Boolean = false;
		
		public function FeedBackScreen() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			this.x = stage.stageWidth / 2;
			this.y = stage.stageHeight / 2;
			
			//this.closeButton.addEventListener(MouseEvent.CLICK, closeScreen);
			//stage.addEventListener(KeyboardEvent.KEY_UP, escCloseScreen);
			
			this.gotoAndStop("END");
		}
		
		private function escCloseScreen(e:KeyboardEvent):void 
		{
			if (e.keyCode ==  Keyboard.ESCAPE) {
				if(this.currentFrame == 1) this.play();
			}
		}
		
		private function closeScreen(e:MouseEvent):void 
		{
			this.play();
			if (okCancelMode) dispatchEvent(new Event(Event.CLOSE, true));
			else dispatchEvent(new Event("FEEDBACK_CLOSED", true));
		}
		
		private function openScreen():void
		{
			this.gotoAndStop("BEGIN");
			if (okCancelMode) {
				cancelButton.visible = true;
				cancelButton.addEventListener(MouseEvent.CLICK, normalCloseScreen);
			}else {
				cancelButton.visible = false;
			}
			this.closeButton.addEventListener(MouseEvent.CLICK, closeScreen, false, 0, true);
		}
		
		private function normalCloseScreen(e:MouseEvent):void 
		{
			this.play();
		}
		
		public function setText(texto:String):void
		{
			openScreen();
			this.texto.text = texto;
		}
		
	}

}