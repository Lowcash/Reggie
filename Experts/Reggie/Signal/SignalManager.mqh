//+------------------------------------------------------------------+
//|                                                SignalManager.mqh |
//|                                         Copyright 2020, Lowcash. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Lowcash."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "../../../Include/Internal/MQL4Helper.mqh"
#include "../../../Include/Internal/Common.mqh"

#include "Signal.mqh"

//+------------------------------------------------------------------+

class SignalManager {
 private:
   const string m_ManagerID;

   const int m_MaxSignals;

   int m_SignalPointer;
 protected:
   void SelectNextSignal();
   
   string GetManagerId() const { return(m_ManagerID); }
   
   int GetSignalPointer() const { return(m_SignalPointer); }
   int GetMaxSignals() const { return(m_MaxSignals); }
 public:
 	SignalManager(const string p_ManagerID = "SignalManager", const int m_MaxSignals = 10);  
};

SignalManager::SignalManager(const string p_ManagerID, const int p_MaxSignals)
   : m_ManagerID(p_ManagerID), m_MaxSignals(p_MaxSignals), m_SignalPointer(0) {}

void SignalManager::SelectNextSignal(void) {
   m_SignalPointer = m_SignalPointer >= m_MaxSignals - 1 ? 0 : m_SignalPointer + 1;
}

//+------------------------------------------------------------------+

class TrendManager : public SignalManager {
 private:
 	double m_CurrMAFast, m_CurrMASlow;
 
 	Trend::State m_CurrState;
 	
   Trend m_Trends[];
   
   void UpdateTrendInfo(const bool p_IsNewTrend, const datetime p_Time, const double p_Value);
    
   Trend::State GetState(const int p_MinCandles, const MovingAverageSettings &p_FastMASettings, const MovingAverageSettings &p_SlowMASettings);
 public:
   TrendManager(const string p_ManagerID = "TrendManager", const int p_MaxTrends = 10);
	
	void AnalyzeTrend(const int p_MinCandles, const MovingAverageSettings &p_FastMASettings, const MovingAverageSettings &p_SlowMASettings);
	
	Trend::State GetCurrState() const { return(m_CurrState); }
	
   Trend* GetSelectedTrend() { return(&m_Trends[GetSignalPointer()]); }
};

TrendManager::TrendManager(const string p_ManagerID, const int p_MaxTrends)
   : SignalManager(p_ManagerID, p_MaxTrends), m_CurrState(Trend::State::INVALID_TREND) {
   if(ArrayResize(m_Trends, p_MaxTrends) != -1)
      PrintFormat("Trend array initialized succesfully with size %d", GetMaxSignals());
   else
      Print("Trend array initialization failed with error %", GetLastError());
};

Trend::State TrendManager::GetState(const int p_MinCandles, const MovingAverageSettings &p_FastMASettings, const MovingAverageSettings &p_SlowMASettings) {
   switch(m_CurrState) {
   case Trend::State::VALID_UPTREND:
      if(Bid > m_CurrMASlow) { return(Trend::State::VALID_UPTREND); }

      break;
   case Trend::State::VALID_DOWNTREND:
      if(Bid < m_CurrMASlow) { return(Trend::State::VALID_DOWNTREND); }

      break;
   case Trend::State::INVALID_TREND: {
	      bool _IsUpTrend = true, _IsDownTrend = true;
	      double _MA_CurrFast = 0, _MA_CurrSlow = 0;
	      
	      for(int i = 1; i <= p_MinCandles && _IsUpTrend && _IsDownTrend; ++i) {
	         _MA_CurrFast = iMAMQL4(_Symbol, p_FastMASettings.m_TimeFrame, p_FastMASettings.m_Period, 0, p_FastMASettings.m_Method, p_FastMASettings.m_AppliedTo, i);
	         _MA_CurrSlow = iMAMQL4(_Symbol, p_SlowMASettings.m_TimeFrame, p_SlowMASettings.m_Period, 0, p_SlowMASettings.m_Method, p_SlowMASettings.m_AppliedTo, i);

	         if(!(Close[i] > _MA_CurrFast && _MA_CurrFast > _MA_CurrSlow)) { _IsUpTrend = false; }
	         if(!(Close[i] < _MA_CurrFast && _MA_CurrFast < _MA_CurrSlow)) { _IsDownTrend = false; }   
	      }
	
	      if(_IsUpTrend) { return(Trend::State::VALID_UPTREND); }
	      if(_IsDownTrend) { return(Trend::State::VALID_DOWNTREND); }
	
	      break;
	   }
   }

   return(Trend::State::INVALID_TREND);
}

