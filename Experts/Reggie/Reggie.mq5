//+------------------------------------------------------------------+
//|                                                       Reggie.mq5 |
//|                                          Copyright 2020, Lowcash |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../Include/Internal/MQL4Helper.mqh"
#include "../../Include/Internal/Common.mqh"

#include "Signal/SignalManager.mqh"
#include "Order/OrderManager.mqh"

//+------------------------------------------------------------------+
//|                                                       Properties |
//+------------------------------------------------------------------+

input group             "Base"
input double        LotSize                 = 0.01;
input bool          IsUnlimitedOpenPosition = true;
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

color               PullBackMA_UpClr        = clrForestGreen;
color               PullBackMA_DownClr      = clrCrimson;

//+------------------------------------------------------------------+
//|                                                        Variables |
//+------------------------------------------------------------------+

const int                  _Markers_BufferSize     = 1000;

ObjectBuffer               _MarkersBuffer("Marker", _Markers_BufferSize);

MovingAverageSettings		_FastTrendMASettings(TrendMA_TimeFrame, TrendMA_Method, TrendMA_AppliedTo, TrendMA_Fast, 0);
MovingAverageSettings		_SlowTrendMASettings(TrendMA_TimeFrame, TrendMA_Method, TrendMA_AppliedTo, TrendMA_Slow, 0);
MovingAverageSettings		_FastPullBackMASettings(PullBackMA_TimeFrame, PullBackMA_Method, PullBackMA_AppliedTo, PullBackMA_Fast, 0);
MovingAverageSettings		_MediumPullBackMASettings(PullBackMA_TimeFrame, PullBackMA_Method, PullBackMA_AppliedTo, PullBackMA_Medium, 0);
MovingAverageSettings		_SlowPullBackMASettings(PullBackMA_TimeFrame, PullBackMA_Method, PullBackMA_AppliedTo, PullBackMA_Slow, 0);

const int                  _TrendMA_BufferSize     = 1000;
const int                  _PullBackMA_BufferSize  = 1000;

ObjectBuffer               _PullBackMA_FastBuffer("PullBackMA_Fast", _PullBackMA_BufferSize);

TrendManager               _TrendManager(&_FastTrendMASettings, &_SlowTrendMASettings, "TrendManager", _TrendMA_BufferSize);
PullBackManager				_PullBackManager(&_FastPullBackMASettings, &_MediumPullBackMASettings, &_SlowPullBackMASettings, "PullBackManager", _PullBackMA_BufferSize);

ReggieTradeManager			_ReggieTradeManager(LotSize);

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
   const bool _IsNewWeek = IsNewWeek(_DayOfWeek);
   
   const bool _IsTradeableDay = (_DayOfWeek == MONDAY && TradeOnMonday) ||
                                (_DayOfWeek == TUESDAY && TradeOnTuesday) ||
                                (_DayOfWeek == WEDNESDAY && TradeOnWednesday) ||
                                (_DayOfWeek == THURSDAY && TradeOnThursday) ||
                                (_DayOfWeek == FRIDAY && TradeOnFriday);
   
   const bool _IsTradeableTime = _TimeStruct.hour >= TradeFrom && _TimeStruct.hour < TradeTo;
   
   if(_IsNewBar_Trend) { _TrendManager.UpdateTrendValues(); }
   if(_IsNewBar_PullBack) { _PullBackManager.UpdatePullBackValues(); }
   
   const string _A = _IsTradeableDay ?
         (_IsTradeableTime ? _ReggieTradeManager.GetOrdersStateInfo() : StringFormat("NOT_TRADEABLE - NIGHT TIME\n%s", _ReggieTradeManager.GetOrdersStateInfo())) :
         (StringFormat("NOT_TRADEABLE - %s\n%s", EnumToString(_DayOfWeek), _ReggieTradeManager.GetOrdersStateInfo()));
   
   Comment(
      StringFormat("%s\nWeek profit: %.2lf%%", _A, NormalizeDouble(AccountInfoDouble(ACCOUNT_EQUITY), 2))
   );
   
   if(_IsNewBar_Trend) {
   	const Trend::State _TrendState = _TrendManager.AnalyzeTrend(TrendMA_MinCandles);
   	
      if(_TrendManager.GetCurrState() == Trend::State::VALID_UPTREND) {
         _MarkersBuffer.GetNewObjectId();
      }
      if(_TrendManager.GetCurrState() == Trend::State::VALID_DOWNTREND) {
         _MarkersBuffer.GetNewObjectId();   
      }
   }
   
   if(_Period == TrendMA_TimeFrame) {
   	Trend* _SelectedTrend = _TrendManager.GetSelectedTrend();

      if(_TrendManager.GetCurrState() == Trend::State::VALID_UPTREND) {
         DrawTrendMarker(_MarkersBuffer.GetSelecterObjectId(), iTimeMQL4(_Symbol, TrendMA_TimeFrame, 0), Low[0], true, TrendMA_UpClr);
         DrawTrendMarker(_SelectedTrend.GetSignalID(), _SelectedTrend.GetBeginDateTime(), _SelectedTrend.GetHighestValue(), _SelectedTrend.GetEndDateTime(), _SelectedTrend.GetLowestValue(), TrendMA_UpClr);
      }
      if(_TrendManager.GetCurrState() == Trend::State::VALID_DOWNTREND) {
         DrawTrendMarker(_MarkersBuffer.GetSelecterObjectId(), iTimeMQL4(_Symbol, TrendMA_TimeFrame, 0), Low[0], false, TrendMA_DownClr);
         DrawTrendMarker(_SelectedTrend.GetSignalID(), _SelectedTrend.GetBeginDateTime(), _SelectedTrend.GetLowestValue(), _SelectedTrend.GetEndDateTime(), _SelectedTrend.GetHighestValue(), TrendMA_DownClr);
      }
   }
   
   // You can only analyze pullbacks if there is a trend 
   if(_TrendManager.GetCurrState() != Trend::State::INVALID_TREND) {
   	_ReggieTradeManager.AnalyzeTrades(_PullBackManager.GetCurrMASlow());
   		
   	if(_IsNewBar_PullBack) {
   	   if(_IsTradeableDay && _IsTradeableTime) {
   	      if(IsUnlimitedOpenPosition || (!IsUnlimitedOpenPosition && PositionsTotal() == 0 && OrdersTotal() == 0) ) {
   			   const PullBack::State _PullBackState = _PullBackManager.AnalyzePullBack(_TrendManager.GetCurrState());
   			
   				if(_PullBackState == PullBack::State::VALID_UPPULLBACK) {
   				   _ReggieTradeManager.TryOpenOrder(ReggieTrade::TradeType::BUY, _FastPullBackMASettings.m_TimeFrame);
   				}
   				if(_PullBackState == PullBack::State::VALID_DOWNPULLBACK) {
   				   _ReggieTradeManager.TryOpenOrder(ReggieTrade::TradeType::SELL, _FastPullBackMASettings.m_TimeFrame);
   				}
   			}
   	   }
      }
   }
   
   if(_Period == PullBackMA_TimeFrame && _TrendManager.GetCurrState() != Trend::State::INVALID_TREND) {
      if(_IsNewBar_PullBack) {
	      _PullBackMA_FastBuffer.GetNewObjectId();
	   }
      
      const double _MA_PrevFast = iMAMQL4(_Symbol, PullBackMA_TimeFrame, PullBackMA_Fast, 0, PullBackMA_Method, PullBackMA_AppliedTo, 1);
      const double _MA_CurrFast = iMAMQL4(_Symbol, PullBackMA_TimeFrame, PullBackMA_Fast, 0, PullBackMA_Method, PullBackMA_AppliedTo, 0);

		// In case MA is rendering incorrectly, try change Model to "Every tick..."
		
      DrawMovingAverage(_PullBackMA_FastBuffer.GetSelecterObjectId(), 0, _MA_PrevFast, _MA_CurrFast, _TrendManager.GetCurrState() == Trend::State::VALID_UPTREND ? PullBackMA_UpClr : PullBackMA_DownClr);
	}
}

