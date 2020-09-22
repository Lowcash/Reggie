//+------------------------------------------------------------------+
//|                                                       Signal.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

//+------------------------------------------------------------------+
struct MovingAverageSettings {
 public:
	const ENUM_TIMEFRAMES m_TimeFrame;
	const ENUM_MA_METHOD m_Method;
	const ENUM_APPLIED_PRICE m_AppliedTo;
	const int m_Period, m_Shift;
	
	MovingAverageSettings(const ENUM_TIMEFRAMES p_TimeFrame, const ENUM_MA_METHOD p_Method, const ENUM_APPLIED_PRICE p_AppliedTo, const int p_Period, const int p_Shift)
		: m_TimeFrame(p_TimeFrame), m_Method(p_Method), m_AppliedTo(p_AppliedTo), m_Period(p_Period), m_Shift(p_Shift){}
};

//+------------------------------------------------------------------+

class Signal {
 private:
   string m_SignalID;

   datetime m_BeginDateTime, m_EndDateTime;
   double m_BeginValue, m_EndValue;
   double m_LowestValue, m_HighestValue;
   
   void SetValues(const datetime p_InTime, const double p_InValue, datetime &p_RefTime, double &p_RefValue) {
   	m_LowestValue = MathMin(m_LowestValue, p_InValue);
   	m_HighestValue = MathMax(m_HighestValue, p_InValue);
   
   	p_RefTime = p_InTime;
   	p_RefValue = p_InValue;
   }
 public:
   Signal(const string p_SignalID, const datetime p_Time, const double p_Value)
      : m_SignalID(p_SignalID), m_LowestValue(DBL_MAX), m_HighestValue(DBL_MIN) {
      SetBegin(p_Time, p_Value);
      SetEnd(p_Time, p_Value);
   }

   void SetBegin(const datetime p_Time, const double p_Value) {
   	SetValues(p_Time, p_Value, m_BeginDateTime, m_BeginValue);
   }

   void SetEnd(const datetime p_Time, const double p_Value) {
      SetValues(p_Time, p_Value, m_EndDateTime, m_EndValue);
   }

   string GetSignalID() const { return(m_SignalID); }

   datetime GetBeginDateTime() const { return(m_BeginDateTime); }
   datetime GetEndDateTime() const { return(m_EndDateTime); }

   double GetBeginValue() const { return(m_BeginValue); }
   double GetEndValue() const { return(m_EndValue); }
   
   double GetLowestValue() const { return(m_LowestValue); }
   double GetHighestValue() const { return(m_HighestValue); }
};

//+------------------------------------------------------------------+

class Trend : public Signal {
 public:
	enum State { INVALID_TREND = -1, VALID_UPTREND = 1, VALID_DOWNTREND = 2 };
 private: 
 	const State m_State;
 public:
 	Trend(const string p_TrendID, const State p_State, const datetime p_Time, const double p_Value) 
 		: Signal(p_TrendID, p_Time, p_Value), m_State(p_State) {}
 
 	State GetState() const { return(m_State); }
};

class PullBack : public Signal {
 public:
 	enum State { INVALID_PULLBACK = -1, VALID_UPPULLBACK = 1, VALID_DOWNPULLBACK = 2 };
 private:
 	const State m_State;
 public:
	PullBack(const string p_PullbackID, const datetime p_Time, const double p_Value) 
 		: Signal(p_PullbackID, p_Time, p_Value) {}
 		
 	State GetState() const { return(m_State); }
};
