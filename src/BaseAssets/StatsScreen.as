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
	public class StatsScreen extends MovieClip
	{
		private var stats:Object = new Object();;
		
		public function StatsScreen() 
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
			stage.addEventListener(KeyboardEvent.KEY_UP, escCloseScreen);
			addEventListener(KeyboardEvent.KEY_UP, escCloseScreen);
			
			this.gotoAndStop("END");
			
			stats.nTotal = 0;
			stats.nValendo = 0;
			stats.nNaoValendo = 0;
			stats.scoreMin = 0;
			stats.scoreTotal = 0;
			stats.scoreValendo = 0;
			stats.valendo = false;
		}
		
		private function escCloseScreen(e:KeyboardEvent):void 
		{
			if (e.keyCode ==  Keyboard.ESCAPE) {
				if (this.currentFrame == 1) closeScreen(null);
			}
		}
		
		private function closeScreen(e:MouseEvent):void 
		{
			this.play();
			dispatchEvent(new Event(Event.CLOSE, true));
		}
		
		public function openScreen():void
		{
			this.gotoAndStop("BEGIN");
			this.closeButton.addEventListener(MouseEvent.CLICK, closeScreen, false, 0, true);
			updateStatics();
		}
		
		public function updateStatics(stats:Object = null):void
		{
			if(stats != null){
				this.stats.nTotal = stats.nTotal;
				this.stats.nValendo = stats.nValendo;
				this.stats.nNaoValendo = stats.nNaoValendo;
				this.stats.scoreMin = stats.scoreMin;
				this.stats.scoreTotal = stats.scoreTotal;
				this.stats.scoreValendo = stats.scoreValendo;
				this.stats.valendo = stats.valendo;
			}
			
			if (this.currentFrame == 1) {
				nTotal.text = this.stats.nTotal;
				nValendo.text = this.stats.nValendo;
				nNaoValendo.text = this.stats.nNaoValendo;
				scoreMin.text = String(this.stats.scoreMin).replace(".", "");
				scoreTotal.text = String(this.stats.scoreTotal).replace(".", "");
				scoreValendo.text = String(this.stats.scoreValendo).replace(".", "");
				
				if (this.stats.valendo) {
					valendoMC.gotoAndStop("VALENDO");
					valendoText.visible = false;
				}
				else {
					valendoMC.gotoAndStop("NAO_VALENDO");
					valendoText.visible = true;
				}
			}
		}
		
	}

}