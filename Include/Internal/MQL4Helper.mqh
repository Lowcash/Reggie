//+------------------------------------------------------------------+
//|                                                       Helper.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"

static datetime Time[];
static double Close[];

static datetime _Time;
static double Ask, Bid;

void UpdatePredefinedVars() {
   ArraySetAsSeries(Time, true);
   ArraySetAsSeries(Close, true);
   
   CopyTime(_Symbol, _Period, 0, 100, Time);
   CopyClose(_Symbol, _Period, 0, 100, Close);
   
   MqlTick _LastTick;
   SymbolInfoTick(_Symbol, _LastTick);
   _Time = _LastTick.time;
   Ask = _LastTick.ask;
   Bid = _LastTick.bid;
}