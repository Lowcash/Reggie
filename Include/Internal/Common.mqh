//+------------------------------------------------------------------+
//|                                                       Common.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"

#include "MQL4Helper.mqh"
#include <Generic/Hashmap.mqh>

#define ForEachCObject(node, list) for(CObject* node = list.GetFirstNode(); node != NULL; node = list.GetNextNode())

struct ObjectBuffer {
 private:
   const string m_ObjectId;

   const int m_MaxObjects;
   int m_ObjectPointer;
 public:
	ObjectBuffer(const string ObjectId, const int MaxObjects = 10) 
		: m_ObjectId(ObjectId), m_MaxObjects(MaxObjects), m_ObjectPointer(0) {}

   string GetSelecterObjectId() {
      return StringFormat("%s_%d", m_ObjectId, m_ObjectPointer);
   }
   
   string GetNewObjectId() {
      m_ObjectPointer = m_ObjectPointer >= m_MaxObjects - 1 ? 0 : m_ObjectPointer + 1;
		
      return GetSelecterObjectId();
   }
};

static CHashMap<ENUM_TIMEFRAMES, datetime> Times;
static ENUM_DAY_OF_WEEK DayOfWeek;

double GetForexPipValue() {
   return(_Digits % 2 == 1 ? (_Point * 10) : _Point);
}

double GetNumPipsBetweenPrices(const double p_FirstPrice, const double p_SecondPrice, const double p_PipValue) {
   return(
      NormalizeDouble(MathAbs(
         (int)((p_FirstPrice / (p_PipValue) * 100)) - (int)((p_SecondPrice / (p_PipValue) * 100))
      ) / 100.0, 2)
   );
}

bool IsBullCandle(const int p_BarIdx) {
   return(Open[p_BarIdx] < Close[p_BarIdx]);
}

bool IsBearCandle(const int p_BarIdx) {
   return(Open[p_BarIdx] > Close[p_BarIdx]);
}

bool IsValueInRange(const double p_Value, const double p_Begin, const double p_End) {
   const double _LowerValue = MathMin(p_Begin, p_End);
   const double _HigherValue = MathMax(p_Begin, p_End);
   
   return(p_Value > _LowerValue && p_Value < _HigherValue);
}

bool IsNewDay(const ENUM_DAY_OF_WEEK p_DayOfWeek) {
   if(DayOfWeek != p_DayOfWeek) {
      DayOfWeek = p_DayOfWeek;
      
      return(true);
   }
   
   return(false);
}

bool IsNewWeek(const ENUM_DAY_OF_WEEK p_ActualDayOfWeek, const ENUM_DAY_OF_WEEK p_FirstDayOfWeek) {
   return(IsNewDay(p_ActualDayOfWeek) && p_ActualDayOfWeek == p_FirstDayOfWeek);
}

bool IsNewBar(const ENUM_TIMEFRAMES p_TimeFrame) {
   datetime _PrevTime = NULL, _CurrTime = iTimeMQL4(_Symbol, p_TimeFrame, 0);

   if(!Times.TryGetValue(p_TimeFrame, _PrevTime)) {
      Times.Add(p_TimeFrame, _CurrTime);
   }
   
   if(!Times.TrySetValue(p_TimeFrame, _CurrTime)) {
      Print("Cannot set new bar value!");
   }
   
   return(_PrevTime != _CurrTime);
}