void TrendManager::UpdateTrendInfo(const bool p_IsNewTrend, const datetime p_Time, const double p_Value) {
	const int _SignalPointer = GetSignalPointer();

   if(p_IsNewTrend)
      m_Trends[_SignalPointer] = Signal(StringFormat("%s_%d", GetManagerId(), _SignalPointer), p_Time, p_Value);
   else
      m_Trends[_SignalPointer].SetEnd(p_Time, p_Value);
}

void TrendManager::AnalyzeTrend(const int p_MinCandles, const MovingAverageSettings &p_FastMASettings, const MovingAverageSettings &p_SlowMASettings) {
   m_CurrMAFast = iMAMQL4(_Symbol, p_FastMASettings.m_TimeFrame, p_FastMASettings.m_Period, 0, p_FastMASettings.m_Method, p_FastMASettings.m_AppliedTo, 0);
   m_CurrMASlow = iMAMQL4(_Symbol, p_SlowMASettings.m_TimeFrame, p_SlowMASettings.m_Period, 0, p_SlowMASettings.m_Method, p_SlowMASettings.m_AppliedTo, 0);
   
   Trend::State _PrevState = m_CurrState;
	
   if((m_CurrState = GetState(p_MinCandles, p_FastMASettings, p_SlowMASettings)) != Trend::State::INVALID_TREND) {
      if(_PrevState != m_CurrState) { // Is new Trend?
         SelectNextSignal();
      } 
      
      UpdateTrendInfo(_PrevState != m_CurrState, _Time, Bid);
   }
}

//+------------------------------------------------------------------+

class PullBackManager : public SignalManager {
 private:
 	double m_CurrMAFast, m_CurrMAMedium, m_CurrMASlow;
 	double m_PipValue;
 	
 	PullBack::State m_CurrState;
 	
   PullBack m_PullBacks[];
   
   void UpdatePullBackInfo(const bool p_IsNewPullBack, const datetime p_Time, const double p_Value);
   
   PullBack::State GetState(Trend::State p_TrendState, const MovingAverageSettings &p_MASettings);
 public:
   PullBackManager(const string p_ManagerID = "TrendManager", const int p_MaxPullBacks = 10);
	
	void AnalyzePullBack(const Trend::State p_CurrTrendState, const MovingAverageSettings &p_FastMASettings, const MovingAverageSettings &p_MediumMASettings, const MovingAverageSettings &p_SlowMASettings);
	
	PullBack::State GetCurrState() const { return(m_CurrState); }
	
	double GetCurrMAFast() const { return(m_CurrMAFast); }
	double GetCurrMAMedium() const { return(m_CurrMAMedium); }
	double GetCurrMASlow() const { return(m_CurrMASlow); }
	
   PullBack* GetSelectedPullBack() { return(&m_PullBacks[GetSignalPointer()]); }
};

PullBackManager::PullBackManager(const string p_ManagerID, const int p_MaxPullBacks)
   : SignalManager(p_ManagerID, p_MaxPullBacks) {
   m_PipValue = GetForexPipValue();
	
   if(ArrayResize(m_PullBacks, p_MaxPullBacks) != -1)
      PrintFormat("PullBack array initialized succesfully with size %d", GetMaxSignals());
   else
      Print("PullBack array initialization failed with error %", GetLastError());
   
   SelectNextSignal();
};

void PullBackManager::UpdatePullBackInfo(const bool p_IsNewPullBack, const datetime p_Time, const double p_Value) {
	const int _SignalPointer = GetSignalPointer();

   if(p_IsNewPullBack)
      m_PullBacks[_SignalPointer] = Signal(StringFormat("%s_%d", GetManagerId(), _SignalPointer), p_Time, p_Value);
   else
      m_PullBacks[_SignalPointer].SetEnd(p_Time, p_Value);
}

void PullBackManager::AnalyzePullBack(const Trend::State p_CurrTrendState, const MovingAverageSettings &p_FastMASettings, const MovingAverageSettings &p_MediumMASettings, const MovingAverageSettings &p_SlowMASettings) {
	m_CurrMAFast = iMAMQL4(_Symbol, p_FastMASettings.m_TimeFrame, p_FastMASettings.m_Period, 0, p_FastMASettings.m_Method, p_FastMASettings.m_AppliedTo, 1);
	m_CurrMAMedium = iMAMQL4(_Symbol, p_MediumMASettings.m_TimeFrame, p_MediumMASettings.m_Period, 0, p_MediumMASettings.m_Method, p_MediumMASettings.m_AppliedTo, 1);
	m_CurrMASlow = iMAMQL4(_Symbol, p_SlowMASettings.m_TimeFrame, p_SlowMASettings.m_Period, 0, p_SlowMASettings.m_Method, p_SlowMASettings.m_AppliedTo, 1);
	
	PullBack::State _PrevState = m_CurrState;
	
	if((m_CurrState = GetState(p_CurrTrendState, p_FastMASettings)) != PullBack::State::INVALID_PULLBACK) {
		if((p_CurrTrendState == Trend::State::VALID_UPTREND && m_CurrState == PullBack::State::VALID_UPPULLBACK) ||
		(p_CurrTrendState == Trend::State::VALID_DOWNTREND && m_CurrState == PullBack::State::VALID_DOWNPULLBACK)) {
			if(_PrevState != m_CurrState) { // Is new PullBack?
			   SelectNextSignal();
			}	

			UpdatePullBackInfo(_PrevState != m_CurrState, _Time, Bid);
		}
	}
}