//+------------------------------------------------------------------+

void DrawTrendMarker(const string p_ID, const datetime p_DateTime, const double p_Value, const bool p_IsMarkerUpDirection, color p_Color) {
   const long SChartId = ChartID();

   if(ObjectFind(SChartId, p_ID) != -1) 
      ObjectDelete(SChartId, p_ID);
   
   if(ObjectCreate(SChartId, p_ID, OBJ_ARROW, 0, p_DateTime, p_Value)) {
      ObjectSetInteger(SChartId, p_ID, OBJPROP_ARROWCODE, p_IsMarkerUpDirection ? 233 : 234);
      ObjectSetInteger(SChartId, p_ID, OBJPROP_COLOR, p_Color);
      ObjectSetInteger(SChartId, p_ID, OBJPROP_WIDTH, 1);
   } else 
      Print("Marker was not created - something went wrong!!");
}

void DrawTrendMarker(const string p_ID, const datetime p_BeginDateTime, const double p_BeginValue, const datetime p_EndDateTime, const double p_EndValue, const color p_Color) {
   const long SChartId = ChartID();

   if(ObjectFind(SChartId, p_ID) != -1) 
      ObjectDelete(SChartId, p_ID);

   if(ObjectCreate(SChartId, p_ID, OBJ_RECTANGLE, 0, p_BeginDateTime, p_BeginValue, p_EndDateTime, p_EndValue)) {
      ObjectSetInteger(SChartId, p_ID, OBJPROP_COLOR, p_Color);
      ObjectSetInteger(SChartId, p_ID, OBJPROP_BACK, false);
      ObjectSetInteger(SChartId, p_ID, OBJPROP_WIDTH, 2);
   } else 
      Print("Marker was not created - something went wrong!!");
}

void DrawMovingAverage(const string p_MAID, const int p_MAOffset, const double p_MAPrevValue, const double p_MACurrValue, const color p_MAColor) {
   const long SChartId = ChartID();

   if(ObjectFind(SChartId, p_MAID) != -1) 
      ObjectDelete(SChartId, p_MAID);

   if(ObjectCreate(SChartId, p_MAID, OBJ_TREND, 0, Time[p_MAOffset + 0], p_MACurrValue, Time[p_MAOffset + 1], p_MAPrevValue)) {
      ObjectSetInteger(SChartId, p_MAID, OBJPROP_COLOR, p_MAColor);
      ObjectSetInteger(SChartId, p_MAID, OBJPROP_WIDTH, 3);
      ObjectSetInteger(SChartId, p_MAID, OBJPROP_RAY, false);
   } else 
      Print("MA was not created - something went wrong!!");
}
//+------------------------------------------------------------------+