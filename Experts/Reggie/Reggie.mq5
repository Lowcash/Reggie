//+------------------------------------------------------------------+
//|                                                       Reggie.mq5 |
//|                                          Copyright 2020, Lowcash |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Core/Include/MQL4Helper.mqh"
#include "../../Core/Include/Common.mqh"
#include "../../Core/Include/Draw.mqh"

#include "../../Core/Signal/_Indicators/MovingAverage.mqh"

#include "../../Core/Signal/Trend/TrendManager.mqh"
#include "../../Core/Signal/PullBack/PullBackManager.mqh"

#include "Order/OrderManager.mqh"
#include "Account/AccountManager.mqh"

//+------------------------------------------------------------------+
//|                                                       Properties |
//+------------------------------------------------------------------+

input group          "Positions"
input bool          UseUnlimitedOpenPosition = true;

input group             "Lot adjuster"
input bool          UseLotAdjuster           = true;
input double        LotSize                 = 0.25;
input double        LotSizeToEquity         = 1000;

input double        EquityMaxLoss           = -5.00;
input double        EquityMaxProfit         = 10.00; 

input group              "Trade time"
input int           TradeFrom               = 7;
input int           TradeTo                 = 20;
input bool          TradeOnMonday           = true; 
input bool          TradeOnTuesday          = true; 
input bool          TradeOnWednesday        = true; 
input bool          TradeOnThursday         = true; 
input bool          TradeOnFriday           = true;

input group             "Trend"
input ENUM_TIMEFRAMES     TrendMA_TimeFrame       = PERIOD_H1;
input ENUM_MA_METHOD      TrendMA_Method          = MODE_EMA;
input ENUM_APPLIED_PRICE  TrendMA_AppliedTo       = PRICE_CLOSE;
input int                 TrendMA_Slow            = 21;
input int                 TrendMA_Fast            = 8;
color               TrendMA_SlowColor       = clrGold;
color               TrendMA_FastColor       = clrMediumSeaGreen;
int                 TrendMA_MinCandles      = 1;

color               TrendMA_UpClr           = clrForestGreen;
color               TrendMA_DownClr         = clrCrimson;

input group             "PullBack"
input ENUM_TIMEFRAMES     PullBackMA_TimeFrame    = PERIOD_M5;
input ENUM_MA_METHOD      PullBackMA_Method       = MODE_EMA;
input ENUM_APPLIED_PRICE  PullBackMA_AppliedTo    = PRICE_CLOSE;
input int                 PullBackMA_Slow         = 21;
input int                 PullBackMA_Medium       = 13;
input int                 PullBackMA_Fast         = 8;
color               PullBackMA_SlowColor    = clrGold;
color               PullBackMA_MediumColor  = clrCornflowerBlue;
color               PullBackMA_FastColor    = clrMediumSeaGreen;

input double        PullBack_MinPips        = 0.5;
input double        PullBack_PipsTriggerTolerance= 0.1;

color               PullBackMA_UpClr        = clrForestGreen;
color               PullBackMA_DownClr      = clrCrimson;

//+------------------------------------------------------------------+
//|                                                        Variables |
//+------------------------------------------------------------------+

const int                  _Markers_BufferSize     = 999999;

ObjectBuffer               _MarkersBuffer("Marker", _Markers_BufferSize);

MovingAverageSettings		_FastTrendMASettings(_Symbol, TrendMA_TimeFrame, TrendMA_Method, TrendMA_AppliedTo, TrendMA_Fast, 0);
MovingAverageSettings		_SlowTrendMASettings(_Symbol, TrendMA_TimeFrame, TrendMA_Method, TrendMA_AppliedTo, TrendMA_Slow, 0);
MovingAverageSettings		_FastPullBackMASettings(_Symbol, PullBackMA_TimeFrame, PullBackMA_Method, PullBackMA_AppliedTo, PullBackMA_Fast, 0);
MovingAverageSettings		_MediPullBackMASettings(_Symbol, PullBackMA_TimeFrame, PullBackMA_Method, PullBackMA_AppliedTo, PullBackMA_Medium, 0);
MovingAverageSettings		_SlowPullBackMASettings(_Symbol, PullBackMA_TimeFrame, PullBackMA_Method, PullBackMA_AppliedTo, PullBackMA_Slow, 0);

const int                  _TrendMA_BufferSize     = 9999;
const int                  _PullBackMA_BufferSize  = 9999;

ObjectBuffer               _PullBackMA_FastBuffer("PullBackMA_Fast", _PullBackMA_BufferSize);

