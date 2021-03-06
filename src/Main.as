﻿package 
{
	import BaseAssets.BaseMain;
	import com.adobe.serialization.json.JSON;
	import cepa.utils.ToolTip;
	import com.eclecticdesignstudio.motion.Actuate;
	import com.eclecticdesignstudio.motion.easing.Elastic;
	import com.eclecticdesignstudio.motion.easing.Linear;
	import fl.transitions.easing.None;
	import fl.transitions.Tween;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.setTimeout;
	import flash.utils.Timer;
	import pipwerks.SCORM;
	
	/**
	 * ...
	 * @author Alexandre
	 */
	public class Main extends BaseMain
	{
		private const HAPLOIDE:int = 1;
		private const DIPLOIDE:int = 2;
		
		private var tweenX:Tween;
		private var tweenY:Tween;
		
		private var tweenX2:Tween;
		private var tweenY2:Tween;
		
		private var tweenTime:Number = 0.2;
		private var timerFilterPecas:Timer = new Timer(400, 1);
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			scrollRect = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			
			addListeners();
			createAnswer();
			
			sortPecas();
			verificaFinaliza();
			
			if (ExternalInterface.available) {
				initLMSConnection();
				if (mementoSerialized != null) {
					if(mementoSerialized != "" && mementoSerialized != "null") recoverStatus(mementoSerialized);
				}
			}
			
			if (completed) {
				travaPecas();
			}else iniciaTutorial();
			
			//if(!completed) iniciaTutorial();
		}
		
		private var nPecas:int = 15;
		private function sortPecas():void 
		{
			var posicoesIniciaisFundos:Vector.<Fundo> = new Vector.<Fundo>();
			var fundo:Fundo;
			var child:DisplayObject;
			
			for (var i:int = 1; i <= nPecas; i++) 
			{
				fundo = this["fundo" + i];
				posicoesIniciaisFundos.push(fundo);
			}
			
			for (i = 0; i < numChildren; i++) 
			{
				child = getChildAt(i);
				if (child is Peca) {
					fundo = Fundo(posicoesIniciaisFundos.splice(Math.floor(Math.random() * posicoesIniciaisFundos.length), 1)[0]);
					Peca(child).x = fundo.x;
					Peca(child).y = fundo.y;
					//Peca(child).inicialPosition = new Point(child.x, child.y);
					Peca(child).currentFundo = fundo;
					fundo.currentPeca = Peca(child);
					Peca(child).gotoAndStop(2);
					Peca(child).classificacao = 3;
				}
			}
		}
		
		private function addListeners():void 
		{
			finaliza.addEventListener(MouseEvent.CLICK, finalizaExec);
			finaliza.buttonMode = true;
			timerFilterPecas.addEventListener(TimerEvent.TIMER_COMPLETE, timerCompleted);
			timerForScale.addEventListener(TimerEvent.TIMER_COMPLETE, sclaeObjs);
		}
		
		private var overAlowed:Boolean = true;
		private var wrongFilter:GlowFilter = new GlowFilter(0xFF0000, 0.8, 6, 6, 3, 2);
		private var rightFilter:GlowFilter = new GlowFilter(0x008000, 0.8, 6, 6, 3, 2);
		
		private function finalizaExec(e:MouseEvent):void 
		{
			var nCertasPos:int = 0;
			var nCertasClass:int = 0;
			var nPecas:int = 0;
			
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					nPecas++;
					//Posicao
					if(Peca(child).fundo.indexOf(Peca(child).currentFundo) != -1){
						nCertasPos++;
						Peca(child).pecaErrada = [rightFilter];
					}else {
						Peca(child).pecaErrada = [wrongFilter];
					}
					
					//Classificacao:
					if(Peca(child).classificacao == Peca(child).ans_classificacao){
						nCertasClass++;
						Peca(child).classificacaoErrada = [rightFilter];
					}else {
						Peca(child).classificacaoErrada = [wrongFilter];
					}
				}
			}
			
			var currentScore:int = int((nCertasPos / nPecas) * 50);
			currentScore += int((nCertasClass / nPecas) * 50);
			
			if(e != null){
				if (currentScore < 100) {
					feedbackScreen.setText("Sua pontuação foi de " + currentScore + "%. As respostas erradas estão destacadas em vermelho.");
				}
				else {
					feedbackScreen.setText("Parabéns!\nSua resposta está correta!");
				}
			
			
				if (!completed) {
					completed = true;
					score = currentScore;
					saveStatus();
					commit();
					
					travaPecas();
				}
				
				setChildIndex(feedbackScreen, numChildren - 1);
			}
		}
		
		private function travaPecas():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					//Peca(child).mouseEnabled = false;
					Peca(child).removeListeners();
				}
			}
			
			lock(botoes.resetButton);
		}
		
		private function verificaFinaliza():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if (Peca(child).currentFundo == null || Peca(child).classificacao == 3) {
						lock(finaliza);
						return;
					}
				}
			}
			
			unlock(finaliza);
		}
		
		private function createAnswer():void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					setAnswerForPeca(Peca(child));
					var objClass:Class = Class(getDefinitionByName(getQualifiedClassName(child)));
					var ghostObj:* = new objClass();
					MovieClip(ghostObj).gotoAndStop(2);
					Peca(ghostObj).removeClassificacao();
					Peca(child).ghost = ghostObj;
					Peca(child).addListeners();
					//Peca(child).inicialPosition = new Point(child.x, child.y);
					child.addEventListener("paraArraste", verifyPosition);
					child.addEventListener("iniciaArraste", verifyForFilter);
					Peca(child).buttonMode = true;
					Peca(child).gotoAndStop(1);
					Peca(child).addEventListener(MouseEvent.MOUSE_OVER, overPeca);
					Peca(child).addEventListener(MouseEvent.MOUSE_OUT, outPeca);
					Peca(child).addEventListener("mudaClassificacao", mudaClassificacao);
				}else if (child is Fundo) {
					var finalFundoName:String = child.name.replace("fundo", "");
					Fundo(child).figura = this["fig" + finalFundoName];
					Fundo(child).linha = this["linha" + finalFundoName];
				}
				
			}
		}
		
		private function mudaClassificacao(e:Event):void 
		{
			removeFiltersPecas();
			var peca:Peca = Peca(e.target);
			classificacaoOver = peca.classificacao;
			
			if (timerFilterPecas.running) {
				timerFilterPecas.stop();
				timerFilterPecas.reset();
			}
			timerFilterPecas.start();
			//addFiltersPecas(peca.classificacao);
			
			saveStatus();
			verificaFinaliza();
		}
		
		private var classificacaoOver:int;
		private function overPeca(e:MouseEvent):void 
		{
			if (!overAlowed) return;
			
			timerFilterPecas.start();
			
			
			var peca:Peca = Peca(e.target);
			classificacaoOver = peca.classificacao;
			//addFiltersPecas(peca.classificacao);
			
		}
		
		private function timerCompleted(e:TimerEvent):void 
		{
			addFiltersPecas(classificacaoOver);
		}
		
		private var alphaTweenTime:Number = 0.6;
		private var nonN:int = 11;
		private var timerForScale:Timer = new Timer(650, 1);
		private function addFiltersPecas(classificacao:int):void 
		{
			removeFiltersPecas();
			
			if (classificacao == 3) return;
				
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if (Peca(child).classificacao != classificacao) {
						/*
						child.alpha = 0.2;
						child.filters = [GRAYSCALE_FILTER];
						
						Fundo(Peca(child).currentFundo).figura.alpha = 0.2;
						Fundo(Peca(child).currentFundo).figura.filters = [GRAYSCALE_FILTER];
						
						Fundo(Peca(child).currentFundo).alpha = 0.2;
						Fundo(Peca(child).currentFundo).filters = [GRAYSCALE_FILTER];
						*/
						
						Actuate.tween(child, alphaTweenTime, { alpha:0.2 } ).ease(Linear.easeNone).onComplete(setFilter, child);
						Actuate.tween(Fundo(Peca(child).currentFundo).figura, alphaTweenTime, {alpha:0.2 } ).ease(Linear.easeNone).onComplete(setFilter, Fundo(Peca(child).currentFundo).figura);
						Actuate.tween(Fundo(Peca(child).currentFundo).linha, alphaTweenTime, {alpha:0.2 } ).ease(Linear.easeNone).onComplete(setFilter, Fundo(Peca(child).currentFundo).linha);
						Actuate.tween(Fundo(Peca(child).currentFundo), alphaTweenTime, {alpha:0.2 } ).ease(Linear.easeNone).onComplete(setFilter, Fundo(Peca(child).currentFundo));
					}
				}
			}
			
			for (var j:int = 1; j <= nonN ; j++) 
			{
				Actuate.tween(this["non" + j], alphaTweenTime, { alpha:0.2 } ).ease(Linear.easeNone).onComplete(setFilter, this["non" + j]);
			}
			
			//timerForScale.start();
			
		}
		
		private function setFilter(obj:*):void 
		{
			obj.filters = [GRAYSCALE_FILTER];
		}
		
		private function removeFilter(obj:*):void 
		{
			obj.filters = [];
		}
		
		private function sclaeObjs(e:TimerEvent):void 
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if (Peca(child).alpha == 1) {
						Actuate.tween(Fundo(Peca(child).currentFundo).figura, 0.3, {scaleX:3, scaleY:3 } ).ease(Elastic.easeOut);
					}
				}
			}
		}
		
		private function outPeca(e:MouseEvent):void 
		{
			if (!overAlowed) return;
			
			if (timerFilterPecas.running) {
				timerFilterPecas.stop();
				timerFilterPecas.reset();
				return;
			}
			var peca:Peca = Peca(e.target);
			
			removeFiltersPecas();
		}
		
		private function removeFiltersPecas():void 
		{
			if (timerForScale.running) {
				timerForScale.stop();
				timerForScale.reset();
			}
			if (timerFilterPecas.running) {
				timerFilterPecas.stop();
				timerFilterPecas.reset();
			}
			
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					
					Actuate.stop(child, null, true );
					Actuate.stop(Fundo(Peca(child).currentFundo).figura, null );
					Actuate.stop(Fundo(Peca(child).currentFundo).linha, null );
					Actuate.stop(Fundo(Peca(child).currentFundo), null);
					
					Actuate.stop(Fundo(Peca(child).currentFundo).figura, null);
					
					child.alpha = 1;
					child.filters = [];
					
					Fundo(Peca(child).currentFundo).figura.alpha = 1;
					Fundo(Peca(child).currentFundo).linha.alpha = 1;
					Fundo(Peca(child).currentFundo).figura.filters = [];
					Fundo(Peca(child).currentFundo).linha.filters = [];
					Fundo(Peca(child).currentFundo).figura.scaleX = Fundo(Peca(child).currentFundo).figura.scaleY = 1;
					
					Fundo(Peca(child).currentFundo).alpha = 1;
					Fundo(Peca(child).currentFundo).filters = [];
					
					
				}
			}
			
			for (var j:int = 1; j <= nonN ; j++) 
			{
				Actuate.stop(this["non" + j], null);
				this["non" + j].alpha = 1;
				this["non" + j].filters = [];
			}
		}
		
		private function saveStatusForRecovery(e:MouseEvent = null):void
		{
			var status:Object = new Object();
			
			status.pecas = new Object();
			status.classificacoes = new Object();
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if (Peca(child).currentFundo != null) {
						status.pecas[child.name] = Peca(child).currentFundo.name;
						status.classificacoes[child.name] = Peca(child).classificacao;
					}
					else status.pecas[child.name] = "null";
				}
			}
			
			mementoSerialized = JSON.encode(status);
		}
		
		private function recoverStatus(memento:String):void
		{
			var status:Object = JSON.decode(memento);
			
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					if (status.pecas[child.name] != "null") {
						Peca(child).currentFundo = getFundoByName(status.pecas[child.name]);
						Fundo(Peca(child).currentFundo).currentPeca = Peca(child);
						Peca(child).classificacao = status.classificacoes[child.name];
						Peca(child).x = Peca(child).currentFundo.x;
						Peca(child).y = Peca(child).currentFundo.y;
						Peca(child).gotoAndStop(2);
					}
				}
			}
			
			if (completed) finalizaExec(null);
		}
		
		private var pecaDragging:Peca;
		//private var fundoFilter:GlowFilter = new GlowFilter(0xFF0000, 1, 20, 20, 1, 2, true, true);
		private var fundoFilter:GlowFilter = new GlowFilter(0x800000);
		private var fundoWGlow:MovieClip;
		private function verifyForFilter(e:Event):void 
		{
			pecaDragging = Peca(e.target);
			overAlowed = false;
			removeFiltersPecas();
			stage.addEventListener(MouseEvent.MOUSE_MOVE, verifying);
		}
		
		private function verifying(e:MouseEvent):void 
		{
			var fundoUnder:Fundo = getFundo(new Point(pecaDragging.ghost.x, pecaDragging.ghost.y));
			
			if (fundoUnder != null) {
				/*if (fundoUnder.currentPeca != null) {
					if (fundoWGlow == null) {
						fundoWGlow = fundoUnder.currentPeca;
						fundoWGlow.gotoAndStop(2);
					}else {
						if (fundoWGlow is Fundo) {
							fundoWGlow.borda.filters = [];
						}else {
							fundoWGlow.gotoAndStop(1);
						}
						fundoWGlow = fundoUnder.currentPeca;
						fundoWGlow.gotoAndStop(2);
					}
				}else{*/
					if (fundoWGlow == null) {
						fundoWGlow = fundoUnder;
						fundoWGlow.borda.filters = [fundoFilter];
					}else {
						if (fundoWGlow is Fundo) {
							fundoWGlow.borda.filters = [];
						}else {
							fundoWGlow.gotoAndStop(1);
						}
						fundoWGlow = fundoUnder;
						fundoWGlow.borda.filters = [fundoFilter];
					}
				//}
			}else {
				if (fundoWGlow != null) {
					if(fundoWGlow is Fundo){
						Fundo(fundoWGlow).borda.filters = [];
					}else {
						fundoWGlow.gotoAndStop(1);
					}
					fundoWGlow = null;
				}
			}
		}
		
		private function verifyPosition(e:Event):void 
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, verifying);
			pecaDragging = null;
			if (fundoWGlow != null) {
				if (fundoWGlow is Fundo) fundoWGlow.borda.filters = [];
				else fundoWGlow.gotoAndStop(1);
				fundoWGlow = null;
			}
			
			var peca:Peca = e.target as Peca;
			var fundoDrop:Fundo = getFundo(peca.position);
			
			if (fundoDrop != null) {
				if (fundoDrop.currentPeca == null) {
					if (peca.currentFundo != null) {
						Fundo(peca.currentFundo).currentPeca = null;
					}
					fundoDrop.currentPeca = peca;
					peca.currentFundo = fundoDrop;
					//tweenX = new Tween(peca, "x", None.easeNone, peca.x, fundoDrop.x, 0.5, true);
					//tweenY = new Tween(peca, "y", None.easeNone, peca.y, fundoDrop.y, 0.5, true);
					peca.x = fundoDrop.x;
					peca.y = fundoDrop.y;
					peca.gotoAndStop(2);
				}else {
					if(peca.currentFundo != null){
						var pecaFundo:Peca = Peca(fundoDrop.currentPeca);
						var fundoPeca:Fundo = Fundo(peca.currentFundo);
						
						tweenX = new Tween(peca, "x", None.easeNone, peca.x, fundoDrop.x, tweenTime, true);
						tweenY = new Tween(peca, "y", None.easeNone, peca.y, fundoDrop.y, tweenTime, true);
						
						tweenX2 = new Tween(pecaFundo, "x", None.easeNone, pecaFundo.x, fundoPeca.x, tweenTime, true);
						tweenY2 = new Tween(pecaFundo, "y", None.easeNone, pecaFundo.y, fundoPeca.y, tweenTime, true);
						
						peca.currentFundo = fundoDrop;
						fundoDrop.currentPeca = peca;
						
						pecaFundo.currentFundo = fundoPeca;
						fundoPeca.currentPeca = pecaFundo;
					}else {
						pecaFundo = Peca(fundoDrop.currentPeca);
						
						//tweenX = new Tween(peca, "x", None.easeNone, peca.position.x, fundoDrop.x, tweenTime, true);
						//tweenY = new Tween(peca, "y", None.easeNone, peca.position.y, fundoDrop.y, tweenTime, true);
						peca.x = fundoDrop.x;
						peca.y = fundoDrop.y;
						peca.gotoAndStop(2);
						
						tweenX2 = new Tween(pecaFundo, "x", None.easeNone, pecaFundo.x, pecaFundo.inicialPosition.x, tweenTime, true);
						tweenY2 = new Tween(pecaFundo, "y", None.easeNone, pecaFundo.y, pecaFundo.inicialPosition.y, tweenTime, true);
						
						peca.currentFundo = fundoDrop;
						fundoDrop.currentPeca = peca;
						
						pecaFundo.currentFundo = null;
						pecaFundo.gotoAndStop(1);
					}
				}
				verificaFinaliza();
				setTimeout(saveStatus, (tweenTime + 0.1) * 1000);
			}
			overAlowed = true;
		}
		
		private function getFundo(position:Point):Fundo 
		{
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Fundo) {
					if (child.hitTestPoint(position.x, position.y)) return Fundo(child);
				}
			}
			return null;
		}
		
		private function getFundoByName(name:String):Fundo 
		{
			if (name == "") return null;
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Fundo) {
					if (child.name == name) return Fundo(child);
				}
			}
			return null;
		}
		
		private function setAnswerForPeca(child:Peca):void 
		{
			var finalName:String = getQualifiedClassName(child).replace("Peca", "");
			
			child.nome = "peca" + finalName;
			//child.figura = this["fig" + finalName];
			child.fundo = [this["fundo" + finalName]];
			
			if (child is Peca1) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca2) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca3) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca4) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca5) {
				child.ans_classificacao = HAPLOIDE;
			}else if (child is Peca6) {
				child.ans_classificacao = HAPLOIDE;
			}else if (child is Peca7) {
				child.ans_classificacao = HAPLOIDE;
			}else if (child is Peca8) {
				child.ans_classificacao = HAPLOIDE;
			}else if (child is Peca9) {
				child.ans_classificacao = HAPLOIDE;
			}else if (child is Peca10) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca11) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca12) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca13) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca14) {
				child.ans_classificacao = DIPLOIDE;
			}else if (child is Peca15) {
				child.ans_classificacao = DIPLOIDE;
			}
		}
		
		override public function reset(e:MouseEvent = null):void 
		{
			/*
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child is Peca) {
					child.x = Peca(child).inicialPosition.x;
					child.y = Peca(child).inicialPosition.y;
					Peca(child).currentFundo = null;
					Peca(child).gotoAndStop(1);
				}
			}*/
			sortPecas();
			verificaFinaliza();
			saveStatus();
		}
		
		
		//---------------- Tutorial -----------------------
		
		private var balao:CaixaTexto;
		private var pointsTuto:Array;
		private var tutoBaloonPos:Array;
		private var tutoPos:int;
		private var tutoSequence:Array = ["Organize as peças (arraste-as) de acordo com o esquema.", 
										  "Clique para classificar como haploide (n) ou diploide (2n).",
										  "Clique para avaliar sua resposta."];
		
		override public function iniciaTutorial(e:MouseEvent = null):void
		{
			tutoPos = 0;
			if(balao == null){
				balao = new CaixaTexto(true);
				addChild(balao);
				balao.visible = false;
				
				pointsTuto = 	[new Point(327, 318),
								new Point(383 , 278),
								new Point(55 , 612)];
								
				tutoBaloonPos = [[CaixaTexto.TOP, CaixaTexto.CENTER],
								[CaixaTexto.BOTTON, CaixaTexto.CENTER],
								[CaixaTexto.BOTTON, CaixaTexto.FIRST]];
			}
			balao.removeEventListener(Event.CLOSE, closeBalao);
			
			balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
			balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			balao.addEventListener(Event.CLOSE, closeBalao);
			balao.visible = true;
		}
		
		private function closeBalao(e:Event):void 
		{
			tutoPos++;
			if (tutoPos >= tutoSequence.length) {
				balao.removeEventListener(Event.CLOSE, closeBalao);
				balao.visible = false;
			}else {
				balao.setText(tutoSequence[tutoPos], tutoBaloonPos[tutoPos][0], tutoBaloonPos[tutoPos][1]);
				balao.setPosition(pointsTuto[tutoPos].x, pointsTuto[tutoPos].y);
			}
		}
		
		
		/*------------------------------------------------------------------------------------------------*/
		//SCORM:
		
		private const PING_INTERVAL:Number = 5 * 60 * 1000; // 5 minutos
		private var completed:Boolean;
		private var scorm:SCORM;
		private var scormExercise:int;
		private var connected:Boolean;
		private var score:int = 0;
		private var pingTimer:Timer;
		private var mementoSerialized:String = "";
		
		/**
		 * @private
		 * Inicia a conexão com o LMS.
		 */
		private function initLMSConnection () : void
		{
			completed = false;
			connected = false;
			scorm = new SCORM();
			
			pingTimer = new Timer(PING_INTERVAL);
			pingTimer.addEventListener(TimerEvent.TIMER, pingLMS);
			
			connected = scorm.connect();
			
			if (connected) {
				
				if (scorm.get("cmi.mode" != "normal")) return;
				
				scorm.set("cmi.exit", "suspend");
				// Verifica se a AI já foi concluída.
				var status:String = scorm.get("cmi.completion_status");	
				mementoSerialized = scorm.get("cmi.suspend_data");
				var stringScore:String = scorm.get("cmi.score.raw");
				
				switch(status)
				{
					// Primeiro acesso à AI
					case "not attempted":
					case "unknown":
					default:
						completed = false;
						break;
					
					// Continuando a AI...
					case "incomplete":
						completed = false;
						break;
					
					// A AI já foi completada.
					case "completed":
						completed = true;
						//setMessage("ATENÇÃO: esta Atividade Interativa já foi completada. Você pode refazê-la quantas vezes quiser, mas não valerá nota.");
						break;
				}
				
				//unmarshalObjects(mementoSerialized);
				scormExercise = 1;
				score = Number(stringScore.replace(",", "."));
				
				var success:Boolean = scorm.set("cmi.score.min", "0");
				if (success) success = scorm.set("cmi.score.max", "100");
				
				if (success)
				{
					scorm.save();
					pingTimer.start();
				}
				else
				{
					//trace("Falha ao enviar dados para o LMS.");
					connected = false;
				}
			}
			else
			{
				trace("Esta Atividade Interativa não está conectada a um LMS: seu aproveitamento nela NÃO será salvo.");
				mementoSerialized = ExternalInterface.call("getLocalStorageString");
			}
			
			//reset();
		}
		
		/**
		 * @private
		 * Salva cmi.score.raw, cmi.location e cmi.completion_status no LMS
		 */ 
		private function commit()
		{
			if (connected)
			{
				if (scorm.get("cmi.mode" != "normal")) return;
				
				// Salva no LMS a nota do aluno.
				var success:Boolean = scorm.set("cmi.score.raw", score.toString());

				// Notifica o LMS que esta atividade foi concluída.
				success = scorm.set("cmi.completion_status", (completed ? "completed" : "incomplete"));
				
				//success = scorm.set("cmi.exit", (completed ? "normal" : "suspend"));
				
				//Notifica o LMS se o aluno passou ou falhou na atividade, de acordo com a pontuação:
				success = scorm.set("cmi.success_status", (score > 75 ? "passed" : "failed"));

				// Salva no LMS o exercício que deve ser exibido quando a AI for acessada novamente.
				success = scorm.set("cmi.location", scormExercise.toString());
				
				// Salva no LMS a string que representa a situação atual da AI para ser recuperada posteriormente.
				//mementoSerialized = marshalObjects();
				success = scorm.set("cmi.suspend_data", mementoSerialized.toString());

				if(completed){
			  		scorm.set("cmi.exit", "normal");
				} else {
			  		scorm.set("cmi.exit", "suspend");
				}

				if (success)
				{
					scorm.save();
				}
				else
				{
					pingTimer.stop();
					//setMessage("Falha na conexão com o LMS.");
					connected = false;
				}
			}else { //LocalStorage
				ExternalInterface.call("save2LS", mementoSerialized);
			}
		}
		
		/**
		 * @private
		 * Mantém a conexão com LMS ativa, atualizando a variável cmi.session_time
		 */
		private function pingLMS (event:TimerEvent)
		{
			//scorm.get("cmi.completion_status");
			commit();
		}
		
		private function saveStatus(e:Event = null):void
		{
			if (ExternalInterface.available) {
				if (connected) {
					
					if (scorm.get("cmi.mode" != "normal")) return;
					
					saveStatusForRecovery();
					scorm.set("cmi.suspend_data", mementoSerialized);
					commit();
				}else {//LocalStorage
					saveStatusForRecovery();
					ExternalInterface.call("save2LS", mementoSerialized);
				}
			}
		}
		
	}

}