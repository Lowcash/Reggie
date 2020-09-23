//+------------------------------------------------------------------+
//|                                                       Helper.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"

static datetime Time[];
static double Close[], Low[];

static datetime _Time;
static double Ask, Bid;

void UpdatePredefinedVars() {
   ArraySetAsSeries(Time, true);
   ArraySetAsSeries(Close, true);
   ArraySetAsSeries(Low, true);
   
   CopyTime(_Symbol, _Period, 0, 100, Time);
   CopyClose(_Symbol, _Period, 0, 100, Close);
   CopyLow(_Symbol, _Period, 0, 100, Low);
   
   MqlTick _LastTick;
   SymbolInfoTick(_Symbol, _LastTick);
   _Time = _LastTick.time;
   Ask = _LastTick.ask;
   Bid = _LastTick.bid;
}

datetime iTimeMQL4(const string p_Symbol, const ENUM_TIMEFRAMES p_TimeFrame, const int p_Shift) {
   if(p_Shift < 0) return(-1);
   
   datetime Arr[];
   if(CopyTime(p_Symbol, p_TimeFrame, p_Shift, 1, Arr) > 0) { 
      return(Arr[0]); 
   }
   
   return(-1);
}

double CopyBufferMQL4(const int p_Handle, const int p_Index, const int p_Shift) {
   double _Buffer[];
   
   switch(p_Index) {
      case 0: if(CopyBuffer(p_Handle, 0, p_Shift, 1, _Buffer) > 0) { return(_Buffer[0]); }
      case 1: if(CopyBuffer(p_Handle, 1, p_Shift, 1, _Buffer) > 0) { return(_Buffer[0]); }
      case 2: if(CopyBuffer(p_Handle, 2, p_Shift, 1, _Buffer) > 0) { return(_Buffer[0]); }
      case 3: if(CopyBuffer(p_Handle, 3, p_Shift, 1, _Buffer) > 0) { return(_Buffer[0]); }
      case 4: if(CopyBuffer(p_Handle, 4, p_Shift, 1, _Buffer) > 0) { return(_Buffer[0]); }
      
      default: break;
   }
   
   return(EMPTY_VALUE);
}

double iMAMQL4(const string p_Symbol, const ENUM_TIMEFRAMES p_TimeFrame, const int p_Period, const int p_MA_Shift, const ENUM_MA_METHOD p_Method, const ENUM_APPLIED_PRICE p_AppliedTo, const int p_Shift) {
   const int _Handle = iMA(p_Symbol, p_TimeFrame, p_Period, p_MA_Shift, p_Method, p_AppliedTo);
   
   if(_Handle < 0) {
      Print("The iMA object is not created: Error",GetLastError());
      return(-1);
   }
   
   return(CopyBufferMQL4(_Handle, 0, p_Shift));
}