TrendManager               _TrendManager(_TrendMA_BufferSize);
PullBackManager				_PullBackManager(_PullBackMA_BufferSize);

ReggieTradeManager			_ReggieTradeManager(LotSize);

AccountManager             _AccountManager();

int OnInit() {
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {}

void OnTradeTransaction(const MqlTradeTransaction &p_Trans, const MqlTradeRequest &p_Request, const MqlTradeResult &p_Result) {
   //PrintFormat("Orders: %d, Positions: %d", OrdersTotal(), PositionsTotal());
   
   if(HistoryDealSelect(p_Trans.deal)) {
      ulong _PositionID;
      
      if(HistoryDealGetInteger(p_Trans.deal, DEAL_POSITION_ID, _PositionID)) {
         //PrintFormat("Order: %lu; Position: %lu", p_Trans.order, _PositionID);
         
         switch(p_Trans.type) {
            case TRADE_TRANSACTION_DEAL_ADD: {
               _ReggieTradeManager.HandleMakeDeal(_PositionID);
            
               break;
            }
         }
      } else {
         Print("Cannot transform deal ID to ticket ID!");
      }
   } else {
      switch(p_Trans.type) {
         case TRADE_TRANSACTION_ORDER_ADD: {
            _ReggieTradeManager.HandleOrderSend(p_Trans.order);
   
            break;
         }
         case TRADE_TRANSACTION_ORDER_DELETE: {
            if(p_Trans.order_state == ORDER_STATE_CANCELED) {
               _ReggieTradeManager.HandleOrderDelete(p_Trans.order);
            }
            
            break;
         }
      }
   }
}

void OnTick() {
   UpdatePredefinedVars();
   
   const bool _IsNewBar_Trend = IsNewBar(TrendMA_TimeFrame);
   const bool _IsNewBar_PullBack = IsNewBar(PullBackMA_TimeFrame);
   const bool _IsNewWeek = IsNewWeek(_DayOfWeek, MONDAY);
   
   const bool _IsTradeableDay = (_DayOfWeek == MONDAY && TradeOnMonday) ||
                                (_DayOfWeek == TUESDAY && TradeOnTuesday) ||
                                (_DayOfWeek == WEDNESDAY && TradeOnWednesday) ||
                                (_DayOfWeek == THURSDAY && TradeOnThursday) ||
                                (_DayOfWeek == FRIDAY && TradeOnFriday);
   
   const bool _IsTradeableTime = IsValueInRange(_TimeStruct.hour, TradeFrom - 1, TradeTo);
   
   const bool _IsEquityOK = IsValueInRange(_AccountManager.GetAccountEquityPercentage(), EquityMaxLoss, EquityMaxProfit);
   
   //if(_IsNewBar_Trend) { _TrendManager.UpdateTrendValues(); }
   //if(_IsNewBar_PullBack) { _PullBackManager.UpdatePullBackValues(); }
   if(_IsNewWeek) { _AccountManager.UpdateAccountValues(); }
   
   if(UseLotAdjuster) {
      _ReggieTradeManager.UpdateLotSize(_AccountManager.GetAdjustedLotSize(LotSizeToEquity, LotSize));
   }
   
   // Reanalyze all trades before trend/pullback analysis
   double _CurrIMASlow; SetMovingAverage(&_SlowPullBackMASettings, 1, _CurrIMASlow);
   _ReggieTradeManager.AnalyzeTrades(_CurrIMASlow);
   
   // Trend analysis
   if(_IsNewBar_Trend) {
   	const Trend::State _TrendState = _TrendManager.AnalyzeByIMAOutCandles(_FastTrendMASettings, _SlowTrendMASettings, TrendMA_MinCandles);
   	
      if(_TrendManager.GetCurrentState() == Trend::State::VALID_UPTREND) {
         _MarkersBuffer.GetNewObjectId();
      }
      if(_TrendManager.GetCurrentState() == Trend::State::VALID_DOWNTREND) {
         _MarkersBuffer.GetNewObjectId();   
      }
   }

   // PullBack analysis
	if(_IsNewBar_PullBack && _TrendManager.GetCurrentState() != Trend::State::INVALID_TREND) {
	   if(_IsTradeableDay && _IsTradeableTime && _IsEquityOK) {
	      if(UseUnlimitedOpenPosition || (!UseUnlimitedOpenPosition && PositionsTotal() == 0 && OrdersTotal() == 0) ) {
			   const PullBack::State _PullBackState = _PullBackManager.AnalyzeInclTrend(_TrendManager.GetCurrentState(), _FastPullBackMASettings, _MediPullBackMASettings, _SlowPullBackMASettings, GetForexPipValue(), PullBack_PipsTriggerTolerance, PullBack_MinPips);
			
				if(_PullBackState == PullBack::State::VALID_UPPULLBACK) {
				   _ReggieTradeManager.TryOpenOrder(ReggieTrade::TradeType::BUY, _FastPullBackMASettings.m_TimeFrame);
				}
				if(_PullBackState == PullBack::State::VALID_DOWNPULLBACK) {
				   _ReggieTradeManager.TryOpenOrder(ReggieTrade::TradeType::SELL, _FastPullBackMASettings.m_TimeFrame);
				}
			}
	   }
   }

   // Update balance and info
   _AccountManager.UpdateAccountBalance();
   
   if(_AccountManager.GetAccountEquityPercentage() > EquityMaxProfit) { 
      _ReggieTradeManager.ForceCloseTrades(); 
   }
   
   SetInfoComment(_IsTradeableDay, _DayOfWeek, _IsTradeableTime, _ReggieTradeManager.GetOrdersStateInfo(), _AccountManager.GetAccountInfo(_ReggieTradeManager.GetLotSize()));
   //+------------------------------------------------------------------+
   
   // Draw objects into the chart
   if(_Period == TrendMA_TimeFrame) {
   	Trend* _SelectedTrend = _TrendManager.GetSelectedTrend();

      if(_TrendManager.GetCurrentState() == Trend::State::VALID_UPTREND) {
         DrawTrendMarker(_MarkersBuffer.GetSelecterObjectId(), iTimeMQL4(_Symbol, TrendMA_TimeFrame, 0), Low[0], true, TrendMA_UpClr);
         DrawTrendMarker(_SelectedTrend.GetSignalID(), _SelectedTrend.GetBeginDateTime(), _SelectedTrend.GetHighestValue(), _SelectedTrend.GetEndDateTime(), _SelectedTrend.GetLowestValue(), TrendMA_UpClr);
      }
      if(_TrendManager.GetCurrentState() == Trend::State::VALID_DOWNTREND) {
         DrawTrendMarker(_MarkersBuffer.GetSelecterObjectId(), iTimeMQL4(_Symbol, TrendMA_TimeFrame, 0), Low[0], false, TrendMA_DownClr);
         DrawTrendMarker(_SelectedTrend.GetSignalID(), _SelectedTrend.GetBeginDateTime(), _SelectedTrend.GetLowestValue(), _SelectedTrend.GetEndDateTime(), _SelectedTrend.GetHighestValue(), TrendMA_DownClr);
      }
   }
   
   if(_Period == PullBackMA_TimeFrame && _TrendManager.GetCurrentState() != Trend::State::INVALID_TREND) {
      if(_IsNewBar_PullBack) {
	      _PullBackMA_FastBuffer.GetNewObjectId();
	   }
      
      const double _MA_PrevFast = iMAMQL4(_Symbol, PullBackMA_TimeFrame, PullBackMA_Fast, 0, PullBackMA_Method, PullBackMA_AppliedTo, 1);
      const double _MA_CurrFast = iMAMQL4(_Symbol, PullBackMA_TimeFrame, PullBackMA_Fast, 0, PullBackMA_Method, PullBackMA_AppliedTo, 0);

		// In case MA is rendering incorrectly, try change Model to "Every tick..."
		
      DrawMovingAverage(_PullBackMA_FastBuffer.GetSelecterObjectId(), 1, _MA_PrevFast, _MA_CurrFast, _TrendManager.GetCurrentState() == Trend::State::VALID_UPTREND ? PullBackMA_UpClr : PullBackMA_DownClr);
	}
	//+------------------------------------------------------------------+
}

void SetInfoComment(const bool p_IsTradeableDay, const ENUM_DAY_OF_WEEK p_DayOfWeek, const bool p_IsTradeableTime, const string p_OrdersInfo, const string p_AccountInfo) {
   string _Info = "";
   
   if(p_IsTradeableDay) { 
      if(!p_IsTradeableTime) {
         StringAdd(_Info, "NOT_TRADEABLE - NIGHT TIME\n");
      }
   } else {
      StringAdd(_Info, StringFormat("NOT_TRADEABLE - %s\n", EnumToString(p_DayOfWeek)));
   }
   
   StringAdd(_Info, StringFormat("%s\n", p_OrdersInfo));
   StringAdd(_Info, StringFormat("%s\n", p_AccountInfo));
   
   Comment(_Info);
}