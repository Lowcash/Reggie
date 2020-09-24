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

double GetForexPipValue() {
   return(_Digits % 2 == 1 ? (_Point * 10) : _Point);
}

int GetNumPipsBetweenPrices(const double p_FirstPrice, const double p_SecondPrice, const double p_PipValue) {
   return(
      MathAbs(
         (int)(p_FirstPrice / p_PipValue) - (int)(p_SecondPrice / p_PipValue)
      )
   );
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