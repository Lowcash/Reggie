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

//+------------------------------------------------------------------+
//|                                                       Properties |
//+------------------------------------------------------------------+

ENUM_TIMEFRAMES     TrendMA_TimeFrame       = PERIOD_H1;
ENUM_MA_METHOD      TrendMA_Method          = MODE_EMA;
ENUM_APPLIED_PRICE  TrendMA_AppliedTo       = PRICE_CLOSE;
int                 TrendMA_Slow            = 21;
int                 TrendMA_Fast            = 8;
color               TrendMA_SlowColor       = clrGold;
color               TrendMA_FastColor       = clrMediumSeaGreen;
int                 TrendMA_MinCandles      = 1;

color               TrendMA_UpClr           = clrForestGreen;
color               TrendMA_DownClr         = clrCrimson;

ENUM_TIMEFRAMES     PullBackMA_TimeFrame    = PERIOD_M5;
ENUM_MA_METHOD      PullBackMA_Method       = MODE_EMA;
ENUM_APPLIED_PRICE  PullBackMA_AppliedTo    = PRICE_CLOSE;
int                 PullBackMA_Slow         = 21;
int                 PullBackMA_Medium       = 13;
int                 PullBackMA_Fast         = 8;
color               PullBackMA_SlowColor    = clrGold;
color               PullBackMA_MediumColor  = clrCornflowerBlue;
color               PullBackMA_FastColor    = clrMediumSeaGreen;
extern int                 PullBackMA_MinCandles   = 5;

color               PullBackMA_UpClr        = clrForestGreen;
color               PullBackMA_DownClr      = clrCrimson;

extern double              LotSize                 = 0.01;

const int                  _Markers_BufferSize     = 1000;
const int                  _TrendMA_BufferSize     = 1000;
const int                  _PullBackMA_BufferSize  = 1000;

int OnInit() {
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   
}

void OnTick() {
   UpdatePredefinedVars();
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