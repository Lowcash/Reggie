//+------------------------------------------------------------------+
//|                                                         Draw.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"

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