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
   MovingAverageSettings *m_FastMASettings, *m_SlowMASettings;
   
 	double m_CurrMAFast, m_CurrMASlow;
 
 	Trend::State m_CurrState;
 	
   Trend m_Trends[];
   
   void UpdateTrendInfo(const bool p_IsNewTrend, const datetime p_Time, const double p_Value);
    
   Trend::State GetState(const int p_MinCandles);
 public:
   TrendManager(MovingAverageSettings *p_FastMASettings, MovingAverageSettings *p_SlowMASettings, const string p_ManagerID = "TrendManager", const int p_MaxTrends = 10);
	
	void UpdateTrendValues();
	
	Trend::State AnalyzeTrend(const int p_MinCandles);
	Trend::State GetCurrState() const { return(m_CurrState); }
	
   Trend* GetSelectedTrend() { return(&m_Trends[GetSignalPointer()]); }
};

TrendManager::TrendManager(MovingAverageSettings *p_FastMASettings, MovingAverageSettings *p_SlowMASettings, const string p_ManagerID, const int p_MaxTrends)
   : SignalManager(p_ManagerID, p_MaxTrends), m_CurrState(Trend::State::INVALID_TREND), m_FastMASettings(p_FastMASettings), m_SlowMASettings(p_SlowMASettings) {
   if(ArrayResize(m_Trends, p_MaxTrends) != -1) {
      PrintFormat("Trend array initialized succesfully with size %d", GetMaxSignals());
   } else {
      Print("Trend array initialization failed with error %", GetLastError());
   }
};

