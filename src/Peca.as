package 
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Peca extends MovieClip
	{
		public var fundo:Array;
		private var withMouseMove:Boolean = false;
		private var posClick:Point;
		private var _inicialPosition:Point;
		public var currentFundo:DisplayObject;
		private var _ghost:MovieClip;
		public var nome:String;
		private var _classificacao:int = 3;
		private var spr_classificacao:Classificacao;
		public var ans_classificacao:int;
		//public var figura:MovieClip;
		
		private var _position:Point = new Point();
		
		public function Peca() 
		{
			this.mouseChildren = false;
			
			spr_classificacao = new Classificacao();
			addChild(spr_classificacao);
			spr_classificacao.x = 55;
			spr_classificacao.y = -35 / 2;
			spr_classificacao.gotoAndStop(_classificacao);
			spr_classificacao.mouseEnabled = false;
		}
		
		public function removeClassificacao():void
		{
			removeChild(spr_classificacao);
		}
		
		public function addListeners():void
		{
			addEventListener(MouseEvent.MOUSE_DOWN, initArraste);
		}
		
		private function initArraste(e:MouseEvent):void 
		{
			if (MovieClip(spr_classificacao).hitTestPoint(stage.mouseX, stage.mouseY)) {
				classificacao += 1;
				dispatchEvent(new Event("mudaClassificacao", true));
			}else{
				dispatchEvent(new Event("iniciaArraste", true));
				stage.addEventListener(MouseEvent.MOUSE_UP, stopArraste);
				this.parent.addChild(ghost);
				ghost.x = this.x;
				ghost.y = this.y;
				this.parent.setChildIndex(ghost, this.parent.numChildren - 1);
				if (withMouseMove) {
					posClick = new Point(ghost.mouseX, ghost.mouseY);
					stage.addEventListener(MouseEvent.MOUSE_MOVE, moving);
				}
				else ghost.startDrag();
			}
		}
		
		private function moving(e:MouseEvent):void 
		{
			ghost.x = parent.mouseX - posClick.x;
			ghost.y = parent.mouseY - posClick.y;
		}
		
		private function stopArraste(e:MouseEvent):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_UP, stopArraste);
			if (withMouseMove) {
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, moving);
			}
			else ghost.stopDrag();
			setPosition(ghost.x, ghost.y);
			this.parent.removeChild(ghost);
			dispatchEvent(new Event("paraArraste", true));
		}
		
		public function get position():Point
		{
			return _position;
		}
		
		private function setPosition(posX:Number, posY:Number):void
		{
			_position.x = posX;
			_position.y = posY;
		}
		
		public function get inicialPosition():Point
		{
			return _inicialPosition;
		}
		
		public function set inicialPosition(pos:Point):void
		{
			_inicialPosition = new Point(pos.x, pos.y);
		}
		
		public function get ghost():MovieClip 
		{
			return _ghost;
		}
		
		public function set ghost(value:MovieClip):void 
		{
			_ghost = value;
			_ghost.alpha = 0.5;
			//_ghost.scaleX = _ghost.scaleY = 0.5;
		}
		
		public function get classificacao():int 
		{
			return _classificacao;
		}
		
		public function set classificacao(value:int):void 
		{
			var val:int = value;
			if (val > 3) val = 1;
			_classificacao = val;
			
			spr_classificacao.gotoAndStop(val);
		}
		
	}

}