PullBack::State PullBackManager::GetState(Trend::State p_TrendState, const MovingAverageSettings &p_MASettings) {
	const double _PrevEMA = iMAMQL4(_Symbol, p_MASettings.m_TimeFrame, p_MASettings.m_Period, 0, p_MASettings.m_Method, p_MASettings.m_AppliedTo, 2);
	
	const double _PrevLength = MathAbs((Open[2] / m_PipValue) - (Close[2] / m_PipValue));
	const double _CurrLength = MathAbs((Open[1] / m_PipValue) - (Close[1] / m_PipValue));
		      	   
	switch(p_TrendState) {
		case Trend::State::VALID_UPTREND: {
			if(m_CurrMASlow < m_CurrMAMedium && m_CurrMAMedium < m_CurrMAFast) {
				const double _PrevLow = iLow(_Symbol, p_MASettings.m_TimeFrame, 2);
				
				// Is the previous candle out/above off the iMA?
				if(_PrevLow > _PrevEMA) {
					const double _CurrLow = iLow(_Symbol, p_MASettings.m_TimeFrame, 1);
					
					// Is the candle wick above iMA and the candle below slow iMA?
					if(_CurrLow < m_CurrMAFast && Close[2] > m_CurrMASlow) {
						// Is the previous candle longer then current or current is lower then previous candle?
						if(_PrevLength > _CurrLength || Close[2] > Close[1]) {
						   const int _NumPips = GetNumPipsBetweenPrices(_PrevLow, _PrevEMA, m_PipValue);
						
						   // Is one and more pips?
		      		   if(_NumPips >= 1) {
		      		      return(PullBack::State::VALID_UPPULLBACK);
		      		   } else {
		      		      PrintFormat("Not enought pips for pullback! Result: %d -> Low:%lf EMA:%lf", _NumPips, _PrevLow, _PrevEMA);
		      		   }
		      	   } else {
		      	      Print("Trigger candle was not shorter or lower then the previous candle -> invalid pullback!");
		      	   }
					} else {
					   PrintFormat("Candle wick not above iMA -> invalid pullback! Wick: %lf, iMA: %lf", _PrevLow, _PrevEMA);
					}
				}
		   }
   
			break;
		}
		case Trend::State::VALID_DOWNTREND: {
			if(m_CurrMASlow > m_CurrMAMedium && m_CurrMAMedium > m_CurrMAFast) {
				const double _PrevHigh = iHigh(_Symbol, p_MASettings.m_TimeFrame, 2);
				
				// Is the previous candle out off/below the iMA?
				if(_PrevHigh < _PrevEMA) {
					const double _CurrHigh = iHigh(_Symbol, p_MASettings.m_TimeFrame, 1);

					// Is the candle wick below fast iMA and the candle above slow iMA?
		      	if(_CurrHigh > m_CurrMAFast && Close[2] < m_CurrMASlow) {
		      		// Is the previous candle longer then current or current is higher then previous candle?
		      		if(_PrevLength > _CurrLength || Close[2] < Close[1]) {
		      		   const int _NumPips = GetNumPipsBetweenPrices(_PrevHigh, _PrevEMA, m_PipValue);
		      		   
		      		   // Is one and more pips?
		      		   if(_NumPips >= 1) {
		      		      return(PullBack::State::VALID_DOWNPULLBACK);
		      		   } else {
		      		      PrintFormat("Not enought pips for pullback! Result: %d -> High:%lf EMA:%lf", _NumPips, _PrevHigh, _PrevEMA);
		      		   }
		      	   } else {
		      	      Print("Trigger candle was not shorter or higher then the previous candle -> invalid pullback!");
		      	   }
		      	} else {
					   PrintFormat("Candle wick not below iMA -> invalid pullback! Wick: %lf, iMA: %lf", _PrevHigh, _PrevEMA);
					}
				}
		   }
   
			break;
		}
	}

   return(PullBack::State::INVALID_PULLBACK);
}