Trend::State TrendManager::GetState(const int p_MinCandles) {
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
	      
	      for(int i = 0; i < p_MinCandles && _IsUpTrend && _IsDownTrend; ++i) {
	         _MA_CurrFast = iMAMQL4(_Symbol, m_FastMASettings.m_TimeFrame, m_FastMASettings.m_Period, 0, m_FastMASettings.m_Method, m_FastMASettings.m_AppliedTo, i);
	         _MA_CurrSlow = iMAMQL4(_Symbol, m_SlowMASettings.m_TimeFrame, m_SlowMASettings.m_Period, 0, m_SlowMASettings.m_Method, m_SlowMASettings.m_AppliedTo, i);

	         if(!(Close[i + 1] > _MA_CurrFast && _MA_CurrFast > _MA_CurrSlow)) { _IsUpTrend = false; }
	         if(!(Close[i + 1] < _MA_CurrFast && _MA_CurrFast < _MA_CurrSlow)) { _IsDownTrend = false; }   
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

   if(p_IsNewTrend) {
      m_Trends[_SignalPointer] = Signal(StringFormat("%s_%d", GetManagerId(), _SignalPointer), p_Time, p_Value);
   } else {
      m_Trends[_SignalPointer].SetEnd(p_Time, p_Value);
   } 
}

void TrendManager::UpdateTrendValues() {
   m_CurrMAFast = iMAMQL4(_Symbol, m_FastMASettings.m_TimeFrame, m_FastMASettings.m_Period, 0, m_FastMASettings.m_Method, m_FastMASettings.m_AppliedTo, 0);
   m_CurrMASlow = iMAMQL4(_Symbol, m_SlowMASettings.m_TimeFrame, m_SlowMASettings.m_Period, 0, m_SlowMASettings.m_Method, m_SlowMASettings.m_AppliedTo, 0);
}

Trend::State TrendManager::AnalyzeTrend(const int p_MinCandles) {
   const Trend::State _PrevState = m_CurrState;
	
   if((m_CurrState = GetState(p_MinCandles)) != Trend::State::INVALID_TREND) {
      if(_PrevState != m_CurrState) { // Is new Trend?
         SelectNextSignal();
      } 
      
      UpdateTrendInfo(_PrevState != m_CurrState, _Time, Bid);
   }
   
   return(m_CurrState);
}

//+------------------------------------------------------------------+

class PullBackManager : public SignalManager {
 private:
 	double m_CurrMAFast, m_CurrMAMedium, m_CurrMASlow;
 	double m_PipValue, m_TriggerPipsTolerance, m_PrevMinPipsIMA;
 	
 	MovingAverageSettings *m_FastMASettings, *m_MediumMASettings, *m_SlowMASettings;
 	
 	PullBack::State m_CurrState;
 	
   PullBack m_PullBacks[];
   
   void UpdatePullBackInfo(const bool p_IsNewPullBack, const datetime p_Time, const double p_Value);
   
   PullBack::State GetState(Trend::State p_TrendState);
 public:
   PullBackManager(MovingAverageSettings *p_FastMASettings, MovingAverageSettings *p_MediumMASettings, MovingAverageSettings *p_SlowMASettings, const double p_TriggerPipsTolerance, const double p_PrevMinPipsIMA, const string p_ManagerID = "TrendManager", const int p_MaxPullBacks = 10);
	
	void UpdatePullBackValues();
	
	PullBack::State AnalyzePullBack(const Trend::State p_CurrTrendState);
	PullBack::State GetCurrState() const { return(m_CurrState); }
	
	double GetCurrMAFast() const { return(m_CurrMAFast); }
	double GetCurrMAMedium() const { return(m_CurrMAMedium); }
	double GetCurrMASlow() const { return(m_CurrMASlow); }
	
   PullBack* GetSelectedPullBack() { return(&m_PullBacks[GetSignalPointer()]); }
};

PullBackManager::PullBackManager(MovingAverageSettings *p_FastMASettings, MovingAverageSettings *p_MediumMASettings, MovingAverageSettings *p_SlowMASettings, const double p_TriggerPipsTolerance, const double p_PrevMinPipsIMA, const string p_ManagerID, const int p_MaxPullBacks)
   : SignalManager(p_ManagerID, p_MaxPullBacks), m_FastMASettings(p_FastMASettings), m_MediumMASettings(p_MediumMASettings), m_SlowMASettings(p_SlowMASettings), m_TriggerPipsTolerance(p_TriggerPipsTolerance), m_PrevMinPipsIMA(p_PrevMinPipsIMA) {
   m_PipValue = GetForexPipValue();
	
   if(ArrayResize(m_PullBacks, p_MaxPullBacks) != -1) {
      PrintFormat("PullBack array initialized succesfully with size %d", GetMaxSignals());
   } else {
      Print("PullBack array initialization failed with error %", GetLastError());
   }
   
   SelectNextSignal();
};

void PullBackManager::UpdatePullBackInfo(const bool p_IsNewPullBack, const datetime p_Time, const double p_Value) {
	const int _SignalPointer = GetSignalPointer();

   if(p_IsNewPullBack) {
      m_PullBacks[_SignalPointer] = Signal(StringFormat("%s_%d", GetManagerId(), _SignalPointer), p_Time, p_Value);
   } else {
      m_PullBacks[_SignalPointer].SetEnd(p_Time, p_Value);
   }
}

void PullBackManager::UpdatePullBackValues() {
   m_CurrMAFast = iMAMQL4(_Symbol, m_FastMASettings.m_TimeFrame, m_FastMASettings.m_Period, 0, m_FastMASettings.m_Method, m_FastMASettings.m_AppliedTo, 0);
	m_CurrMAMedium = iMAMQL4(_Symbol, m_MediumMASettings.m_TimeFrame, m_MediumMASettings.m_Period, 0, m_MediumMASettings.m_Method, m_MediumMASettings.m_AppliedTo, 0);
	m_CurrMASlow = iMAMQL4(_Symbol, m_SlowMASettings.m_TimeFrame, m_SlowMASettings.m_Period, 0, m_SlowMASettings.m_Method, m_SlowMASettings.m_AppliedTo, 0);
}

PullBack::State PullBackManager::AnalyzePullBack(const Trend::State p_CurrTrendState) {
	const PullBack::State _PrevState = m_CurrState;
	
	if((m_CurrState = GetState(p_CurrTrendState)) != PullBack::State::INVALID_PULLBACK) {
		if((p_CurrTrendState == Trend::State::VALID_UPTREND && m_CurrState == PullBack::State::VALID_UPPULLBACK) ||
		(p_CurrTrendState == Trend::State::VALID_DOWNTREND && m_CurrState == PullBack::State::VALID_DOWNPULLBACK)) {
			if(_PrevState != m_CurrState) { // Is new PullBack?
			   SelectNextSignal();
			}	

			UpdatePullBackInfo(_PrevState != m_CurrState, _Time, Bid);
		}
	}
	
	return(m_CurrState);
}

PullBack::State PullBackManager::GetState(Trend::State p_TrendState) {
	const double _PrevFastIMA = iMAMQL4(_Symbol, m_FastMASettings.m_TimeFrame, m_FastMASettings.m_Period, 0, m_FastMASettings.m_Method, m_FastMASettings.m_AppliedTo, 1);
	
	const double _PrevLength = MathAbs((Open[2] / m_PipValue) - (Close[2] / m_PipValue));
	const double _TriggerLength = MathAbs((Open[1] / m_PipValue) - (Close[1] / m_PipValue));
		      	   
	switch(p_TrendState) {
		case Trend::State::VALID_UPTREND: {
			if(m_CurrMASlow < m_CurrMAMedium && m_CurrMAMedium < m_CurrMAFast) {
			   const double _TriggerLow = iLow(_Symbol, m_FastMASettings.m_TimeFrame, 1);
			   
			   // Is the trigger wick above the fast iMA and the whole candle below the slow iMA?
				if((_TriggerLow < m_CurrMAFast || GetNumPipsBetweenPrices(_TriggerLow, m_CurrMAFast, m_PipValue) <= m_TriggerPipsTolerance) && Close[1] > m_CurrMASlow) {
				   const double _PrevLow = iLow(_Symbol, m_FastMASettings.m_TimeFrame, 2);
				   
				   // Is the previous candle above the fast iMA?
				   if(_PrevLow > _PrevFastIMA) {
				      const double _NumPips = GetNumPipsBetweenPrices(_PrevLow, _PrevFastIMA, m_PipValue);
				      
				      // Is valid wick - iMA distance?
		      		if(_NumPips >= m_PrevMinPipsIMA) {
		      		
		      		   // Is there a good shape of previous and trigger candle?
		      		   if((Close[2] > Close[1] || _PrevLength > _TriggerLength) && !(IsBullCandle(2) && IsBullCandle(1))) {
		      		      PrintFormat("Valid pullback! Previous candle close: %lf; Trigger candle close: %lf; Previous candle length: %lf; Trigger candle close: %lf", Close[2], Close[1], _PrevLength, _TriggerLength);
		      		   
		      		      return(PullBack::State::VALID_UPPULLBACK);
		      		   } else {
		      		      Print("Invalid pullback! Wrong previous/trigger candle shape.");
		      		   }
		      		} else {
		      		   PrintFormat("Invalid previous candle! Candle wick is too close to iMA! Wick: %lf; Fast iMA: %lf; Num pips: %lf < Min num pips: %lf", _PrevLow, _PrevFastIMA, _NumPips, m_PrevMinPipsIMA);
		      		}
				   } else {
				      PrintFormat("Invalid previous candle! Candle is not above the fast iMA! Wick: %lf; Candle: %lf; Fast iMA: %lf", _PrevLow, Close[2], m_CurrMAFast);
				   }
				} else {
				   PrintFormat("Invalid trigger candle! Wick: %lf; Candle: %lf; Fast iMA: %lf; Slow iMA: %lf", _TriggerLow, Close[1], m_CurrMAFast, m_CurrMASlow);
				}
		   }
   
			break;
		}
		case Trend::State::VALID_DOWNTREND: {
		   if(m_CurrMASlow > m_CurrMAMedium && m_CurrMAMedium > m_CurrMAFast) {
			   const double _TriggerHigh = iHigh(_Symbol, m_FastMASettings.m_TimeFrame, 1);
			   
			   // Is the trigger wick below the fast iMA and the whole candle above the slow iMA?
				if((_TriggerHigh > m_CurrMAFast || GetNumPipsBetweenPrices(_TriggerHigh, m_CurrMAFast, m_PipValue) <= m_TriggerPipsTolerance) && Close[1] < m_CurrMASlow) {
				   const double _PrevHigh = iHigh(_Symbol, m_FastMASettings.m_TimeFrame, 2);
				   
				   // Is the previous candle below the fast iMA?
				   if(_PrevHigh < _PrevFastIMA) {
				      const double _NumPips = GetNumPipsBetweenPrices(_PrevHigh, _PrevFastIMA, m_PipValue);
				      
				      // Is valid wick - iMA distance?
		      		if(_NumPips >= m_PrevMinPipsIMA) {
		      		
		      		   // Is there a good shape of previous and trigger candle?
		      		   if((Close[2] < Close[1] || _PrevLength > _TriggerLength) && !(IsBearCandle(2) && IsBearCandle(1))) {
		      		      PrintFormat("Valid pullback! Previous candle close: %lf; Trigger candle close: %lf; Previous candle length: %lf; Trigger candle close: %lf", Close[2], Close[1], _PrevLength, _TriggerLength);
		      		   
		      		      return(PullBack::State::VALID_DOWNPULLBACK);
		      		   } else {
		      		      Print("Invalid pullback! Wrong previous/trigger candle shape.");
		      		   }
		      		} else {
		      		   PrintFormat("Invalid previous candle! Candle wick is too close to iMA! Wick: %lf; Fast iMA: %lf; Num pips: %lf < Min num pips: %lf", _PrevHigh, _PrevFastIMA, _NumPips, m_PrevMinPipsIMA);
		      		}
				   } else {
				      PrintFormat("Invalid previous candle! Candle is not below the fast iMA! Wick: %lf; Candle: %lf; Fast iMA: %lf", _PrevHigh, Close[2], m_CurrMAFast);
				   }
				} else {
				   PrintFormat("Invalid trigger candle! Wick: %lf; Candle: %lf; Fast iMA: %lf; Slow iMA: %lf", _TriggerHigh, Close[1], m_CurrMAFast, m_CurrMASlow);
				}
		   }
   
			break;
		}
	}

   return(PullBack::State::INVALID_PULLBACK);
}